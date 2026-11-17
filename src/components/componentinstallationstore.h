#ifndef COMPONENTINSTALLATIONSTORE_H
#define COMPONENTINSTALLATIONSTORE_H

#include <QJsonObject>
#include <QString>
#include <QVariantMap>

// Project-local installation index. Never stores absolute machine paths.
class ComponentInstallationStore
{
public:
    static QString load(const QString &projectPath, QJsonObject *document);
    static QVariantMap find(const QString &projectPath, const QString &componentId);
    static QString record(const QString &projectPath, const QString &componentId,
                          const QString &relativeDirectory, const QVariantMap &definition);
    static QString relocate(const QString &projectPath, const QString &componentId,
                            const QString &relativeDirectory, const QVariantMap &definition);
    static QString unregister(const QString &projectPath, const QString &componentId);
};

#endif
