#include "projectcontroller.h"

#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>

ProjectController::ProjectController(QObject *parent)
    : QObject(parent)
{
}

bool ProjectController::createProject(
    const QString &projectName,
    const QUrl &parentFolder
    )
{
    const QString name = projectName.trimmed();

    // تسمية أولية مناسبة للمشاريع التي سننشئها لاحقًا.
    static const QRegularExpression namePattern(
        "^[a-z][a-z0-9_-]{0,63}$"
        );

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
        emit logMessage(
            "Error: A file or folder already exists at " + projectPath
            );
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

    emit logMessage("Project folder created: " + projectPath);
    emit projectCreated(name, projectPath);

    return true;
}