#include "componentinstallationstore.h"

#include "componentinstaller.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSaveFile>

namespace {
QString registryPath(const QString &projectPath)
{
    return QDir(projectPath).filePath(".jeridiengine/components.json");
}

QJsonObject makeEntry(const QString &componentId, const QString &directory,
                      const QVariantMap &definition)
{
    QJsonArray paths;
    for (const QVariant &item : definition.value("files").toList())
        paths.append(ComponentInstaller::combinedPath(directory,
                          item.toMap().value("target").toString()));
    QJsonObject entry{{"id", componentId}, {"directory", directory}, {"files", paths}};
    const QString config = definition.value("configTarget").toString();
    if (!config.isEmpty())
        entry.insert("config", ComponentInstaller::combinedPath(directory, config));
    return entry;
}

QString save(const QString &projectPath, const QJsonObject &document)
{
    const QDir project(projectPath);
    if (!project.mkpath(".jeridiengine"))
        return QStringLiteral("Could not create .jeridiengine directory.");
    QSaveFile output(registryPath(projectPath));
    const QByteArray bytes = QJsonDocument(document).toJson(QJsonDocument::Indented);
    if (!output.open(QIODevice::WriteOnly)
        || output.write(bytes) != bytes.size() || !output.commit())
        return QStringLiteral("Could not save installation registry: ") + output.errorString();
    return {};
}
}

QString ComponentInstallationStore::load(const QString &projectPath, QJsonObject *document)
{
    if (!document)
        return QStringLiteral("Invalid installation registry output.");

    const QDir project(projectPath);
    const QFileInfo folder(project.filePath(".jeridiengine"));
    const QFileInfo file(registryPath(projectPath));
    if (folder.isSymLink() || (folder.exists() && !folder.isDir()))
        return QStringLiteral("Invalid .jeridiengine directory.");
    if (file.isSymLink() || (file.exists() && !file.isFile()))
        return QStringLiteral("Invalid .jeridiengine/components.json file.");

    if (!file.exists()) {
        *document = QJsonObject{{"version", 1}, {"installations", QJsonArray{}}};
        return {};
    }

    QFile input(file.filePath());
    if (!input.open(QIODevice::ReadOnly))
        return QStringLiteral("Could not read component installation registry.");
    QJsonParseError parseError;
    const QJsonDocument parsed = QJsonDocument::fromJson(input.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !parsed.isObject())
        return QStringLiteral("Invalid .jeridiengine/components.json; fix it before installing.");

    *document = parsed.object();
    if (document->value("version").toInt() != 1
        || !document->value("installations").isArray())
        return QStringLiteral("Unsupported component installation registry format.");
    return {};
}

QVariantMap ComponentInstallationStore::find(const QString &projectPath,
                                              const QString &componentId)
{
    QJsonObject document;
    if (!load(projectPath, &document).isEmpty())
        return {};
    for (const QJsonValue &value : document.value("installations").toArray()) {
        if (value.isObject() && value.toObject().value("id").toString() == componentId)
            return value.toObject().toVariantMap();
    }
    return {};
}

QString ComponentInstallationStore::record(const QString &projectPath,
                                            const QString &componentId,
                                            const QString &relativeDirectory,
                                            const QVariantMap &definition)
{
    QJsonObject document;
    const QString error = load(projectPath, &document);
    if (!error.isEmpty())
        return error;

    QJsonArray installations = document.value("installations").toArray();
    for (const QJsonValue &value : installations) {
        if (value.toObject().value("id").toString() == componentId)
            return QStringLiteral("This component is already registered in the project.");
    }

    installations.append(makeEntry(componentId, relativeDirectory, definition));
    document.insert("installations", installations);
    return save(projectPath, document);
}

QString ComponentInstallationStore::relocate(const QString &projectPath,
                                            const QString &componentId,
                                            const QString &relativeDirectory,
                                            const QVariantMap &definition)
{
    QJsonObject document;
    const QString error = load(projectPath, &document);
    if (!error.isEmpty())
        return error;
    QJsonArray installations = document.value("installations").toArray();
    for (int i = 0; i < installations.size(); ++i) {
        if (installations.at(i).toObject().value("id").toString() == componentId) {
            installations.replace(i, makeEntry(componentId, relativeDirectory, definition));
            document.insert("installations", installations);
            return save(projectPath, document);
        }
    }
    // Adopt installations made before the registry existed.
    installations.append(makeEntry(componentId, relativeDirectory, definition));
    document.insert("installations", installations);
    return save(projectPath, document);
}

QString ComponentInstallationStore::unregister(const QString &projectPath,
                                               const QString &componentId)
{
    QJsonObject document;
    const QString error = load(projectPath, &document);
    if (!error.isEmpty())
        return error;
    QJsonArray filtered;
    bool found = false;
    for (const QJsonValue &value : document.value("installations").toArray()) {
        if (value.toObject().value("id").toString() == componentId) {
            found = true;
            continue;
        }
        filtered.append(value);
    }
    if (!found)
        return {}; // Legacy installation: nothing to unregister.
    document.insert("installations", filtered);
    return save(projectPath, document);
}
