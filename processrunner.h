#ifndef PROCESSRUNNER_H
#define PROCESSRUNNER_H

#include <QObject>
#include <QProcess>
#include <QStringList>
#include <QtQml/qqmlregistration.h>

class ProcessRunner : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool running READ running NOTIFY runningChanged)

public:
    explicit ProcessRunner(QObject *parent = nullptr);

    bool running() const;

    Q_INVOKABLE void run(
        const QString &program,
        const QStringList &arguments,
        const QString &workingDirectory = QString()
        );

    Q_INVOKABLE void createReactProject(
        const QString &projectPath
        );

signals:
    void runningChanged();
    void outputReceived(const QString &text);
    void logMessage(const QString &message);

private:
    QProcess m_process;
};

#endif