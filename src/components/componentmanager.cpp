#include "componentmanager.h"

#include "componentinstaller.h"
#include "componentinstallationstore.h"
#include "componentlifecycle.h"
#include "componentregistry.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>

ComponentManager::ComponentManager(QObject *parent) : QObject(parent) {}

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
    if (!ComponentRegistry::instance().component(id).isEmpty())
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
    const QVariantMap definition = ComponentRegistry::instance().component(id);
    if (definition.isEmpty())
        return {{"error", QStringLiteral("Unknown component package.")}};
    if (!m_projectController || m_projectController->activeProjectPath().isEmpty())
        return {{"error", QStringLiteral("Open a project first.")}};
    const QString projectPath = QDir(m_projectController->activeProjectPath()).canonicalPath();
    if (projectPath.isEmpty())
        return {{"error", QStringLiteral("Project folder is unavailable.")}};
    QJsonObject registry;
    const QString registryError = ComponentInstallationStore::load(projectPath, &registry);
    if (!registryError.isEmpty())
        return {{"error", registryError}};

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
    return ComponentInstaller::previewInstall(projectPath, id, definition, relativeDirectory);
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
    const QVariantMap definition = ComponentRegistry::instance().component(id);
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
    const QString project = QDir(m_projectController->activeProjectPath()).canonicalPath();
    if (project.isEmpty())
        return {{"error", QStringLiteral("Project folder is unavailable.")}};
    return ComponentLifecycle::previewMove(project, id,
        ComponentRegistry::instance().component(id), installedDirectory(id), relativeDirectory);
}

QString ComponentManager::moveComponentInDirectory(const QString &id,
                                                   const QString &relativeDirectory)
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
    const QString previous = installedDirectory(id);
    QString cleanupNote;
    const QString error = ComponentLifecycle::move(project, id,
        ComponentRegistry::instance().component(id), previous, relativeDirectory, &cleanupNote);
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
        ComponentRegistry::instance().component(id), installedDirectory(id));
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
        ComponentRegistry::instance().component(id), installedDirectory(id), &backup,
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
    const QVariantMap definition = ComponentRegistry::instance().component(id);
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
    const QVariantMap definition = ComponentRegistry::instance().component(id);
    const QString directory = installedDirectory(id);
    return !definition.isEmpty() && !directory.isEmpty()
        && ComponentInstaller::isInstalled(m_projectController->activeProjectPath(),
                                            definition, directory);
}

QUrl ComponentManager::configurationUrl(const QString &id) const
{
    if (!m_projectController || !isInstalled(id))
        return {};
    const QString target = ComponentRegistry::instance().component(id)
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

    const QVariantMap definition = ComponentRegistry::instance().component(id);
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
    const QVariantMap definition = ComponentRegistry::instance().component(id);
    if (definition.isEmpty() || !ComponentInstaller::validTarget(
            definition.value("configTarget").toString()))
        return QStringLiteral("This component does not support configuration previews.");
    QJsonParseError error;
    const QByteArray bytes = jsonText.toUtf8();
    const QJsonDocument doc = QJsonDocument::fromJson(bytes, &error);
    if (error.error != QJsonParseError::NoError || !doc.isObject()
        || bytes.size() > 64 * 1024)
        return QStringLiteral("Configuration must be a JSON object of at most 64 KiB.");
    m_drafts.insert(id, jsonText);
    return {};
}

QString ComponentManager::installComponentInDirectory(const QString &id,
                                                       const QString &relativeDirectory)
{
    const QVariantMap definition = ComponentRegistry::instance().component(id);
    if (definition.isEmpty())
        return QStringLiteral("Unknown component: ") + id;
    if (!m_projectController || m_projectController->activeProjectPath().isEmpty())
        return QStringLiteral("Open a project first.");
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

    QStringList createdFiles;
    const QString error = ComponentInstaller::install(
        projectPath, id, definition, relativeDirectory, m_drafts.value(id), &createdFiles);
    if (!error.isEmpty()) {
        for (const QString &path : createdFiles)
            QFile::remove(path); // Roll back only the new files from this attempt.
        return error;
    }

    const QString recordError = ComponentInstallationStore::record(
        projectPath, id, relativeDirectory, definition);
    if (!recordError.isEmpty()) {
        for (const QString &path : createdFiles)
            QFile::remove(path);
        return recordError;
    }

    m_drafts.remove(id);
    emit logMessage(QStringLiteral("Component installed: %1 → %2")
                        .arg(definition.value("name").toString(), relativeDirectory));
    emit componentInstalled(id);
    return {};
}
