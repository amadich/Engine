#include "componentmanager.h"

#include "componentinstaller.h"
#include "componentregistry.h"
#include "projectcontroller.h"

#include <QDir>

ComponentManager::ComponentManager(QObject *parent) : QObject(parent) {}

ProjectController *ComponentManager::projectController() const
{
    return m_projectController;
}

void ComponentManager::setProjectController(ProjectController *controller)
{
    if (m_projectController == controller)
        return;
    m_projectController = controller;
    emit projectControllerChanged();
}

QString ComponentManager::installComponent(const QString &id)
{
    const QVariantMap definition = ComponentRegistry::instance().component(id);
    if (definition.isEmpty())
        return QStringLiteral("Unknown component: ") + id;
    if (!m_projectController || m_projectController->activeProjectPath().isEmpty())
        return QStringLiteral("Open a React project first.");
    if (m_projectController->busy() && !m_projectController->devServerActive())
        return QStringLiteral("Wait for the current command to finish.");

    const QString error = ComponentInstaller::install(
        m_projectController->activeProjectPath(), id, definition);
    if (error.isEmpty()) {
        emit logMessage(QStringLiteral("Component ready: %1").arg(definition.value("name").toString()));
        emit componentInstalled(id);
    }
    return error;
}

bool ComponentManager::isInstalled(const QString &id) const
{
    if (!m_projectController)
        return false;
    const QVariantMap definition = ComponentRegistry::instance().component(id);
    return !definition.isEmpty() && ComponentInstaller::isInstalled(
        m_projectController->activeProjectPath(), definition);
}

QUrl ComponentManager::configurationUrl(const QString &id) const
{
    if (!m_projectController || m_projectController->activeProjectPath().isEmpty())
        return {};
    const QString path = ComponentRegistry::instance().component(id)
                             .value("configTarget").toString();
    if (!ComponentInstaller::validTarget(path))
        return {};
    return QUrl::fromLocalFile(QDir(m_projectController->activeProjectPath()).filePath(path));
}
