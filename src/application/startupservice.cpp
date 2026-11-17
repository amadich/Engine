#include "startupservice.h"
#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QCryptographicHash>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>
#include <QVersionNumber>
#include <QTimer>

StartupService::StartupService(QObject *parent): QObject(parent) {}
void StartupService::setStatus(const QString &s) { m_status=s; emit changed(); }
QString StartupService::currentVersion() const { return QCoreApplication::applicationVersion(); }
QString StartupService::manifestUrl() const { return QSettings().value("updates/manifestUrl").toString(); }
void StartupService::setManifestUrl(const QString &url) { QSettings().setValue("updates/manifestUrl",url.trimmed()); emit changed(); }
QVariantList StartupService::recentProjects() const {
 QVariantList result;
 for (const QString &p: QSettings().value("projects/recent").toStringList())
   if (QFileInfo(p).isDir()) result << QVariantMap{{"path",p},{"name",QFileInfo(p).fileName()}};
 return result;
}
void StartupService::rememberProject(const QUrl &url) {
 QString p = url.toLocalFile(); if(p.isEmpty() || !QFileInfo(p).isDir()) return;
 p=QDir(p).canonicalPath(); auto paths=QSettings().value("projects/recent").toStringList();
 paths.removeAll(p); paths.prepend(p); while(paths.size()>12) paths.removeLast();
 QSettings().setValue("projects/recent",paths); emit changed();
}
void StartupService::forgetProject(const QString &path) { auto p=QSettings().value("projects/recent").toStringList(); p.removeAll(path); QSettings().setValue("projects/recent",p); emit changed(); }
void StartupService::checkUpdates() {
 if(m_checking) return;
 m_progress=8; m_checking=true; m_updateAvailable=false; m_assetUrl.clear(); m_sha256.clear();
 setStatus("Checking for updates…");
 const QUrl url(manifestUrl());
 if(url.isEmpty()) { m_checking=false; m_progress=100; setStatus("Ready · Update source not configured"); return; }
 if(url.scheme()!="https" || !url.isValid()) { m_checking=false; m_progress=100; setStatus("Update URL must use HTTPS"); return; }
 QNetworkRequest request(url); request.setTransferTimeout(12000); request.setRawHeader("Accept","application/json");
 auto *reply=m_network.get(request);
 connect(reply,&QNetworkReply::finished,this,[this,reply]() {
   reply->deleteLater(); m_checking=false; m_progress=100;
   if(reply->error()!=QNetworkReply::NoError) { setStatus("Update check unavailable: "+reply->errorString()); return; }
   if(reply->url().scheme()!="https") { setStatus("Rejected insecure update redirect"); return; }
   QJsonParseError error; auto doc=QJsonDocument::fromJson(reply->readAll(),&error);
   if(error.error!=QJsonParseError::NoError || !doc.isObject()) { setStatus("Invalid update manifest"); return; }
   auto obj=doc.object(); m_latestVersion=obj.value("version").toString();
   const auto remote=QVersionNumber::fromString(m_latestVersion);
   const auto local=QVersionNumber::fromString(currentVersion());
   if(remote.isNull()) { setStatus("Invalid version in manifest"); return; }
   m_updateAvailable=QVersionNumber::compare(remote,local)>0;
   if(m_updateAvailable) {
     const auto platform=
#ifdef Q_OS_MACOS
       QStringLiteral("macos");
#elif defined(Q_OS_WIN)
       QStringLiteral("windows");
#else
       QStringLiteral("linux");
#endif
     auto asset=obj.value("assets").toObject().value(platform).toObject();
     m_assetUrl=asset.value("url").toString(); m_sha256=asset.value("sha256").toString().toLatin1().toLower();
     setStatus("Version "+m_latestVersion+" available");
   } else setStatus("You're up to date · v"+currentVersion());
 });
}
void StartupService::downloadUpdate() {
 if(m_checking || !m_updateAvailable) return;
 const QUrl url(m_assetUrl);
 if(url.scheme()!="https" || m_sha256.size()!=64) { setStatus("Update requires HTTPS download and SHA-256 checksum"); return; }
 m_checking=true; m_progress=0; setStatus("Downloading verified update…");
 QNetworkRequest request(url); request.setTransferTimeout(120000);
 auto *reply=m_network.get(request);
 connect(reply,&QNetworkReply::downloadProgress,this,[this](qint64 done,qint64 total) {
   if(total>0) { m_progress=int(done*100/total); emit changed(); }
 });
 connect(reply,&QNetworkReply::finished,this,[this,reply]() {
   reply->deleteLater(); m_checking=false;
   if(reply->error()!=QNetworkReply::NoError || reply->url().scheme()!="https") { setStatus("Download failed or insecure redirect"); return; }
   QByteArray bytes=reply->readAll();
   if(QCryptographicHash::hash(bytes,QCryptographicHash::Sha256).toHex()!=m_sha256) { setStatus("Update rejected: checksum mismatch"); return; }
   QString dir=QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
   QString suffix=QFileInfo(reply->url().path()).suffix().toLower();
   if(!QStringList{"dmg","zip","pkg","exe","msi","appimage"}.contains(suffix)) { setStatus("Unsupported update package format"); return; }
   QString path=QDir(dir).filePath("JeridiEngine-"+m_latestVersion+"."+suffix);
   QFile file(path); if(!file.open(QIODevice::WriteOnly) || file.write(bytes)!=bytes.size()) { setStatus("Could not save update"); return; }
   file.close(); m_downloadPath=path; m_progress=100; setStatus("Verified update saved · Install it manually");
 });
}
