#ifndef COMPONENTMANAGER_H
#define COMPONENTMANAGER_H

#include <QObject>
#include <QUrl>
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

    Q_INVOKABLE QString installComponent(const QString &id);
    Q_INVOKABLE bool isInstalled(const QString &id) const;
    Q_INVOKABLE QUrl configurationUrl(const QString &id) const;

signals:
    void projectControllerChanged();
    void componentInstalled(const QString &id);
    void logMessage(const QString &message);

private:
    ProjectController *m_projectController = nullptr;
};

#endif
