#include "componentlifecycle.h"

#include "componentinstaller.h"
#include "componentinstallationstore.h"

#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSet>
#include <QStringList>
#include <QUuid>
#include <QVector>
#include <algorithm>

namespace {
struct Relocation {
    QString source; // Project-relative, forward slashes.
    QString target;
};

struct Edit {
    QString originalPath;
    QString finalPath;
    QByteArray original;
    QByteArray updated;
};

struct Analysis {
    QString error;
    QStringList references;
    QVector<Edit> edits;
};

bool safeExistingParents(const QDir &project, const QString &relativeFile)
{
    QString current;
    const QStringList parts = relativeFile.split('/');
    for (int i = 0; i < parts.size() - 1; ++i) {
        current += (current.isEmpty() ? QString() : QStringLiteral("/")) + parts.at(i);
        const QFileInfo info(project.filePath(current));
        if (info.isSymLink() || (info.exists() && !info.isDir()))
            return false;
    }
    return true;
}

QString planFiles(const QString &projectPath, const QVariantMap &definition,
                  const QString &sourceDirectory, const QString &targetDirectory,
                  QVector<Relocation> *plan)
{
    if (!ComponentInstaller::validDirectory(sourceDirectory)
        || !ComponentInstaller::validDirectory(targetDirectory))
        return QStringLiteral("Choose a directory inside the project.");
    if (sourceDirectory == targetDirectory)
        return QStringLiteral("Choose a different destination folder.");
    const QDir project(projectPath);
    QSet<QString> sources;
    QSet<QString> targets;
    for (const QVariant &value : definition.value("files").toList()) {
        const QString name = value.toMap().value("target").toString();
        if (!ComponentInstaller::validTarget(name))
            return QStringLiteral("Invalid component file mapping.");
        const QString from = ComponentInstaller::combinedPath(sourceDirectory, name);
        const QString to = ComponentInstaller::combinedPath(targetDirectory, name);
        if (sources.contains(from) || targets.contains(to))
            return QStringLiteral("Duplicate file mapping in component package.");
        sources.insert(from);
        targets.insert(to);
        if (!safeExistingParents(project, from) || !safeExistingParents(project, to))
            return QStringLiteral("A component path contains an unsafe folder or symbolic link.");
        const QFileInfo input(project.filePath(from));
        if (!input.isFile() || input.isSymLink())
            return QStringLiteral("Component file is missing or unsafe: ") + from;
        const QFileInfo output(project.filePath(to));
        if (output.exists() || output.isSymLink())
            return QStringLiteral("Destination already contains a file: ") + to;
        plan->append({from, to});
    }
    if (plan->isEmpty())
        return QStringLiteral("Component has no files to move.");
    return {};
}

bool sourceCodeFile(const QString &name)
{
    static const QSet<QString> extensions = {
        "js", "jsx", "ts", "tsx", "mjs", "cjs", "mts", "cts", "vue", "svelte", "astro", "mdx"
    };
    return extensions.contains(QFileInfo(name).suffix().toLower());
}

QStringList projectSourceFiles(const QString &projectPath, QString *error)
{
    const QDir project(projectPath);
    QStringList pending{QStringLiteral(".")};
    QStringList result;
    static const QSet<QString> excluded = {
        ".git", ".jeridiengine", "node_modules", "build", "dist", "coverage",
        ".next", ".nuxt", ".vite", ".svelte-kit", "out", "target"
    };
    while (!pending.isEmpty()) {
        const QString folder = pending.takeLast();
        const QDir dir(project.filePath(folder));
        for (const QFileInfo &entry : dir.entryInfoList(QDir::Files | QDir::Dirs
                                   | QDir::Hidden | QDir::NoDotAndDotDot | QDir::NoSymLinks)) {
            if (entry.isSymLink())
                continue;
            const QString relative = project.relativeFilePath(entry.filePath());
            if (entry.isDir()) {
                if (!excluded.contains(entry.fileName()))
                    pending.append(relative);
            } else if (entry.isFile() && sourceCodeFile(entry.fileName())) {
                if (entry.size() > 4 * 1024 * 1024) {
                    *error = QStringLiteral("Source file is too large to scan safely: ") + relative;
                    return {};
                }
                result.append(relative);
            }
            if (pending.size() + result.size() > 20000) {
                *error = QStringLiteral("Project is too large to scan safely (20,000 paths limit).");
                return {};
            }
        }
    }
    return result;
}

// Resolves common TypeScript/Vite relative import forms, including extensionless imports.
QString resolveImport(const QDir &project, const QString &importer, const QString &specifier)
{
    const QString path = specifier.section(QRegularExpression("[?#]"), 0, 0);
    const QString base = QDir::cleanPath(QFileInfo(importer).path() + "/" + path);
    if (!ComponentInstaller::validTarget(base))
        return {};
    QStringList candidates{base};
    if (QFileInfo(base).suffix().isEmpty()) {
        for (const QString &ext : {".tsx", ".ts", ".jsx", ".js", ".mjs", ".cjs",
                                   ".mts", ".cts", ".json", ".css", ".scss"}) {
            candidates.append(base + ext);
            candidates.append(base + "/index" + ext);
        }
    }
    for (const QString &candidate : candidates) {
        const QFileInfo file(project.filePath(candidate));
        if (file.isFile() && !file.isSymLink()
            && safeExistingParents(project, candidate))
            return candidate;
    }
    return {};
}

QString rewrittenSpecifier(const QDir &project, const QString &specifier,
                           const QString &newImporter,
                           const QString &oldResolved, const QString &newResolved)
{
    const QString importerFolder = QFileInfo(project.filePath(newImporter)).absolutePath();
    QString path = QDir(importerFolder).relativeFilePath(project.filePath(newResolved));
    path.replace('\\', '/');
    if (!path.startsWith('.'))
        path.prepend("./");
    const QString originalPath = specifier.section(QRegularExpression("[?#]"), 0, 0);
    if (QFileInfo(originalPath).suffix().isEmpty()) {
        if (oldResolved.contains("/index.")) {
            const int index = path.lastIndexOf("/index.");
            if (index >= 0)
                path.truncate(index);
        } else {
            const int dot = path.lastIndexOf('.');
            const int slash = path.lastIndexOf('/');
            if (dot > slash)
                path.truncate(dot);
        }
    }
    return path + specifier.mid(originalPath.size()); // Keep ?query and #fragment.
}

Analysis scanReferences(const QString &projectPath, const QVector<Relocation> &plan,
                        bool removal)
{
    Analysis result;
    const QDir project(projectPath);
    QHash<QString, QString> moved;
    QSet<QString> movedFiles;
    QSet<QString> componentNames;
    for (const Relocation &file : plan) {
        moved.insert(file.source, file.target);
        movedFiles.insert(file.source);
        componentNames.insert(QFileInfo(file.source).completeBaseName());
        componentNames.insert(QFileInfo(file.source).fileName());
    }
    QString scanError;
    const QStringList files = projectSourceFiles(projectPath, &scanError);
    if (!scanError.isEmpty()) {
        result.error = scanError;
        return result;
    }

    // Rewrites import/export-from, side-effect import, require() and import().
    // Alias imports are flagged instead of guessing a tsconfig/vite alias mapping.
    static const QRegularExpression imports(
        R"((?:\bfrom\s*|\bimport\s*\(\s*|\brequire\s*\(\s*|\bimport\s*)(['"])([^'"\r\n]+)\1)");
    for (const QString &file : files) {
        QFile input(project.filePath(file));
        if (!input.open(QIODevice::ReadOnly)) {
            result.error = QStringLiteral("Could not scan source file: ") + file;
            return result;
        }
        const QByteArray original = input.readAll();
        if (input.error() != QFileDevice::NoError) {
            result.error = QStringLiteral("Could not fully read source file: ") + file;
            return result;
        }
        const QString content = QString::fromUtf8(original);
        const bool importerMoves = movedFiles.contains(file);
        QString updated;
        int last = 0;
        bool changed = false;
        auto matches = imports.globalMatch(content);
        while (matches.hasNext()) {
            const QRegularExpressionMatch match = matches.next();
            const int lineStart = match.capturedStart(0) == 0 ? 0
                : content.lastIndexOf('\n', match.capturedStart(0) - 1) + 1;
            const QString beforeMatch = content.mid(lineStart, match.capturedStart(0) - lineStart)
                                            .trimmed();
            if (beforeMatch.startsWith("//") || beforeMatch.startsWith("*")
                || beforeMatch.startsWith("/*"))
                continue;
            const QString spec = match.captured(2);
            if (!spec.startsWith('.')) {
                const QString importedFile = QFileInfo(
                    spec.section(QRegularExpression("[?#]"), 0, 0)).fileName();
                if (componentNames.contains(importedFile)) {
                    result.error = QStringLiteral("Alias import needs manual adjustment: %1 → %2")
                                       .arg(file, spec);
                    return result;
                }
                continue;
            }
            const QString target = resolveImport(project, file, spec);
            if (target.isEmpty()) {
                if (importerMoves) {
                    result.error = QStringLiteral("Cannot resolve import in component file: %1 → %2")
                                       .arg(file, spec);
                    return result;
                }
                continue;
            }
            const bool targetMoves = moved.contains(target);
            if (!importerMoves && !targetMoves)
                continue;
            if (removal) {
                if (targetMoves && !importerMoves)
                    result.references.append(file + " → " + spec);
                continue;
            }
            const QString newImporter = moved.value(file, file);
            const QString newTarget = moved.value(target, target);
            const QString replacement = rewrittenSpecifier(project, spec, newImporter,
                                                           target, newTarget);
            if (replacement != spec) {
                updated += content.mid(last, match.capturedStart(2) - last);
                updated += replacement;
                last = match.capturedEnd(2);
                changed = true;
                result.references.append(file + ": " + spec + " → " + replacement);
            }
        }
        if (changed) {
            if (content.toUtf8() != original) {
                result.error = QStringLiteral("Source file is not valid UTF-8: ") + file;
                return result;
            }
            updated += content.mid(last);
            result.edits.append({file, moved.value(file, file), original, updated.toUtf8()});
        }
    }
    if (removal && !result.references.isEmpty())
        result.error = QStringLiteral("Remove the listed imports/usages before removing this component.");
    return result;
}

QString writeFile(const QString &path, const QByteArray &bytes)
{
    QSaveFile output(path);
    if (!output.open(QIODevice::WriteOnly)
        || output.write(bytes) != bytes.size() || !output.commit())
        return QStringLiteral("Cannot update file: ") + path + " (" + output.errorString() + ")";
    return {};
}

QString rollbackMoves(const QDir &project, const QVector<Relocation> &plan, int completed)
{
    QStringList failed;
    for (int i = completed - 1; i >= 0; --i) {
        if (!QFile::rename(project.filePath(plan.at(i).target),
                           project.filePath(plan.at(i).source)))
            failed.append(plan.at(i).source);
    }
    return failed.isEmpty() ? QString()
         : QStringLiteral(" Rollback requires attention for: ") + failed.join(", ");
}

QString pruneEmptySourceDirectories(const QDir &project,
                                    const QVector<Relocation> &plan,
                                    const QString &sourceDirectory)
{
    // The old component folder and its descendants only; never delete ancestors.
    if (sourceDirectory == "." || !ComponentInstaller::validDirectory(sourceDirectory))
        return {};

    QSet<QString> candidates{sourceDirectory};
    for (const Relocation &item : plan) {
        QString folder = QFileInfo(item.source).path();
        while (folder == sourceDirectory || folder.startsWith(sourceDirectory + "/")) {
            candidates.insert(folder);
            if (folder == sourceDirectory)
                break;
            folder = QFileInfo(folder).path();
        }
    }
    QStringList ordered;
    for (const QString &candidate : candidates)
        ordered.append(candidate);
    std::sort(ordered.begin(), ordered.end(), [](const QString &left, const QString &right) {
        return left.count('/') > right.count('/');
    });
    for (const QString &folder : ordered) {
        const QFileInfo info(project.filePath(folder));
        if (info.isDir() && !info.isSymLink())
            project.rmdir(folder); // Succeeds only when EMPTY; never recursive.
    }
    const QFileInfo source(project.filePath(sourceDirectory));
    return source.exists()
        ? QStringLiteral("Previous folder preserved (contains other files or could not be removed): ")
              + sourceDirectory
        : QString();
}

QString previewFolderCleanup(const QString &projectPath,
                             const QVector<Relocation> &plan,
                             const QString &sourceDirectory,
                             const QString &targetDirectory)
{
    if (sourceDirectory == ".")
        return QStringLiteral("The project root is always preserved.");
    if (targetDirectory.startsWith(sourceDirectory + "/"))
        return QStringLiteral("The old folder will stay because the new folder is inside it.");
    QSet<QString> movedFiles;
    for (const Relocation &item : plan)
        movedFiles.insert(item.source);

    const QDir project(projectPath);
    QDirIterator iterator(project.filePath(sourceDirectory),
        QDir::AllEntries | QDir::Hidden | QDir::System | QDir::NoDotAndDotDot,
        QDirIterator::Subdirectories);
    int checked = 0;
    while (iterator.hasNext()) {
        const QString absolute = iterator.next();
        const QFileInfo info = iterator.fileInfo();
        const QString relative = project.relativeFilePath(absolute);
        if (++checked > 10000)
            return QStringLiteral("Large source folder: unrelated contents will be preserved.");
        if ((info.isFile() || info.isSymLink()) && !movedFiles.contains(relative))
            return QStringLiteral("The old folder contains additional files and will be preserved.");
    }
    return QStringLiteral("The old folder will be removed automatically if empty after moving.");
}

QString performMoves(const QString &projectPath, const QVector<Relocation> &plan,
                     const QVector<Edit> &edits, const QString &id,
                     const QVariantMap &definition, const QString &newDirectory,
                     bool unregister, const QString &oldDirectory, QString *cleanupNote)
{
    const QDir project(projectPath);
    int movedCount = 0;
    for (const Relocation &item : plan) {
        if (!safeExistingParents(project, item.target)
            || !project.mkpath(QFileInfo(item.target).path())
            || !safeExistingParents(project, item.target)
            || QFileInfo(project.filePath(item.target)).exists()
            || QFileInfo(project.filePath(item.target)).isSymLink()
            || !QFile::rename(project.filePath(item.source), project.filePath(item.target))) {
            return QStringLiteral("Could not move component file: ") + item.source
                   + rollbackMoves(project, plan, movedCount);
        }
        ++movedCount;
    }

    int written = 0;
    QString failure;
    for (const Edit &edit : edits) {
        failure = writeFile(project.filePath(edit.finalPath), edit.updated);
        if (!failure.isEmpty())
            break;
        ++written;
    }
    if (failure.isEmpty()) {
        failure = unregister
            ? ComponentInstallationStore::unregister(projectPath, id)
            : ComponentInstallationStore::relocate(projectPath, id, newDirectory, definition);
    }
    if (failure.isEmpty()) {
        const QString note = pruneEmptySourceDirectories(project, plan, oldDirectory);
        if (cleanupNote)
            *cleanupNote = note;
        return {};
    }

    QStringList rollbackErrors;
    for (int i = written - 1; i >= 0; --i) {
        const Edit &edit = edits.at(i);
        const QString error = writeFile(project.filePath(edit.finalPath), edit.original);
        if (!error.isEmpty())
            rollbackErrors.append(edit.finalPath);
    }
    const QString moveRollback = rollbackMoves(project, plan, movedCount);
    if (!rollbackErrors.isEmpty())
        failure += QStringLiteral(" Could not restore: ") + rollbackErrors.join(", ");
    return failure + moveRollback;
}

QVariantMap errorResult(const QString &error)
{
    return {{"error", error}, {"files", QStringList{}}, {"references", QStringList{}}};
}
} // namespace

QVariantMap ComponentLifecycle::previewMove(const QString &projectPath, const QString &id,
                                            const QVariantMap &definition,
                                            const QString &fromDirectory,
                                            const QString &toDirectory)
{
    Q_UNUSED(id)
    QVector<Relocation> plan;
    const QString error = planFiles(projectPath, definition, fromDirectory, toDirectory, &plan);
    if (!error.isEmpty()) {
        QVariantMap rejected = errorResult(error);
        QStringList planned;
        for (const QVariant &item : definition.value("files").toList()) {
            const QString name = item.toMap().value("target").toString();
            if (ComponentInstaller::validDirectory(toDirectory)
                && ComponentInstaller::validTarget(name))
                planned.append(ComponentInstaller::combinedPath(fromDirectory, name)
                               + " → " + ComponentInstaller::combinedPath(toDirectory, name));
        }
        rejected.insert("files", planned);
        return rejected;
    }
    const Analysis analysis = scanReferences(projectPath, plan, false);
    QStringList files;
    for (const Relocation &item : plan)
        files.append(item.source + " → " + item.target);
    return {{"error", analysis.error}, {"files", files}, {"references", analysis.references},
            {"cleanup", previewFolderCleanup(projectPath, plan, fromDirectory, toDirectory)}};
}

QString ComponentLifecycle::move(const QString &projectPath, const QString &id,
                                 const QVariantMap &definition, const QString &fromDirectory,
                                 const QString &toDirectory, QString *cleanupNote)
{
    QVector<Relocation> plan;
    const QString error = planFiles(projectPath, definition, fromDirectory, toDirectory, &plan);
    if (!error.isEmpty())
        return error;
    const Analysis analysis = scanReferences(projectPath, plan, false);
    if (!analysis.error.isEmpty())
        return analysis.error;
    return performMoves(projectPath, plan, analysis.edits, id, definition, toDirectory,
                        false, fromDirectory, cleanupNote);
}

QVariantMap ComponentLifecycle::previewRemove(const QString &projectPath, const QString &id,
                                              const QVariantMap &definition,
                                              const QString &fromDirectory)
{
    Q_UNUSED(id)
    QVector<Relocation> plan;
    if (!ComponentInstaller::validDirectory(fromDirectory))
        return errorResult(QStringLiteral("Invalid installed component folder."));
    const QDir project(projectPath);
    QSet<QString> seen;
    for (const QVariant &entry : definition.value("files").toList()) {
        const QString name = entry.toMap().value("target").toString();
        if (!ComponentInstaller::validTarget(name) || seen.contains(name))
            return errorResult(QStringLiteral("Invalid component file mapping."));
        seen.insert(name);
        const QString source = ComponentInstaller::combinedPath(fromDirectory, name);
        const QFileInfo file(project.filePath(source));
        if (!safeExistingParents(project, source) || !file.isFile() || file.isSymLink())
            return errorResult(QStringLiteral("Component file is missing or unsafe: ") + source);
        plan.append({source, source}); // Scanner only needs the original paths.
    }
    if (plan.isEmpty())
        return errorResult(QStringLiteral("Component has no files to remove."));
    const Analysis analysis = scanReferences(projectPath, plan, true);
    QStringList files;
    for (const Relocation &item : plan)
        files.append(item.source);
    return {{"error", analysis.error}, {"files", files}, {"references", analysis.references},
            {"cleanup", previewFolderCleanup(projectPath, plan, fromDirectory, QString())}};
}

QString ComponentLifecycle::remove(const QString &projectPath, const QString &id,
                                   const QVariantMap &definition, const QString &fromDirectory,
                                   QString *trashDirectory, QString *cleanupNote)
{
    const QString previewError = previewRemove(projectPath, id, definition, fromDirectory)
                                     .value("error").toString();
    if (!previewError.isEmpty())
        return previewError;
    const QDir project(projectPath);
    const QFileInfo metadata(project.filePath(".jeridiengine"));
    const QFileInfo trash(project.filePath(".jeridiengine/trash"));
    if (metadata.isSymLink() || (metadata.exists() && !metadata.isDir())
        || trash.isSymLink() || (trash.exists() && !trash.isDir()))
        return QStringLiteral("Unsafe .jeridiengine/trash path.");

    const QString suffix = QDateTime::currentDateTimeUtc().toString("yyyyMMdd-HHmmss")
        + "-" + QUuid::createUuid().toString(QUuid::WithoutBraces).left(8);
    const QString backupDirectory = ".jeridiengine/trash/" + id + "-" + suffix;
    QVector<Relocation> plan;
    for (const QVariant &entry : definition.value("files").toList()) {
        const QString name = entry.toMap().value("target").toString();
        plan.append({ComponentInstaller::combinedPath(fromDirectory, name),
                     ComponentInstaller::combinedPath(backupDirectory, name)});
    }
    const QString error = performMoves(projectPath, plan, {}, id, definition, {},
                                       true, fromDirectory, cleanupNote);
    if (error.isEmpty() && trashDirectory)
        *trashDirectory = backupDirectory;
    return error;
}
