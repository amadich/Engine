#ifndef PROJECTCONTROLLER_H
#define PROJECTCONTROLLER_H

#include "processrunner.h"

#include <QObject>
#include <QString>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

class ProjectController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString activeProjectName READ activeProjectName NOTIFY activeProjectChanged)
    Q_PROPERTY(QString activeProjectPath READ activeProjectPath NOTIFY activeProjectChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

public:
    explicit ProjectController(QObject *parent = nullptr);

    QString activeProjectName() const;
    QString activeProjectPath() const;
    bool busy() const;

    Q_INVOKABLE bool createProject(const QString &projectName,
                                  const QUrl &parentFolder);
    Q_INVOKABLE void checkNpm();
    Q_INVOKABLE void generateReact();

signals:
    void activeProjectChanged();
    void busyChanged();
    void logMessage(const QString &message);
    void outputReceived(const QString &text);
    void projectCreated(const QString &projectName, const QString &projectPath);

private:
    QString m_activeProjectName;
    QString m_activeProjectPath;
    ProcessRunner m_processRunner;
};

#endif
