#include "projectcontroller.h"

#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>

ProjectController::ProjectController(QObject *parent)
    : QObject(parent)
{
    connect(&m_processRunner, &ProcessRunner::runningChanged,
            this, [this]() {
                if (!busy()) {
                    m_devServerRequested = false;
                }

                emit busyChanged();
            });
    connect(&m_processRunner, &ProcessRunner::logMessage,
            this, &ProjectController::logMessage);
    connect(&m_processRunner, &ProcessRunner::outputReceived,
            this, &ProjectController::outputReceived);
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