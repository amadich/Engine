#include "projectcontroller.h"

#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSaveFile>
#include <QFile>

namespace {
const QString devServerAddress = QStringLiteral("http://127.0.0.1:5173/");
}

namespace {

bool isEditableTextFile(const QString &suffix)
{
    static const QStringList extensions{
        "tsx", "ts", "jsx", "js", "json", "css", "html",
        "md", "txt", "qml", "cpp", "h"
    };

    return extensions.contains(suffix.toLower());
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

                if (m_devServerOutputTail.contains(devServerAddress)) {
                    m_previewUrl = QUrl(devServerAddress);
                    m_devServerOutputTail.clear();
                    emit previewUrlChanged();
                    return;
                }

                // Keep enough text to recognize the URL across two output chunks.
                m_devServerOutputTail =
                    m_devServerOutputTail.right(devServerAddress.size() - 1);
            });
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
    emit activeProjectChanged();

    emit logMessage("Project folder created: " + projectPath);
    emit projectCreated(name, projectPath);
    return true;
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
    const QFileInfo manifest(directory.filePath("package.json"));

    if (!manifest.isFile()) {
        emit logMessage("Error: Choose the project folder containing package.json.");
        return false;
    }

    m_activeProjectName = directory.dirName();
    m_activeProjectPath = directory.absolutePath();
    emit activeProjectChanged();

    emit logMessage("Project opened: " + m_activeProjectPath);
    return true;
}

void ProjectController::installDependencies()
{
    if (busy()) {
        emit logMessage("A process is already running.");
        return;
    }

    if (m_activeProjectPath.isEmpty()) {
        emit logMessage("Error: Open or generate an npm project first.");
        return;
    }

    const QDir directory(m_activeProjectPath);
    const QFileInfo manifest(directory.filePath("package.json"));

    if (!manifest.isFile()) {
        emit logMessage("Error: No package.json found. Generate React first.");
        return;
    }

    m_processRunner.run("npm", {"install"}, m_activeProjectPath);
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

    const QStringList imageExtensions{
        "png", "jpg", "jpeg", "webp", "gif", "svg", "bmp"
    };

    if (imageExtensions.contains(suffix)) {
        details["kind"] = "image";
        details["imageUrl"] = QUrl::fromLocalFile(filePath);
        return details;
    }

    if (isEditableTextFile(suffix)) {
        const QStringList textExtensions{
            "tsx", "ts", "jsx", "js", "json", "css", "html",
            "md", "txt", "qml", "cpp", "h"
        };

        if (textExtensions.contains(suffix)) {
            QFile file(filePath);

            if (!file.open(QIODevice::ReadOnly)) {
                details["error"] = file.errorString();
                return details;
            }

            constexpr qint64 limit = 64 * 1024;
            const QByteArray content = file.read(limit);

            if (file.error() != QFileDevice::NoError) {
                details["error"] = file.errorString();
                return details;
            }

            details["kind"] = "text";
            details["text"] = QString::fromUtf8(content);
            details["truncated"] = !file.atEnd();
        }
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

    if (bytes.size() > 64 * 1024) {
        return QStringLiteral("The editor supports files up to 64 KiB.");
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
    if (m_activeProjectPath.isEmpty()) {
        return {};
    }

    const QDir project(m_activeProjectPath);

    if (!project.exists()) {
        return {};
    }

    QVariantList results;
    QStringList pendingFolders{project.absolutePath()};

    while (!pendingFolders.isEmpty()) {
        const QDir folder(pendingFolders.takeLast());
        const auto entries = folder.entryInfoList(
            QDir::Dirs | QDir::Files | QDir::NoDotAndDotDot | QDir::NoSymLinks,
            QDir::Name | QDir::IgnoreCase
            );

        for (const QFileInfo &entry : entries) {
            if (entry.isDir()) {
                if (entry.fileName() != "node_modules") {
                    pendingFolders.append(entry.absoluteFilePath());
                }
                continue;
            }

            if (entry.size() > 64 * 1024
                || !isEditableTextFile(entry.suffix())) {
                continue;
            }

            results.append(QVariantMap{
                {"name", entry.fileName()},
                {"path", project.relativeFilePath(entry.absoluteFilePath())},
                {"url", QUrl::fromLocalFile(entry.absoluteFilePath())}
            });
        }
    }

    return results;
}
