#ifndef COMPONENTINSTALLER_H
#define COMPONENTINSTALLER_H

#include <QString>
#include <QVariantMap>

// File installation is separate from both the UI and project lifecycle.
class ComponentInstaller
{
public:
    static QString install(const QString &projectPath, const QString &id,
                           const QVariantMap &definition);
    static bool isInstalled(const QString &projectPath, const QVariantMap &definition);
    static bool validTarget(const QString &relativePath);
};

#endif
