#include "processrunner.h"

#include <QDir>
#include <QProcessEnvironment>
#include <QStandardPaths>

ProcessRunner::ProcessRunner(QObject *parent)
    : QObject(parent)
{
    m_process.setProcessChannelMode(QProcess::MergedChannels);

    connect(&m_process, &QProcess::readyReadStandardOutput, this, [this]() {
        emit outputReceived(QString::fromUtf8(m_process.readAllStandardOutput()));
    });

    connect(&m_process, &QProcess::stateChanged,
            this, [this](QProcess::ProcessState) {
        emit runningChanged();
    });

    connect(&m_process, &QProcess::errorOccurred,
            this, [this](QProcess::ProcessError) {
        emit logMessage("Process error: " + m_process.errorString());
    });

    connect(&m_process, &QProcess::finished, this,
            [this](int exitCode, QProcess::ExitStatus exitStatus) {
        const QByteArray remaining = m_process.readAllStandardOutput();

        if (!remaining.isEmpty()) {
            emit outputReceived(QString::fromUtf8(remaining));
        }

        if (exitStatus == QProcess::CrashExit) {
            emit logMessage("Process crashed.");
            return;
        }

        emit logMessage(
            QString("Process finished with exit code %1.").arg(exitCode)
        );
    });
}

bool ProcessRunner::running() const
{
    return m_process.state() != QProcess::NotRunning;
}

void ProcessRunner::run(const QString &program,
                        const QStringList &arguments,
                        const QString &workingDirectory)
{
    if (running()) {
        emit logMessage("A process is already running.");
        return;
    }

    if (!workingDirectory.isEmpty()) {
        const QDir directory(workingDirectory);

        if (!directory.isAbsolute() || !directory.exists()) {
            emit logMessage("Error: Invalid working directory.");
            return;
        }
    }

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    QStringList searchPaths = environment.value("PATH").split(
        QDir::listSeparator(), Qt::SkipEmptyParts
    );

#ifdef Q_OS_MACOS
    // Current Node installation on Mohamed's Mac.
    searchPaths.prepend("/opt/homebrew/opt/node@24/bin");
    searchPaths.append("/opt/homebrew/bin");
    searchPaths.append("/usr/local/bin");
#endif

    searchPaths.removeDuplicates();
    environment.insert("PATH", searchPaths.join(QDir::listSeparator()));

    const QString executable = QStandardPaths::findExecutable(program, searchPaths);

    if (executable.isEmpty()) {
        emit logMessage(
            "Program not found: " + program
            + "\nCheck the executable location and the application's PATH."
        );
        return;
    }

    m_process.setProcessEnvironment(environment);
    m_process.setWorkingDirectory(workingDirectory);

    emit logMessage("Starting: " + executable);
    emit logMessage("Arguments: " + arguments.join(" "));

    if (!workingDirectory.isEmpty()) {
        emit logMessage("Working directory: " + workingDirectory);
    }

    m_process.start(executable, arguments);
}
