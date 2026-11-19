#include "componentmanager.h"

#include "componentinstaller.h"
#include "componentinstallationstore.h"
#include "componentlifecycle.h"
#include "componentregistry.h"
#include "projectscaffolder.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSaveFile>

ComponentManager::ComponentManager(QObject *parent) : QObject(parent) {}

QVariantMap ComponentManager::activeDefinition(const QString &id) const
{
    auto definition = ComponentRegistry::instance().component(id);
    if (m_projectController && m_projectController->projectFramework() == "react-vite"
        && definition.contains("viteFiles")) {
        auto files = definition.value("files").toList();
        files.append(definition.value("viteFiles").toList());
        definition.insert("files", files);
    }
    return definition;
}

namespace {
struct NpmUpdate {
    QString path;
    QByteArray original;
    QByteArray updated;
    QStringList additions;
    QString error;
};

NpmUpdate planNpmUpdate(const QString &projectPath, const QVariantMap &dependencies)
{
    NpmUpdate result;
    if (dependencies.isEmpty())
        return result;
    result.path = QDir(projectPath).filePath("package.json");
    QFile file(result.path);
    if (QFileInfo(file).isSymLink() || !file.open(QIODevice::ReadOnly)) {
        result.error = "Cannot update project package.json.";
        return result;
    }
    result.original = file.readAll();
    const auto document = QJsonDocument::fromJson(result.original);
    if (!document.isObject()) {
        result.error = "Project package.json is not a JSON object.";
        return result;
    }
    auto manifest = document.object();
    auto existing = manifest.value("dependencies").toObject();
    if (manifest.contains("dependencies") && !manifest.value("dependencies").isObject()) {
        result.error = "package.json dependencies must be a JSON object.";
        return result;
    }
    const auto development = manifest.value("devDependencies").toObject();
    for (auto item = dependencies.cbegin(); item != dependencies.cend(); ++item) {
        if (existing.contains(item.key()) || development.contains(item.key()))
            continue;
        existing.insert(item.key(), item.value().toString());
        result.additions.append(item.key());
    }
    if (!result.additions.isEmpty()) {
        manifest.insert("dependencies", existing);
        result.updated = QJsonDocument(manifest).toJson();
    }
    return result;
}

bool writeNpmManifest(const QString &path, const QByteArray &expected, const QByteArray &updated)
{
    QFile input(path);
    if (QFileInfo(input).isSymLink() || !input.open(QIODevice::ReadOnly)
        || input.readAll() != expected)
        return false;
    input.close();
    QSaveFile file(path);
    return file.open(QIODevice::WriteOnly) && file.write(updated) == updated.size() && file.commit();
}
}

ProjectController *ComponentManager::projectController() const
{
    return m_projectController;
}

void ComponentManager::setProjectController(ProjectController *controller)
{
    if (m_projectController == controller)
        return;
    if (m_projectController)
        disconnect(m_projectController, nullptr, this, nullptr);
    m_projectController = controller;
    m_drafts.clear();
    if (m_projectController) {
        connect(m_projectController, &ProjectController::activeProjectChanged, this,
                [this]() { m_drafts.clear(); });
    }
    emit projectControllerChanged();
}

void ComponentManager::requestInstall(const QString &id)
{
    if (m_projectController && ProjectScaffolder::compatible(
            m_projectController->activeProjectPath(),
            activeDefinition(id)))
        emit installRequested(id);
}

void ComponentManager::requestMove(const QString &id)
{
    if (isInstalled(id))
        emit moveRequested(id);
}

void ComponentManager::requestRemove(const QString &id)
{
    if (isInstalled(id))
        emit removeRequested(id);
}

QVariantMap ComponentManager::previewInstall(const QString &id,
                                             const QString &relativeDirectory) const
{
    const QVariantMap definition = activeDefinition(id);
    if (definition.isEmpty())
        return {{"error", QStringLiteral("Unknown component package.")}};
    if (!m_projectController || m_projectController->activeProjectPath().isEmpty())
        return {{"error", QStringLiteral("Open a project first.")}};
    if (!ProjectScaffolder::compatible(m_projectController->activeProjectPath(), definition))
        return {{"error", QStringLiteral("This package does not support the active project's framework.")}};
    const QString projectPath = QDir(m_projectController->activeProjectPath()).canonicalPath();
    if (projectPath.isEmpty())
        return {{"error", QStringLiteral("Project folder is unavailable.")}};
    QJsonObject registry;
    const QString registryError = ComponentInstallationStore::load(projectPath, &registry);
    if (!registryError.isEmpty())
        return {{"error", registryError}};

    for (const auto &conflict : definition.value("conflicts").toStringList()) {
        if (!installedDirectory(conflict).isEmpty())
            return {{"error", QStringLiteral("Remove the conflicting package '%1' first.").arg(conflict)}};
    }
    const QString requiredDirectory = definition.value("requiredDirectory").toString();
    if (!requiredDirectory.isEmpty() && relativeDirectory != requiredDirectory)
        return {{"error", QStringLiteral("This package must be installed in '%1'.").arg(requiredDirectory)}};

    if (isInstalled(id))
        return {{"error", QStringLiteral("Already installed at '%1'. Use Move Component to change location.")
                                .arg(installedDirectory(id))},
                {"status", QStringLiteral("installed")}};

    const QVariantMap recorded = ComponentInstallationStore::find(projectPath, id);
    if (!recorded.isEmpty()) {
        const QString directory = recorded.value("directory").toString();
        bool anyFilesRemain = false;
        if (!ComponentInstaller::validDirectory(directory))
            return {{"error", QStringLiteral("Installation registry contains an invalid folder.")}};
        for (const QVariant &item : definition.value("files").toList()) {
            const QString target = item.toMap().value("target").toString();
            const QFileInfo file(QDir(projectPath).filePath(
                ComponentInstaller::combinedPath(directory, target)));
            if (file.exists() || file.isSymLink())
                anyFilesRemain = true;
        }
        return {{"error", anyFilesRemain
                    ? QStringLiteral("Incomplete installation at '%1'. Inspect the remaining files before repairing.")
                          .arg(directory)
                    : QStringLiteral("Registry still points to '%1', but its files are missing. Repair the record first.")
                          .arg(directory)},
                {"status", QStringLiteral("broken")},
                {"repairable", !anyFilesRemain}, {"recordedDirectory", directory}};
    }
    auto preview = ComponentInstaller::previewInstall(projectPath, id, definition, relativeDirectory);
    if (m_projectController->projectFramework() == "react-vite"
        && preview.value("error").toString().isEmpty()) {
        const auto npm = planNpmUpdate(projectPath, definition.value("viteDependencies").toMap());
        preview.insert("error", npm.error);
        preview.insert("npmAdditions", npm.additions);
        if (!npm.additions.isEmpty() && m_projectController->devServerActive())
            preview.insert("error", "Stop the server before adding npm dependencies.");
    }
    return preview;
}

QString ComponentManager::repairMissingInstallation(const QString &id)
{
    if (!m_projectController || m_projectController->activeProjectPath().isEmpty())
        return QStringLiteral("Open a project first.");
    if (isInstalled(id))
        return QStringLiteral("Installed components must be moved or removed, not repaired.");
    const QString projectPath = QDir(m_projectController->activeProjectPath()).canonicalPath();
    if (projectPath.isEmpty())
        return QStringLiteral("Project folder is unavailable.");
    const QVariantMap recorded = ComponentInstallationStore::find(projectPath, id);
    if (recorded.isEmpty())
        return QStringLiteral("No installation record to repair.");
    const QString directory = recorded.value("directory").toString();
    if (!ComponentInstaller::validDirectory(directory))
        return QStringLiteral("Invalid recorded directory. Repair it manually.");
    const QVariantMap definition = activeDefinition(id);
    for (const QVariant &item : definition.value("files").toList()) {
        const QString path = ComponentInstaller::combinedPath(directory,
                                   item.toMap().value("target").toString());
        const QFileInfo file(QDir(projectPath).filePath(path));
        if (file.exists() || file.isSymLink())
            return QStringLiteral("Cannot repair while registered files still exist: ") + path;
    }
    const QString error = ComponentInstallationStore::unregister(projectPath, id);
    if (error.isEmpty())
        emit logMessage(QStringLiteral("Removed stale component record: ") + id);
    return error;
}

QVariantMap ComponentManager::previewMove(const QString &id,
                                          const QString &relativeDirectory) const
{
    if (!m_projectController || !isInstalled(id))
        return {{"error", QStringLiteral("This component is not installed.")}};
    const QVariantMap definition = activeDefinition(id);
    if (!definition.value("requiredDirectory").toString().isEmpty())
        return {{"error", QStringLiteral("This package has a fixed runtime location.")}};
    for (const QVariant &file : definition.value("files").toList()) {
        if (file.toMap().value("target").toString().endsWith(".java"))
            return {{"error", QStringLiteral("Java package relocation is disabled until imports and package declarations can be rewritten safely.")}};
    }
    const QString project = QDir(m_projectController->activeProjectPath()).canonicalPath();
    if (project.isEmpty())
        return {{"error", QStringLiteral("Project folder is unavailable.")}};
    return ComponentLifecycle::previewMove(project, id,
        activeDefinition(id), installedDirectory(id), relativeDirectory);
}

QString ComponentManager::moveComponentInDirectory(const QString &id,
                                                   const QString &relativeDirectory)
{
    if (!m_projectController || !isInstalled(id))
        return QStringLiteral("This component is not installed.");
    const QVariantMap definition = activeDefinition(id);
    if (!definition.value("requiredDirectory").toString().isEmpty())
        return QStringLiteral("This package has a fixed runtime location.");
    for (const QVariant &file : definition.value("files").toList()) {
        if (file.toMap().value("target").toString().endsWith(".java"))
            return QStringLiteral("Java package relocation is not supported safely yet.");
    }
    if (m_projectController->busy() && !m_projectController->devServerActive())
        return QStringLiteral("Wait for the current command to finish.");
    const QString project = QDir(m_projectController->activeProjectPath()).canonicalPath();
    if (project.isEmpty())
        return QStringLiteral("Project folder is unavailable.");
    QJsonObject registry;
    const QString registryError = ComponentInstallationStore::load(project, &registry);
    if (!registryError.isEmpty())
        return registryError;
    const QString previous = installedDirectory(id);
    QString cleanupNote;
    const QString error = ComponentLifecycle::move(project, id,
        activeDefinition(id), previous, relativeDirectory, &cleanupNote);
    if (!error.isEmpty())
        return error;
    emit logMessage(QStringLiteral("Component moved: %1 → %2").arg(id, relativeDirectory));
    if (!cleanupNote.isEmpty())
        emit logMessage(cleanupNote);
    emit componentMoved(id);
    return {};
}

QVariantMap ComponentManager::previewRemove(const QString &id) const
{
    if (!m_projectController || !isInstalled(id))
        return {{"error", QStringLiteral("This component is not installed.")}};
    const QString project = QDir(m_projectController->activeProjectPath()).canonicalPath();
    if (project.isEmpty())
        return {{"error", QStringLiteral("Project folder is unavailable.")}};
    return ComponentLifecycle::previewRemove(project, id,
        activeDefinition(id), installedDirectory(id));
}

QString ComponentManager::removeComponent(const QString &id)
{
    if (!m_projectController || !isInstalled(id))
        return QStringLiteral("This component is not installed.");
    if (m_projectController->busy() && !m_projectController->devServerActive())
        return QStringLiteral("Wait for the current command to finish.");
    const QString project = QDir(m_projectController->activeProjectPath()).canonicalPath();
    if (project.isEmpty())
        return QStringLiteral("Project folder is unavailable.");
    QJsonObject registry;
    const QString registryError = ComponentInstallationStore::load(project, &registry);
    if (!registryError.isEmpty())
        return registryError;
    QString backup;
    QString cleanupNote;
    const QString error = ComponentLifecycle::remove(project, id,
        activeDefinition(id), installedDirectory(id), &backup,
        &cleanupNote);
    if (!error.isEmpty())
        return error;
    emit logMessage(QStringLiteral("Component removed to recovery folder: %1 → %2")
                        .arg(id, backup));
    if (!cleanupNote.isEmpty())
        emit logMessage(cleanupNote);
    emit componentRemoved(id);
    return {};
}

QString ComponentManager::relativeFolder(const QUrl &folderUrl) const
{
    if (!m_projectController || !folderUrl.isLocalFile())
        return {};
    const QString projectRoot = QDir(m_projectController->activeProjectPath()).canonicalPath();
    const QFileInfo folder(folderUrl.toLocalFile());
    const QString destination = folder.canonicalFilePath();
    if (projectRoot.isEmpty() || destination.isEmpty() || !folder.isDir())
        return {};
    const QString relative = QDir(projectRoot).relativeFilePath(destination);
    if (!ComponentInstaller::validDirectory(relative))
        return {};
    return relative;
}

QString ComponentManager::installComponent(const QString &id, const QUrl &destinationFolder)
{
    const QString relative = relativeFolder(destinationFolder);
    if (relative.isEmpty())
        return QStringLiteral("Choose an existing folder inside the active project.");
    return installComponentInDirectory(id, relative);
}

QString ComponentManager::installedDirectory(const QString &id) const
{
    if (!m_projectController || m_projectController->activeProjectPath().isEmpty())
        return {};
    const QString projectPath = m_projectController->activeProjectPath();
    const QVariantMap entry = ComponentInstallationStore::find(projectPath, id);
    if (!entry.isEmpty())
        return entry.value("directory").toString();

    // Preserve access to components installed before this registry existed.
    const QVariantMap definition = activeDefinition(id);
    const QString legacy = definition.value("legacyDirectory").toString();
    if (ComponentInstaller::validDirectory(legacy)
        && ComponentInstaller::isInstalled(projectPath, definition, legacy))
        return legacy;
    return {};
}

bool ComponentManager::isInstalled(const QString &id) const
{
    if (!m_projectController)
        return false;
    const QVariantMap definition = activeDefinition(id);
    const QString directory = installedDirectory(id);
    return !definition.isEmpty() && !directory.isEmpty()
        && ComponentInstaller::isInstalled(m_projectController->activeProjectPath(),
                                            definition, directory);
}

QUrl ComponentManager::configurationUrl(const QString &id) const
{
    if (!m_projectController || !isInstalled(id))
        return {};
    const QString target = activeDefinition(id)
                               .value("configTarget").toString();
    if (!ComponentInstaller::validTarget(target))
        return {};
    const QString relative = ComponentInstaller::combinedPath(installedDirectory(id), target);
    return QUrl::fromLocalFile(QDir(m_projectController->activeProjectPath()).filePath(relative));
}

QString ComponentManager::draftConfiguration(const QString &id) const
{
    const auto found = m_drafts.constFind(id);
    if (found != m_drafts.cend())
        return found.value();

    const QVariantMap definition = activeDefinition(id);
    const QString configTarget = definition.value("configTarget").toString();
    if (!ComponentInstaller::validTarget(configTarget))
        return {};
    for (const QVariant &item : definition.value("files").toList()) {
        const QVariantMap mapping = item.toMap();
        if (mapping.value("target").toString() != configTarget)
            continue;
        QFile source(QStringLiteral(":/component-packages/%1/%2")
                         .arg(id, mapping.value("source").toString()));
        if (!source.open(QIODevice::ReadOnly))
            return {};
        return QString::fromUtf8(source.readAll());
    }
    return {};
}

QString ComponentManager::setDraftConfiguration(const QString &id, const QString &jsonText)
{
    const QVariantMap definition = activeDefinition(id);
    if (definition.isEmpty() || !ComponentInstaller::validTarget(
            definition.value("configTarget").toString()))
        return QStringLiteral("This component does not support configuration previews.");
    const QByteArray bytes = jsonText.toUtf8();
    if (bytes.size() > 64 * 1024 || bytes.contains('\0'))
        return QStringLiteral("Configuration must be text of at most 64 KiB.");
    if (definition.value("configFormat").toString() != "properties"
        && !QJsonDocument::fromJson(bytes).isObject())
        return QStringLiteral("Configuration must be a JSON object.");
    m_drafts.insert(id, jsonText);
    return {};
}

QString ComponentManager::installComponentInDirectory(const QString &id,
                                                       const QString &relativeDirectory)
{
    const QVariantMap definition = activeDefinition(id);
    if (definition.isEmpty())
        return QStringLiteral("Unknown component: ") + id;
    if (!m_projectController || m_projectController->activeProjectPath().isEmpty())
        return QStringLiteral("Open a project first.");
    if (!ProjectScaffolder::compatible(m_projectController->activeProjectPath(), definition))
        return QStringLiteral("This package is not compatible with the active project.");
    if (m_projectController->busy() && !m_projectController->devServerActive())
        return QStringLiteral("Wait for the current command to finish.");
    if (!ComponentInstaller::validDirectory(relativeDirectory))
        return QStringLiteral("Choose a folder inside the project; '..' and absolute paths are not allowed.");

    const QString projectPath = QDir(m_projectController->activeProjectPath()).canonicalPath();
    if (projectPath.isEmpty())
        return QStringLiteral("The project folder no longer exists.");

    QJsonObject existingRegistry;
    const QString registryError = ComponentInstallationStore::load(projectPath, &existingRegistry);
    if (!registryError.isEmpty())
        return registryError;
    const QVariantMap preview = previewInstall(id, relativeDirectory);
    const QString preflightError = preview.value("error").toString();
    if (!preflightError.isEmpty())
        return preflightError;

    const auto npm = m_projectController->projectFramework() == "react-vite"
        ? planNpmUpdate(projectPath, definition.value("viteDependencies").toMap()) : NpmUpdate{};
    if (!npm.error.isEmpty())
        return npm.error;
    if (!npm.additions.isEmpty() && m_projectController->devServerActive())
        return "Stop the server before adding npm dependencies.";

    QStringList createdFiles;
    const QString error = ComponentInstaller::install(
        projectPath, id, definition, relativeDirectory, m_drafts.value(id), &createdFiles);
    if (!error.isEmpty()) {
        for (const QString &path : createdFiles)
            QFile::remove(path); // Roll back only the new files from this attempt.
        return error;
    }

    if (!npm.updated.isEmpty() && !writeNpmManifest(npm.path, npm.original, npm.updated)) {
        for (const auto &path : createdFiles)
            QFile::remove(path);
        return "package.json changed or could not be saved. No package was installed.";
    }

    const QString recordError = ComponentInstallationStore::record(
        projectPath, id, relativeDirectory, definition);
    if (!recordError.isEmpty()) {
        for (const QString &path : createdFiles)
            QFile::remove(path);
        if (!npm.updated.isEmpty() && !writeNpmManifest(npm.path, npm.updated, npm.original))
            return recordError + " Check package.json, which could not be restored.";
        return recordError;
    }

    if (!npm.additions.isEmpty())
        emit logMessage("Added packages to package.json. Run Install Dependencies before starting the server.");
    m_drafts.remove(id);
    emit logMessage(QStringLiteral("Component installed: %1 → %2")
                        .arg(definition.value("name").toString(), relativeDirectory));
    emit componentInstalled(id);
    return {};
}
