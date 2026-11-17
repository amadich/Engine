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

bool safeRelativePath(const QString &path)
{
    if (path.isEmpty() || path.startsWith('/') || path.contains('\\'))
        return false;
    for (const QString &segment : path.split('/')) {
        if (segment.isEmpty() || segment == "." || segment == "..")
            return false;
    }
    return true;
}

QString verifyDirectories(const QDir &project, const QString &relativeFile)
{
    const QStringList parts = relativeFile.split('/');
    QString current;
    for (int i = 0; i < parts.size() - 1; ++i) {
        current += (current.isEmpty() ? "" : "/") + parts.at(i);
        const QFileInfo info(project.filePath(current));
        if (info.isSymLink() || (info.exists() && !info.isDir()))
            return QStringLiteral("Invalid destination directory: ") + current;
    }
    return {};
}

QString validateFileDestination(const QDir &project, const QString &relativeFile)
{
    const QString directoryError = verifyDirectories(project, relativeFile);
    if (!directoryError.isEmpty())
        return directoryError;
    const QFileInfo destination(project.filePath(relativeFile));
    if (destination.isSymLink() || destination.exists())
        return QStringLiteral("File already exists (nothing overwritten): ") + relativeFile;
    return {};
}
}

bool ComponentInstaller::validTarget(const QString &path)
{
    return safeRelativePath(path) && path != ".jeridiengine"
           && !path.startsWith(".jeridiengine/");
}

bool ComponentInstaller::validDirectory(const QString &path)
{
    return path == "." || (safeRelativePath(path)
            && path != ".jeridiengine" && !path.startsWith(".jeridiengine/"));
}

QString ComponentInstaller::combinedPath(const QString &directory, const QString &target)
{
    return directory == "." ? target : directory + "/" + target;
}

bool ComponentInstaller::isInstalled(const QString &projectPath,
                                     const QVariantMap &definition,
                                     const QString &relativeDirectory)
{
    if (projectPath.isEmpty() || !validDirectory(relativeDirectory))
        return false;
    const QVariantList files = definition.value("files").toList();
    if (files.isEmpty())
        return false;
    const QDir project(projectPath);
    for (const QVariant &entry : files) {
        const QString target = entry.toMap().value("target").toString();
        if (!validTarget(target))
            return false;
        const QString relativeFile = combinedPath(relativeDirectory, target);
        if (!verifyDirectories(project, relativeFile).isEmpty())
            return false;
        const QFileInfo info(project.filePath(relativeFile));
        if (!info.isFile() || info.isSymLink())
            return false;
    }
    return true;
}

QVariantMap ComponentInstaller::previewInstall(const QString &projectPath, const QString &id,
                                                const QVariantMap &definition,
                                                const QString &relativeDirectory)
{
    QVariantMap result{{"error", QString()}, {"files", QStringList{}},
                       {"references", QStringList{}}, {"collisions", QStringList{}}};
    const QDir project(projectPath);
    if (!QFileInfo(project.filePath("package.json")).isFile()) {
        result["error"] = QStringLiteral("Open an npm project (package.json) first.");
        return result;
    }
    if (!validDirectory(relativeDirectory)) {
        result["error"] = QStringLiteral("Destination must be a project-relative folder without '..'.");
        return result;
    }
    QSet<QString> unique;
    QStringList planned;
    QStringList collisions;
    for (const QVariant &entry : definition.value("files").toList()) {
        const QVariantMap mapping = entry.toMap();
        const QString source = mapping.value("source").toString();
        const QString target = mapping.value("target").toString();
        if (!validTarget(target) || unique.contains(target)
            || !safeRelativePath(source) || !source.startsWith("template/")) {
            result["error"] = QStringLiteral("Invalid package manifest for ") + id;
            return result;
        }
        unique.insert(target);
        QFile templateFile(QStringLiteral(":/component-packages/%1/%2").arg(id, source));
        if (!templateFile.open(QIODevice::ReadOnly) || templateFile.size() == 0) {
            result["error"] = QStringLiteral("Missing package template: ") + source;
            return result;
        }
        const QString destination = combinedPath(relativeDirectory, target);
        planned.append(destination);
        const QString problem = validateFileDestination(project, destination);
        if (!problem.isEmpty())
            collisions.append(problem);
    }
    result["files"] = planned;
    result["collisions"] = collisions;
    if (planned.isEmpty())
        result["error"] = QStringLiteral("Component package contains no files.");
    else if (!collisions.isEmpty())
        result["error"] = QStringLiteral("Destination contains conflicts; choose another folder.");
    return result;
}

QString ComponentInstaller::install(const QString &projectPath, const QString &id,
                                    const QVariantMap &definition,
                                    const QString &relativeDirectory,
                                    const QString &draftConfiguration,
                                    QStringList *createdFiles)
{
    if (!createdFiles)
        return QStringLiteral("Internal error: missing installation result.");
    createdFiles->clear();

    const QDir project(projectPath);
    if (!QFileInfo(project.filePath("package.json")).isFile())
        return QStringLiteral("Open a project containing package.json first.");
    if (!validDirectory(relativeDirectory))
        return QStringLiteral("Choose a directory inside the project (no '..' or absolute paths).");

    const QVariantList files = definition.value("files").toList();
    if (files.isEmpty())
        return QStringLiteral("Component has no installable files: ") + id;

    const QString configTarget = definition.value("configTarget").toString();
    QVector<PlannedFile> plan;
    QSet<QString> seenTargets;
    for (const QVariant &value : files) {
        const QVariantMap mapping = value.toMap();
        const QString source = mapping.value("source").toString();
        const QString target = mapping.value("target").toString();
        if (!safeRelativePath(source) || !source.startsWith("template/")
            || !validTarget(target) || seenTargets.contains(target))
            return QStringLiteral("Invalid package file mapping: ") + id;
        seenTargets.insert(target);

        const QString relativeFile = combinedPath(relativeDirectory, target);
        const QString error = validateFileDestination(project, relativeFile);
        if (!error.isEmpty())
            return error;

        QFile templateFile(QStringLiteral(":/component-packages/%1/%2").arg(id, source));
        if (!templateFile.open(QIODevice::ReadOnly))
            return QStringLiteral("Cannot open template: ") + templateFile.fileName();
        QByteArray bytes = templateFile.readAll();
        if (templateFile.error() != QFileDevice::NoError || bytes.isEmpty())
            return QStringLiteral("Cannot read template: ") + templateFile.fileName();

        if (!draftConfiguration.isEmpty() && target == configTarget)
            bytes = draftConfiguration.toUtf8();
        plan.append({relativeFile, bytes});
    }

    // All templates and destination paths have been checked before the first write.
    for (const PlannedFile &item : plan) {
        const QString folder = QFileInfo(item.target).path();
        if (folder != "." && !project.mkpath(folder))
            return QStringLiteral("Could not create destination directory: ") + folder;
        const QString error = validateFileDestination(project, item.target);
        if (!error.isEmpty())
            return error;

        const QString destination = project.filePath(item.target);
        QSaveFile output(destination);
        if (!output.open(QIODevice::WriteOnly)
            || output.write(item.bytes) != item.bytes.size() || !output.commit())
            return QStringLiteral("Could not save ") + item.target + ": " + output.errorString();
        createdFiles->append(destination);
    }

    return {};
}
