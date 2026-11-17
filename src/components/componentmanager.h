#ifndef COMPONENTMANAGER_H
#define COMPONENTMANAGER_H

#include <QObject>
#include <QUrl>
#include <QHash>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>
#include "projectcontroller.h"

// One generic API for all component packages; no per-component methods.
class ComponentManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(ProjectController *projectController READ projectController
                   WRITE setProjectController NOTIFY projectControllerChanged)

public:
    explicit ComponentManager(QObject *parent = nullptr);

    ProjectController *projectController() const;
    void setProjectController(ProjectController *controller);

    Q_INVOKABLE void requestInstall(const QString &id);
    Q_INVOKABLE void requestMove(const QString &id);
    Q_INVOKABLE void requestRemove(const QString &id);
    Q_INVOKABLE QVariantMap previewInstall(const QString &id,
                                           const QString &relativeDirectory) const;
    Q_INVOKABLE QString repairMissingInstallation(const QString &id);
    Q_INVOKABLE QVariantMap previewMove(const QString &id, const QString &relativeDirectory) const;
    Q_INVOKABLE QString moveComponentInDirectory(const QString &id, const QString &relativeDirectory);
    Q_INVOKABLE QVariantMap previewRemove(const QString &id) const;
    Q_INVOKABLE QString removeComponent(const QString &id);
    Q_INVOKABLE QString installComponent(const QString &id, const QUrl &destinationFolder);
    Q_INVOKABLE QString installComponentInDirectory(const QString &id,
                                                     const QString &relativeDirectory);
    Q_INVOKABLE QString relativeFolder(const QUrl &destinationFolder) const;
    Q_INVOKABLE bool isInstalled(const QString &id) const;
    Q_INVOKABLE QString installedDirectory(const QString &id) const;
    Q_INVOKABLE QUrl configurationUrl(const QString &id) const;
    Q_INVOKABLE QString draftConfiguration(const QString &id) const;
    Q_INVOKABLE QString setDraftConfiguration(const QString &id, const QString &jsonText);

signals:
    void projectControllerChanged();
    void componentInstalled(const QString &id);
    void componentMoved(const QString &id);
    void componentRemoved(const QString &id);
    void installRequested(const QString &id);
    void moveRequested(const QString &id);
    void removeRequested(const QString &id);
    void logMessage(const QString &message);

private:
    ProjectController *m_projectController = nullptr;
    QHash<QString, QString> m_drafts;
};

#endif
