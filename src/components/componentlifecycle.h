#ifndef COMPONENTLIFECYCLE_H
#define COMPONENTLIFECYCLE_H

#include <QString>
#include <QVariantMap>

// All components use the same project-local move/remove implementation.
// No Qt/QML registration: ComponentManager is the public facade.
class ComponentLifecycle
{
public:
    static QVariantMap previewMove(const QString &projectPath, const QString &id,
                                   const QVariantMap &definition, const QString &fromDirectory,
                                   const QString &toDirectory);
    static QString move(const QString &projectPath, const QString &id,
                        const QVariantMap &definition, const QString &fromDirectory,
                        const QString &toDirectory, QString *cleanupNote = nullptr);
    static QVariantMap previewRemove(const QString &projectPath, const QString &id,
                                     const QVariantMap &definition, const QString &fromDirectory);
    static QString remove(const QString &projectPath, const QString &id,
                          const QVariantMap &definition, const QString &fromDirectory,
                          QString *trashDirectory, QString *cleanupNote = nullptr);
};

#endif
