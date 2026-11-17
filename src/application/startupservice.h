#pragma once
#include <QObject>
#include <QtQmlIntegration/qqmlintegration.h>
#include <QSettings>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QUrl>
#include <QVariantList>
#include <QFile>

class StartupService : public QObject {
 Q_OBJECT
 QML_ELEMENT
 Q_PROPERTY(QString status READ status NOTIFY changed)
 Q_PROPERTY(int progress READ progress NOTIFY changed)
 Q_PROPERTY(bool checking READ checking NOTIFY changed)
 Q_PROPERTY(bool updateAvailable READ updateAvailable NOTIFY changed)
 Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY changed)
 Q_PROPERTY(QVariantList recentProjects READ recentProjects NOTIFY changed)
 Q_PROPERTY(QString downloadPath READ downloadPath NOTIFY changed)
public:
 explicit StartupService(QObject *parent=nullptr);
 QString status() const { return m_status; }
 int progress() const { return m_progress; }
 bool checking() const { return m_checking; }
 bool updateAvailable() const { return m_updateAvailable; }
 QString latestVersion() const { return m_latestVersion; }
 QVariantList recentProjects() const;
 QString downloadPath() const { return m_downloadPath; }
 Q_INVOKABLE void checkUpdates();
 Q_INVOKABLE void downloadUpdate();
 Q_INVOKABLE void rememberProject(const QUrl &url);
 Q_INVOKABLE void forgetProject(const QString &path);
 Q_INVOKABLE QString manifestUrl() const;
 Q_INVOKABLE void setManifestUrl(const QString &url);
 Q_INVOKABLE QString currentVersion() const;
signals:
 void changed();
private:
 void setStatus(const QString &status);
 QNetworkAccessManager m_network;
 QString m_status = "Preparing workspace…";
 QString m_latestVersion;
 QString m_downloadPath;
 QString m_assetUrl;
 QByteArray m_sha256;
 int m_progress = 0;
 bool m_checking = false;
 bool m_updateAvailable = false;
};
