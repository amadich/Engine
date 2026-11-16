#include "componentinstaller.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSaveFile>
#include <QSet>
#include <QVector>

namespace {
struct PlannedFile {
    QString target;
    QByteArray bytes;
};

bool validSource(const QString &relativePath)
{
    if (!relativePath.startsWith("template/") || relativePath.contains('\\'))
        return false;
    for (const QString &segment : relativePath.split('/')) {
        if (segment.isEmpty() || segment == "." || segment == "..")
            return false;
    }
    return true;
}

QString verifyDirectories(const QDir &project, const QString &relativePath)
{
    const QStringList parts = relativePath.split('/');
    QString current;
    for (int i = 0; i < parts.size() - 1; ++i) {
        current += (current.isEmpty() ? "" : "/") + parts.at(i);
        const QFileInfo info(project.filePath(current));
        if (info.isSymLink() || (info.exists() && !info.isDir()))
            return QStringLiteral("Invalid destination directory: ") + current;
    }
    return {};
}
}

bool ComponentInstaller::validTarget(const QString &path)
{
    if (!path.startsWith("src/components/") || path.contains('\\'))
        return false;
    for (const QString &segment : path.split('/')) {
        if (segment.isEmpty() || segment == "." || segment == "..")
            return false;
    }
    return true;
}

bool ComponentInstaller::isInstalled(const QString &projectPath,
                                      const QVariantMap &definition)
{
    if (projectPath.isEmpty())
        return false;
    const QVariantList files = definition.value("files").toList();
    if (files.isEmpty())
        return false;
    const QDir project(projectPath);
    for (const QVariant &entry : files) {
        const QString target = entry.toMap().value("target").toString();
        if (!validTarget(target) || !verifyDirectories(project, target).isEmpty())
            return false;
        const QFileInfo info(project.filePath(target));
        if (!info.isFile() || info.isSymLink())
            return false;
    }
    return true;
}

QString ComponentInstaller::install(const QString &projectPath, const QString &id,
                                    const QVariantMap &definition)
{
    const QDir project(projectPath);
    if (!QFileInfo(project.filePath("src/App.tsx")).isFile())
        return QStringLiteral("This component expects a React TypeScript project (src/App.tsx).");

    const QVariantList files = definition.value("files").toList();
    if (files.isEmpty())
        return QStringLiteral("Component has no installable files: ") + id;

    QVector<PlannedFile> plan;
    QSet<QString> seenTargets;

    // Validate every path and read every resource before writing to the project.
    for (const QVariant &value : files) {
        const QVariantMap file = value.toMap();
        const QString source = file.value("source").toString();
        const QString target = file.value("target").toString();
        if (!validSource(source) || !validTarget(target) || seenTargets.contains(target))
            return QStringLiteral("Invalid file mapping in component: ") + id;
        seenTargets.insert(target);

        const QString directoryError = verifyDirectories(project, target);
        if (!directoryError.isEmpty())
            return directoryError;

        const QFileInfo destination(project.filePath(target));
        if (destination.isSymLink() || (destination.exists() && !destination.isFile()))
            return QStringLiteral("Invalid destination: ") + target;
        if (destination.isFile())
            continue; // Existing user files are never overwritten.

        QFile templateFile(QStringLiteral(":/component-packages/%1/%2").arg(id, source));
        if (!templateFile.open(QIODevice::ReadOnly))
            return QStringLiteral("Cannot open template: ") + templateFile.fileName();
        const QByteArray bytes = templateFile.readAll();
        if (templateFile.error() != QFileDevice::NoError || bytes.isEmpty())
            return QStringLiteral("Cannot read template: ") + templateFile.fileName();

        plan.append({target, bytes});
    }

    for (const PlannedFile &file : plan) {
        const QString folder = QFileInfo(file.target).path();
        if (!project.mkpath(folder))
            return QStringLiteral("Could not create directory: ") + folder;
        const QString directoryError = verifyDirectories(project, file.target);
        if (!directoryError.isEmpty())
            return directoryError;

        const QString destination = project.filePath(file.target);
        if (QFileInfo::exists(destination) || QFileInfo(destination).isSymLink())
            return QStringLiteral("Destination appeared during install: ") + file.target;

        QSaveFile output(destination);
        if (!output.open(QIODevice::WriteOnly)
            || output.write(file.bytes) != file.bytes.size() || !output.commit())
            return QStringLiteral("Could not save ") + file.target + ": " + output.errorString();
    }

    return {};
}
