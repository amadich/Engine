#ifndef PROJECTCONTROLLER_H
#define PROJECTCONTROLLER_H

#include "processrunner.h"

#include <QObject>
#include <QString>
#include <QUrl>
#include <QtQml/qqmlregistration.h>
#include <QVariantMap>
#include <QVariantList>

class ProjectController : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QStringList supportedProjectFrameworks READ supportedProjectFrameworks CONSTANT)
    Q_PROPERTY(QString activeProjectName READ activeProjectName NOTIFY activeProjectChanged)
    Q_PROPERTY(QString activeProjectPath READ activeProjectPath NOTIFY activeProjectChanged)
    Q_PROPERTY(QUrl projectFolderUrl READ projectFolderUrl NOTIFY activeProjectChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool devServerActive READ devServerActive NOTIFY busyChanged)
    Q_PROPERTY(QUrl previewUrl READ previewUrl NOTIFY previewUrlChanged)
    Q_PROPERTY(QVariantMap projectProfile READ projectProfile NOTIFY activeProjectChanged)
    Q_PROPERTY(QString projectKind READ projectKind NOTIFY activeProjectChanged)
    Q_PROPERTY(QString projectFramework READ projectFramework NOTIFY activeProjectChanged)
    Q_PROPERTY(QString projectArchitecture READ projectArchitecture NOTIFY activeProjectChanged)
    Q_PROPERTY(QString lastProjectError READ lastProjectError NOTIFY lastProjectErrorChanged)



public:
    explicit ProjectController(QObject *parent = nullptr);

    QStringList supportedProjectFrameworks() const;
    QString activeProjectName() const;
    QString activeProjectPath() const;
    QUrl projectFolderUrl() const;

    bool busy() const;
    bool devServerActive() const;
    QUrl previewUrl() const;
    QVariantMap projectProfile() const { return m_profile; }
    QString projectKind() const { return m_profile.value("kind").toString(); }
    QString projectFramework() const { return m_profile.value("framework").toString(); }
    QString projectArchitecture() const { return m_profile.value("architecture").toString(); }
    QString lastProjectError() const { return m_lastProjectError; }

    Q_INVOKABLE void startDevServer();
    Q_INVOKABLE void stopDevServer();
    Q_INVOKABLE void showComponentPreview(const QString &directory);

    Q_INVOKABLE bool createProject(const QString &projectName,
                                  const QUrl &parentFolder);
    Q_INVOKABLE bool createConfiguredProject(const QVariantMap &options);
    Q_INVOKABLE QString suggestedComponentDirectory(const QString &id) const;

    Q_INVOKABLE bool openProject(const QUrl &folder);
    Q_INVOKABLE bool openProjectPath(const QString &path) {
        return openProject(QUrl::fromLocalFile(path));
    }
    Q_INVOKABLE bool closeProject();
    Q_INVOKABLE bool revealProjectFolder() const;
    Q_INVOKABLE QString localFilePath(const QUrl &url) const { return url.toLocalFile(); }
    Q_INVOKABLE void installDependencies();

    Q_INVOKABLE void checkNpm();
    Q_INVOKABLE void generateReact();

    Q_INVOKABLE QVariantMap inspectFile(const QUrl &fileUrl) const;

    Q_INVOKABLE QString saveTextFile(const QUrl &fileUrl,
                                     const QString &originalText,
                                     const QString &newText);
    Q_INVOKABLE QVariantList quickOpenFiles() const;
    // Safe, project-scoped local import resolution (not a language server).
    Q_INVOKABLE QVariantMap resolveImport(const QUrl &sourceFile,
                                          const QString &specifier) const;
    Q_INVOKABLE QStringList suggestImportPaths(const QUrl &sourceFile,
                                               const QString &prefix) const;

signals:
    void activeProjectChanged();
    void busyChanged();
    void logMessage(const QString &message);
    void outputReceived(const QString &text);
    void projectCreated(const QString &projectName, const QString &projectPath);
    void previewUrlChanged();
    void packagePreviewRequested();
    void lastProjectErrorChanged();

private:
    QString m_activeProjectName;
    QString m_activeProjectPath;
    ProcessRunner m_processRunner;
    bool m_devServerRequested = false;
    QUrl m_previewUrl;
    QString m_devServerOutputTail;
    QVariantMap m_profile;
    QString m_lastProjectError;
};

#endif
