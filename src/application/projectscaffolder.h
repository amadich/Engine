#pragma once

#include <QString>
#include <QStringList>
#include <QUrl>
#include <QVariantMap>

// Creates a project only in a new, empty directory. No network calls.
class ProjectScaffolder
{
public:
    struct Result {
        QString projectPath;
        QString error;
        QString kind;
        QString framework;
        QString architecture;
        QString packageName;
        QStringList dependencies;
        bool gitInitialized = false;
        bool success() const { return error.isEmpty(); }
    };

    static QStringList supportedFrameworks();
    static Result create(const QVariantMap &options);
    static QVariantMap detect(const QString &projectPath);
    static bool compatible(const QString &projectPath, const QVariantMap &definition);
    static QString suggestedDirectory(const QString &projectPath,
                                      const QVariantMap &definition);
};
