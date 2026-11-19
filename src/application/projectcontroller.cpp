#include "projectcontroller.h"
#include "projectscaffolder.h"
#include "componentregistry.h"

#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSaveFile>
#include <QFile>
#include <QDesktopServices>
#include <QStringList>
#include <algorithm>

namespace {
const QString devServerAddress = QStringLiteral("http://127.0.0.1:5173/");
const QString nextServerAddress = QStringLiteral("http://127.0.0.1:3000/");
}

namespace {

constexpr qint64 kEditorLimit = 512 * 1024;

QString readSpringEnvironment(const QDir &project, QProcessEnvironment &environment)
{
    const QFileInfo info(project.filePath(".env"));
    if (info.isSymLink())
        return QStringLiteral(".env must be a local project file.");
    if (!info.exists())
        return {};
    QFile file(info.filePath());
    if (!info.isFile() || info.size() > 64 * 1024 || !file.open(QIODevice::ReadOnly))
        return QStringLiteral("Could not load the project .env file.");
    const QStringList lines = QString::fromUtf8(file.readAll()).split('\n');
    if (file.error() != QFileDevice::NoError)
        return QStringLiteral("Could not read the project .env file.");

    static const QRegularExpression property(
        QStringLiteral("^(?:export\\s+)?([A-Z_][A-Z0-9_]*)\\s*=(.*)$"));
    for (qsizetype index = 0; index < lines.size(); ++index) {
        const QString line = lines.at(index).trimmed();
        if (line.isEmpty() || line.startsWith('#'))
            continue;
        const auto match = property.match(line);
        if (!match.hasMatch())
            return QStringLiteral("Invalid or unsupported Spring .env entry on line %1.").arg(index + 1);
        const QString key = match.captured(1);
        static const QStringList prefixes{"JERIDI_", "SPRING_", "SERVER_", "DB_", "JWT_", "APP_", "MINIO_"};
        if (std::none_of(prefixes.cbegin(), prefixes.cend(),
                         [&key](const QString &prefix) { return key.startsWith(prefix); }))
            continue;
        QString value = match.captured(2).trimmed();
        if (value.startsWith('"') || value.startsWith('\'')) {
            if (value.size() < 2 || value.back() != value.front())
                return QStringLiteral("Unclosed quote in .env on line %1.").arg(index + 1);
            value = value.mid(1, value.size() - 2);
        }
        if (value.contains(QChar::Null))
            return QStringLiteral("Invalid .env value on line %1.").arg(index + 1);
        environment.insert(key, value);
    }
    return {};
}

bool isImageFile(const QString &suffix)
{
    static const QStringList extensions{"png", "jpg", "jpeg", "webp", "gif", "svg", "bmp"};
    return extensions.contains(suffix.toLower());
}

bool isInsideRoot(const QString &root, const QString &filePath)
{
    return !root.isEmpty() && !filePath.isEmpty()
        && (filePath == root || filePath.startsWith(root + QDir::separator()));
}

bool isEditableTextFile(const QString &suffix)
{
    static const QStringList extensions{
        "tsx", "ts", "jsx", "js", "mjs", "cjs", "json", "css", "scss", "html",
        "md", "mdx", "txt", "qml", "cpp", "cc", "c", "h", "hpp", "java", "vue",
        "xml", "properties", "yml", "yaml", "gradle", "kt", "py", "sh",
        "sql", "toml", "swift", "gitignore"
    };

    return extensions.contains(suffix.toLower());
}

bool isEditableName(const QString &fileName)
{
    static const QStringList names{
        "Dockerfile", "Makefile", "LICENSE", ".env", ".env.example",
        ".gitignore", ".editorconfig", "Gemfile", "Procfile"
    };
    return names.contains(fileName, Qt::CaseInsensitive);
}

}

QUrl ProjectController::previewUrl() const
{
    return m_previewUrl;
}

ProjectController::ProjectController(QObject *parent)
    : QObject(parent)
{
    connect(&m_processRunner, &ProcessRunner::runningChanged,
            this, [this]() {
                if (!busy()) {
                    m_devServerRequested = false;
                    m_devServerOutputTail.clear();

                    if (!m_previewUrl.isEmpty()) {
                        m_previewUrl = QUrl();
                        emit previewUrlChanged();
                    }
                }

                emit busyChanged();
            });
    connect(&m_processRunner, &ProcessRunner::logMessage,
            this, &ProjectController::logMessage);
    connect(&m_processRunner, &ProcessRunner::outputReceived,
            this, [this](const QString &text) {
                emit outputReceived(text);

                if (!devServerActive() || !m_previewUrl.isEmpty()) {
                    return;
                }

                m_devServerOutputTail += text;

                const bool next = projectFramework() == "next-js";
                const QString address = next ? nextServerAddress : devServerAddress;
                const QString marker = next ? QStringLiteral("Ready in") : address;
                if (m_devServerOutputTail.contains(marker)) {
                    m_previewUrl = QUrl(address);
                    m_devServerOutputTail.clear();
                    emit previewUrlChanged();
                    return;
                }

                // Keep enough text to recognize the URL across two output chunks.
                m_devServerOutputTail =
                    m_devServerOutputTail.right(marker.size() - 1);
            });
}

QStringList ProjectController::supportedProjectFrameworks() const
{
    return ProjectScaffolder::supportedFrameworks();
}

QString ProjectController::activeProjectName() const
{
    return m_activeProjectName;
}

QString ProjectController::activeProjectPath() const
{
    return m_activeProjectPath;
}

bool ProjectController::busy() const
{
    return m_processRunner.running();
}

bool ProjectController::createProject(const QString &projectName,
                                      const QUrl &parentFolder)
{
    if (busy()) {
        emit logMessage("A process is already running.");
        return false;
    }

    const QString name = projectName.trimmed();
    static const QRegularExpression namePattern("^[a-z][a-z0-9_-]{0,63}$");

    if (!namePattern.match(name).hasMatch()) {
        emit logMessage(
            "Error: Use 1-64 lowercase letters, numbers, '-' or '_'. "
            "Start with a letter."
        );
        return false;
    }

    if (!parentFolder.isLocalFile()) {
        emit logMessage("Error: Choose a local folder.");
        return false;
    }

    const QDir parentDirectory(parentFolder.toLocalFile());

    if (!parentDirectory.exists()) {
        emit logMessage("Error: The selected folder does not exist.");
        return false;
    }

    const QString projectPath = parentDirectory.absoluteFilePath(name);
    const QFileInfo projectInfo(projectPath);

    if (projectInfo.exists() || projectInfo.isSymLink()) {
        emit logMessage("Error: A file or folder already exists at " + projectPath);
        return false;
    }

    emit logMessage("Creating project: " + name);

    if (!parentDirectory.mkdir(name)) {
        emit logMessage(
            "Error: Could not create the project folder. "
            "Check folder permissions and available space."
        );
        return false;
    }

    m_activeProjectName = name;
    m_activeProjectPath = projectPath;
    m_profile.clear();
    emit activeProjectChanged();

    emit logMessage("Project folder created: " + projectPath);
    emit projectCreated(name, projectPath);
    return true;
}

bool ProjectController::createConfiguredProject(const QVariantMap &options)
{
    if (busy()) {
        m_lastProjectError = "Finish the current command before creating a project.";
        emit lastProjectErrorChanged();
        return false;
    }
    const auto result = ProjectScaffolder::create(options);
    m_lastProjectError = result.error;
    emit lastProjectErrorChanged();
    if (!result.success()) {
        emit logMessage("Project creation failed: " + result.error);
        return false;
    }
    m_activeProjectPath = result.projectPath;
    m_activeProjectName = QFileInfo(result.projectPath).fileName();
    m_profile = ProjectScaffolder::detect(result.projectPath);
    emit activeProjectChanged();
    emit projectCreated(m_activeProjectName, result.projectPath);
    emit logMessage("Created " + result.framework + " project: " + result.projectPath);
    if (options.value("initializeGit").toBool())
        emit logMessage(result.gitInitialized ? "Git repository initialized."
                                              : "Git init skipped or unavailable.");
    return true;
}

QString ProjectController::suggestedComponentDirectory(const QString &id) const
{
    return ProjectScaffolder::suggestedDirectory(m_activeProjectPath,
                                                 ComponentRegistry::instance().component(id));
}

void ProjectController::checkNpm()
{
    m_processRunner.run("npm", {"--version"});
}

void ProjectController::generateReact()
{
    if (busy()) {
        emit logMessage("A process is already running.");
        return;
    }

    if (m_activeProjectPath.isEmpty()) {
        emit logMessage("Error: Create a project folder first.");
        return;
    }

    const QDir projectDirectory(m_activeProjectPath);

    if (!projectDirectory.isAbsolute() || !projectDirectory.exists()) {
        emit logMessage("Error: The project folder is invalid.");
        return;
    }

    const QStringList entries = projectDirectory.entryList(
        QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden | QDir::System
    );

    if (!entries.isEmpty()) {
        emit logMessage("Error: React generation requires an empty project folder.");
        return;
    }

    m_processRunner.run(
        "npm",
        {"create", "--yes", "vite@latest", ".", "--", "--template",
         "react-ts", "--no-interactive"},
        projectDirectory.absolutePath()
    );
}



bool ProjectController::openProject(const QUrl &folder)
{
    if (busy()) {
        emit logMessage("A process is already running.");
        return false;
    }

    if (!folder.isLocalFile() || folder.toLocalFile().isEmpty()) {
        emit logMessage("Error: Choose a local project folder.");
        return false;
    }

    const QDir directory(folder.toLocalFile());
    const QVariantMap profile = ProjectScaffolder::detect(directory.absolutePath());
    if (profile.isEmpty()) {
        emit logMessage("Error: Choose a supported project (Jeridi profile, package.json, pom.xml, or index.html).");
        return false;
    }

    m_activeProjectName = directory.dirName();
    m_activeProjectPath = directory.absolutePath();
    m_profile = profile;
    emit activeProjectChanged();

    emit logMessage("Project opened: " + m_activeProjectPath);
    return true;
}

bool ProjectController::closeProject()
{
    if (busy()) {
        emit logMessage("Stop the running process before closing the project.");
        return false;
    }
    if (m_activeProjectPath.isEmpty()) return true;
    const QString name = m_activeProjectName;
    m_activeProjectName.clear();
    m_activeProjectPath.clear();
    m_profile.clear();
    m_devServerRequested = false;
    m_devServerOutputTail.clear();
    if (!m_previewUrl.isEmpty()) {
        m_previewUrl = QUrl();
        emit previewUrlChanged();
    }
    emit activeProjectChanged();
    emit logMessage("Project closed: " + name);
    return true;
}

bool ProjectController::revealProjectFolder() const
{
    return !m_activeProjectPath.isEmpty()
        && QDesktopServices::openUrl(QUrl::fromLocalFile(m_activeProjectPath));
}

void ProjectController::installDependencies()
{
    if (busy()) {
        emit logMessage("A process is already running.");
        return;
    }

    if (m_activeProjectPath.isEmpty()) {
        emit logMessage("Error: Open a project first.");
        return;
    }

    const QDir directory(m_activeProjectPath);
    if (QFileInfo::exists(directory.filePath("package.json"))) {
        m_processRunner.run("npm", {"install"}, m_activeProjectPath);
    } else if (QFileInfo::exists(directory.filePath("pom.xml"))) {
        m_processRunner.run("mvn", {"dependency:go-offline"}, m_activeProjectPath);
    } else {
        emit logMessage("This project has no npm or Maven dependencies to install.");
    }
}


bool ProjectController::devServerActive() const
{
    return m_devServerRequested && busy();
}

void ProjectController::startDevServer()
{
    if (busy()) {
        emit logMessage("A process is already running.");
        return;
    }

    if (m_activeProjectPath.isEmpty()) {
        emit logMessage("Error: Open a project first.");
        return;
    }

    const QDir projectDirectory(m_activeProjectPath);
    const QString framework = m_profile.value("framework").toString();
    if (framework == "spring-boot") {
        if (!QFileInfo::exists(projectDirectory.filePath("pom.xml"))) {
            emit logMessage("Error: Spring Boot pom.xml is missing.");
            return;
        }
        QProcessEnvironment environment;
        const QString error = readSpringEnvironment(projectDirectory, environment);
        if (!error.isEmpty()) {
            emit logMessage(error);
            return;
        }
        m_devServerRequested = true;
        m_processRunner.run("mvn", {"spring-boot:run"}, m_activeProjectPath, environment);
        if (!busy()) m_devServerRequested = false;
        return;
    }
    if (framework == "express-ts") {
        if (!QFileInfo::exists(projectDirectory.filePath("node_modules"))) {
            emit logMessage("Error: Install npm dependencies before running Express.");
            return;
        }
        m_devServerRequested = true;
        m_processRunner.run("npm", {"run", "dev"}, m_activeProjectPath);
        if (!busy()) m_devServerRequested = false;
        return;
    }
    if (framework == "next-js") {
        const QString script = projectDirectory.absoluteFilePath("node_modules/next/dist/bin/next");
        if (!QFileInfo(script).isFile()) {
            emit logMessage("Error: Install npm dependencies before running Next.js.");
            return;
        }
        m_devServerRequested = true;
        m_processRunner.run("node", {script, "dev", "--hostname", "127.0.0.1", "--port", "3000"},
                            m_activeProjectPath);
        if (!busy()) m_devServerRequested = false;
        return;
    }
    if (framework != "react-vite" && framework != "vue-vite") {
        emit logMessage("The Run action currently supports Vite, Express and Spring Boot projects.");
        return;
    }
    const QString viteScript =
        projectDirectory.absoluteFilePath("node_modules/vite/bin/vite.js");

    if (!QFileInfo(projectDirectory.filePath("package.json")).isFile()
        || !QFileInfo(viteScript).isFile()) {
        emit logMessage(
            "Error: Open a Vite project and install dependencies first."
            );
        return;
    }

    m_devServerRequested = true;

    m_processRunner.run(
        "node",
        {viteScript, "--host", "127.0.0.1", "--port", "5173",
         "--strictPort"},
        m_activeProjectPath
        );

    // run() can return early if it cannot find the executable.
    if (!busy()) {
        m_devServerRequested = false;
    }
}

void ProjectController::showComponentPreview(const QString &directory)
{
    if (m_previewUrl.isEmpty())
        return;
    static const QRegularExpression nextRoute(
        QStringLiteral("^(?:src/)?app/([a-zA-Z0-9_-]+(?:/[a-zA-Z0-9_-]+)*)$"));
    static const QRegularExpression viteDirectory(
        QStringLiteral("^[a-zA-Z0-9_-]+(?:/[a-zA-Z0-9_-]+)*$"));
    QUrl url;
    if (projectFramework() == "next-js") {
        const auto match = nextRoute.match(directory);
        if (!match.hasMatch())
            return;
        url = QUrl(nextServerAddress);
        url.setPath("/" + match.captured(1));
    } else if (projectFramework() == "react-vite" && viteDirectory.match(directory).hasMatch()) {
        const QString page = directory + "/preview.html";
        if (!QFileInfo(QDir(m_activeProjectPath).filePath(page)).isFile())
            return;
        url = QUrl(devServerAddress);
        url.setPath("/" + page);
    }
    if (url.isEmpty())
        return;
    if (url != m_previewUrl) {
        m_previewUrl = url;
        emit previewUrlChanged();
    }
    emit packagePreviewRequested();
}

void ProjectController::stopDevServer()
{
    if (devServerActive()) {
        m_processRunner.stop();
    }
}





QUrl ProjectController::projectFolderUrl() const
{
    if (m_activeProjectPath.isEmpty()) {
        return {};
    }

    return QUrl::fromLocalFile(m_activeProjectPath);
}

QVariantMap ProjectController::inspectFile(const QUrl &fileUrl) const
{
    if (m_activeProjectPath.isEmpty() || !fileUrl.isLocalFile()) {
        return {{"error", "Open a project and choose a local file."}};
    }

    const QString projectRoot = QDir(m_activeProjectPath).canonicalPath();
    const QFileInfo fileInfo(fileUrl.toLocalFile());
    const QString filePath = fileInfo.canonicalFilePath();

    if (projectRoot.isEmpty() || filePath.isEmpty() || !fileInfo.isFile()) {
        return {{"error", "The selected file is unavailable."}};
    }

    const QString relativePath = QDir(projectRoot).relativeFilePath(filePath);

    if (relativePath == ".." || relativePath.startsWith("../")
        || QDir::isAbsolutePath(relativePath)) {
        return {{"error", "The selected file is outside the project."}};
    }

    const QString suffix = fileInfo.suffix().toLower();

    QVariantMap details{
        {"name", fileInfo.fileName()},
        {"path", relativePath},
        {"extension", suffix},
        {"size", fileInfo.size()},
        {"kind", "file"}
    };

    if (isImageFile(suffix)) {
        details["kind"] = "image";
        details["imageUrl"] = QUrl::fromLocalFile(filePath);
        return details;
    }

    if (isEditableTextFile(suffix) || isEditableName(fileInfo.fileName())) {
        QFile file(filePath);
        if (!file.open(QIODevice::ReadOnly)) {
            details["error"] = file.errorString();
            return details;
        }
        const QByteArray content = file.read(kEditorLimit);
        if (file.error() != QFileDevice::NoError) {
            details["error"] = file.errorString();
            return details;
        }
        details["kind"] = "text";
        details["text"] = QString::fromUtf8(content);
        details["truncated"] = !file.atEnd();
    }

    return details;
}





QString ProjectController::saveTextFile(const QUrl &fileUrl,
                                        const QString &originalText,
                                        const QString &newText)
{
    if (busy() && !devServerActive()) {
        return QStringLiteral("Wait for the current command to finish.");
    }

    const QVariantMap details = inspectFile(fileUrl);
    const QString error = details.value("error").toString();

    if (!error.isEmpty()) {
        return error;
    }

    if (details.value("kind").toString() != "text"
        || details.value("truncated").toBool()) {
        return QStringLiteral("This file cannot be edited here.");
    }

    if (details.value("text").toString() != originalText) {
        return QStringLiteral(
            "The file changed on disk. Keep a copy of your edits and reopen it."
            );
    }

    const QByteArray bytes = newText.toUtf8();

    if (bytes.size() > kEditorLimit) {
        return QStringLiteral("The editor supports files up to 512 KiB.");
    }

    const QString path = QFileInfo(fileUrl.toLocalFile()).canonicalFilePath();

    if (path.isEmpty()) {
        return QStringLiteral("The file is no longer available.");
    }

    QSaveFile file(path);

    if (!file.open(QIODevice::WriteOnly)
        || file.write(bytes) != bytes.size()
        || !file.commit()) {
        return file.errorString();
    }

    emit logMessage("File saved: " + details.value("path").toString());
    return {};
}



QVariantList ProjectController::quickOpenFiles() const
{
    if (m_activeProjectPath.isEmpty()) return {};
    const QString root = QDir(m_activeProjectPath).canonicalPath();
    if (root.isEmpty()) return {};

    const QDir project(root);
    QVariantList results;
    QStringList pendingFolders{root};
    const QStringList skipped{ "node_modules", "target", "dist", "build", ".git",
                               ".next", ".vite", "coverage", ".gradle", ".idea" };
    while (!pendingFolders.isEmpty() && results.size() < 4000) {
        const QDir folder(pendingFolders.takeLast());
        const auto entries = folder.entryInfoList(
            QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot | QDir::NoSymLinks,
            QDir::Name | QDir::IgnoreCase);
        for (const QFileInfo &entry : entries) {
            if (entry.isDir()) {
                if (!skipped.contains(entry.fileName())) pendingFolders.append(entry.absoluteFilePath());
                continue;
            }
            const bool image = isImageFile(entry.suffix());
            if ((!image && (entry.size() > kEditorLimit || !isEditableTextFile(entry.suffix()) && !isEditableName(entry.fileName())))
                || results.size() >= 4000) continue;
            results.append(QVariantMap{
                {"name", entry.fileName()},
                {"path", project.relativeFilePath(entry.absoluteFilePath())},
                {"url", QUrl::fromLocalFile(entry.absoluteFilePath())},
                {"kind", image ? "image" : "text"}
            });
        }
    }
    return results;
}

QVariantMap ProjectController::resolveImport(const QUrl &sourceFile,
                                              const QString &specifier) const
{
    QVariantMap result{{"specifier", specifier}, {"status", "external"},
                       {"kind", "dependency"}};
    if (m_activeProjectPath.isEmpty()) return result;
    const QString root = QDir(m_activeProjectPath).canonicalPath();
    if (root.isEmpty() || !sourceFile.isLocalFile()) return result;
    const QString source = QFileInfo(sourceFile.toLocalFile()).canonicalFilePath();
    if (!isInsideRoot(root, source) || !QFileInfo(source).isFile()) return result;

    QString path = specifier.trimmed();
    if (path.isEmpty()) return result;
    // Strip web-loader query and fragment suffixes (e.g. icon.svg?raw).
    if (path.contains('?')) path = path.left(path.indexOf('?'));
    if (path.contains('#')) path = path.left(path.indexOf('#'));
    QString base;
    if (path.startsWith("./") || path.startsWith("../")) {
        base = QFileInfo(source).absoluteDir().absoluteFilePath(path);
    } else if (path.startsWith("@/") || path.startsWith("~/")) {
        base = QDir(root).filePath("src/" + path.mid(2));
    } else if (path.startsWith('/')) {
        base = QDir(root).filePath("public/" + path.mid(1));
    } else if (source.endsWith(".java") && path.contains('.')) {
        // Java imports use dotted package paths. Dependencies remain external.
        base = QDir(root).filePath("src/main/java/" + QString(path).replace('.', '/'));
    } else {
        return result;
    }

    result["status"] = "missing";
    result["kind"] = "missing";
    const QStringList extensions{ "", ".ts", ".tsx", ".js", ".jsx", ".vue",
        ".json", ".css", ".scss", ".html", ".qml", ".java", ".kt",
        ".cpp", ".h", ".hpp", ".svg", ".png", ".jpg", ".jpeg", ".webp", ".gif" };
    const QStringList indexNames{ "/index.ts", "/index.tsx", "/index.js",
                                  "/index.jsx", "/index.vue", "/index.qml" };
    QStringList candidates;
    for (const auto &ext : extensions) candidates.append(base + ext);
    for (const auto &idx : indexNames) candidates.append(base + idx);

    for (const QString &candidate : candidates) {
        const QFileInfo info(candidate);
        if (!info.isFile()) continue;
        const QString canonical = info.canonicalFilePath();
        if (!isInsideRoot(root, canonical)) continue;
        result["status"] = "local";
        result["kind"] = isImageFile(info.suffix()) ? "image" : "text";
        result["name"] = info.fileName();
        result["path"] = QDir(root).relativeFilePath(canonical);
        result["url"] = QUrl::fromLocalFile(canonical);
        return result;
    }
    if (source.endsWith(".java") && !specifier.startsWith('.')) {
        result["status"] = "external";
        result["kind"] = "dependency";
    }
    return result;
}

QStringList ProjectController::suggestImportPaths(const QUrl &sourceFile,
                                                   const QString &prefix) const
{
    if (m_activeProjectPath.isEmpty()) return {};
    const QString root = QDir(m_activeProjectPath).canonicalPath();
    if (root.isEmpty() || !sourceFile.isLocalFile() || prefix.size() > 240)
        return {};
    const QString source = QFileInfo(sourceFile.toLocalFile()).canonicalFilePath();
    if (!isInsideRoot(root, source) || !QFileInfo(source).isFile()) return {};
    QString base;
    if (prefix.startsWith("./") || prefix.startsWith("../"))
        base = QFileInfo(source).absolutePath();
    else if (prefix.startsWith("@/") || prefix.startsWith("~/"))
        base = QDir(root).filePath("src");
    else return {};

    const int slash = prefix.lastIndexOf('/');
    if (slash < 0) return {};
    const QString folderSuffix = prefix.mid(prefix.startsWith("@/") || prefix.startsWith("~/") ? 2 : 0,
                                             slash + 1 - (prefix.startsWith("@/") || prefix.startsWith("~/") ? 2 : 0));
    // For relative imports keep the ./ or ../ directory prefix, for aliases remove @/.
    const bool alias = prefix.startsWith("@/") || prefix.startsWith("~/");
    const QString relativeFolder = alias ? folderSuffix : prefix.left(slash + 1);
    const QString directoryPath = QDir(base).absoluteFilePath(relativeFolder);
    const QString canonicalFolder = QDir(directoryPath).canonicalPath();
    if (!isInsideRoot(root, canonicalFolder)) return {};
    const QString needle = prefix.mid(slash + 1);
    QStringList values;
    const QDir dir(canonicalFolder);
    const auto entries = dir.entryInfoList(QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot | QDir::NoSymLinks,
                                           QDir::DirsFirst | QDir::Name | QDir::IgnoreCase);
    for (const QFileInfo &entry : entries) {
        if (entry.fileName().startsWith('.') || entry.fileName() == "node_modules") continue;
        if (!entry.fileName().startsWith(needle, Qt::CaseInsensitive)) continue;
        if (!entry.isDir() && !isEditableTextFile(entry.suffix()) && !isEditableName(entry.fileName()) && !isImageFile(entry.suffix())) continue;
        values.append(prefix.left(slash + 1) + entry.fileName() + (entry.isDir() ? "/" : ""));
        if (values.size() >= 24) break;
    }
    return values;
}
