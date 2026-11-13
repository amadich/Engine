#ifndef PROCESSRUNNER_H
#define PROCESSRUNNER_H

#include <QObject>
#include <QProcess>
#include <QStringList>

class ProcessRunner : public QObject
{
    Q_OBJECT

public:
    explicit ProcessRunner(QObject *parent = nullptr);

    bool running() const;
    void run(const QString &program,
             const QStringList &arguments,
             const QString &workingDirectory = QString());

signals:
    void runningChanged();
    void outputReceived(const QString &text);
    void logMessage(const QString &message);

private:
    QProcess m_process;
};

#endif
