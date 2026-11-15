#ifndef PROJECTCONTROLLER_H
#define PROJECTCONTROLLER_H

#include "processrunner.h"

#include <QObject>
#include <QString>
#include <QUrl>
#include <QtQml/qqmlregistration.h>
#include <QVariantMap>

class ProjectController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString activeProjectName READ activeProjectName NOTIFY activeProjectChanged)
    Q_PROPERTY(QString activeProjectPath READ activeProjectPath NOTIFY activeProjectChanged)
    Q_PROPERTY(QUrl projectFolderUrl READ projectFolderUrl NOTIFY activeProjectChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool devServerActive READ devServerActive NOTIFY busyChanged)
    Q_PROPERTY(QUrl previewUrl READ previewUrl NOTIFY previewUrlChanged)



public:
    explicit ProjectController(QObject *parent = nullptr);

    QString activeProjectName() const;
    QString activeProjectPath() const;
    QUrl projectFolderUrl() const;

    bool busy() const;
    bool devServerActive() const;
    QUrl previewUrl() const;

    Q_INVOKABLE void startDevServer();
    Q_INVOKABLE void stopDevServer();

    Q_INVOKABLE bool createProject(const QString &projectName,
                                  const QUrl &parentFolder);

    Q_INVOKABLE bool openProject(const QUrl &folder);
    Q_INVOKABLE void installDependencies();

    Q_INVOKABLE void checkNpm();
    Q_INVOKABLE void generateReact();

    Q_INVOKABLE void addButtonComponent();
    Q_INVOKABLE QVariantMap inspectFile(const QUrl &fileUrl) const;

    Q_INVOKABLE QString saveTextFile(const QUrl &fileUrl,
                                     const QString &originalText,
                                     const QString &newText);

signals:
    void activeProjectChanged();
    void busyChanged();
    void logMessage(const QString &message);
    void outputReceived(const QString &text);
    void projectCreated(const QString &projectName, const QString &projectPath);
    void previewUrlChanged();

private:
    QString m_activeProjectName;
    QString m_activeProjectPath;
    ProcessRunner m_processRunner;
    bool m_devServerRequested = false;
    QUrl m_previewUrl;
    QString m_devServerOutputTail;
};

#endif
