#include "projectcontroller.h"

#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSaveFile>
#include <QFile>

namespace {
const QString devServerAddress = QStringLiteral("http://127.0.0.1:5173/");
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





void ProjectController::addButtonComponent()
{
    if (m_activeProjectPath.isEmpty()) {
        emit logMessage("Error: Open a React project first.");
        return;
    }

    if (busy() && !devServerActive()) {
        emit logMessage("Error: Wait for the current command to finish.");
        return;
    }

    const QDir projectDirectory(m_activeProjectPath);

    if (!QFileInfo(projectDirectory.filePath("src/App.tsx")).isFile()) {
        emit logMessage("Error: This action expects a React TypeScript project.");
        return;
    }

    if (!projectDirectory.mkpath("src/components")) {
        emit logMessage("Error: Could not create src/components.");
        return;
    }

    const QString relativePath = QStringLiteral("src/components/EngineButton.tsx");
    const QString filePath = projectDirectory.absoluteFilePath(relativePath);
    const QFileInfo existingFile(filePath);

    if (existingFile.exists() || existingFile.isSymLink()) {
        emit logMessage("Component already exists: " + relativePath);
        return;
    }

    const QString templatePath =
        QStringLiteral(":/templates/react/engine-button/EngineButton.tsx");

    QFile templateFile(templatePath);

    if (!templateFile.open(QIODevice::ReadOnly)) {
        emit logMessage("Error: Could not open template: " + templatePath
                        + " (" + templateFile.errorString() + ")");
        return;
    }

    const QByteArray source = templateFile.readAll();

    if (templateFile.error() != QFileDevice::NoError || source.isEmpty()) {
        emit logMessage("Error: Could not read component template: " + templatePath);
        return;
    }

    QSaveFile file(filePath);

    if (!file.open(QIODevice::WriteOnly)
        || file.write(source) != source.size()
        || !file.commit()) {
        emit logMessage("Error: Could not save component: " + file.errorString());
        return;
    }

    emit logMessage("Component created: " + relativePath);
}