#ifndef COMPONENTINSTALLER_H
#define COMPONENTINSTALLER_H

#include <QString>
#include <QVariantMap>
#include <QStringList>

// File installation is separate from both the UI and project lifecycle.
class ComponentInstaller
{
public:
    static QVariantMap previewInstall(const QString &projectPath, const QString &id,
                                      const QVariantMap &definition,
                                      const QString &relativeDirectory);
    static QString install(const QString &projectPath, const QString &id,
                           const QVariantMap &definition, const QString &relativeDirectory,
                           const QString &draftConfiguration, QStringList *createdFiles);
    static bool isInstalled(const QString &projectPath, const QVariantMap &definition,
                            const QString &relativeDirectory);
    static bool validTarget(const QString &relativePath);
    static bool validDirectory(const QString &relativeDirectory);
    static QString combinedPath(const QString &directory, const QString &target);
};

#endif
