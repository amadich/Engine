#ifndef PROJECTCONTROLLER_H
#define PROJECTCONTROLLER_H

#include <QObject>
#include <QString>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

class ProjectController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit ProjectController(QObject *parent = nullptr);

    Q_INVOKABLE bool createProject(
        const QString &projectName,
        const QUrl &parentFolder
        );

signals:
    void logMessage(const QString &message);

    void projectCreated(
        const QString &projectName,
        const QString &projectPath
        );
};

#endif