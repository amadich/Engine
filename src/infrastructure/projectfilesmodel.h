#ifndef PROJECTFILESMODEL_H
#define PROJECTFILESMODEL_H

#include <QClipboard>
#include <QDateTime>
#include <QDir>
#include <QElapsedTimer>
#include <QFileInfo>
#include <QFileSystemModel>
#include <QGuiApplication>
#include <QSortFilterProxyModel>
#include <QStringList>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

// Read-only filesystem explorer model. No project files are modified here.
// QFileSystemModel provides lazy tree browsing; a bounded directory scan provides
// filename/path search without relying on which tree branches are expanded.
class ProjectFilesModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool showHidden READ showHidden WRITE setShowHidden NOTIFY showHiddenChanged)
    Q_PROPERTY(QString typeFilter READ typeFilter WRITE setTypeFilter NOTIFY typeFilterChanged)

public:
    explicit ProjectFilesModel(QObject *parent = nullptr)
        : QSortFilterProxyModel(parent)
    {
        m_files.setFilter(baseFilters());
        m_files.setReadOnly(true);
        m_files.setOption(QFileSystemModel::DontUseCustomDirectoryIcons);
        setSourceModel(&m_files);
        setDynamicSortFilter(true);
    }

    bool showHidden() const { return m_showHidden; }
    void setShowHidden(bool value)
    {
        if (m_showHidden == value)
            return;
        m_showHidden = value;
        m_files.setFilter(baseFilters());
        invalidateFilter();
        emit showHiddenChanged();
    }

    QString typeFilter() const { return m_typeFilter; }
    void setTypeFilter(const QString &value)
    {
        const QString normalized = (value == QStringLiteral("code")
                                     || value == QStringLiteral("media"))
                                       ? value : QStringLiteral("all");
        if (m_typeFilter == normalized)
            return;
        m_typeFilter = normalized;
        invalidateFilter();
        emit typeFilterChanged();
    }

    Q_INVOKABLE QModelIndex openFolder(const QUrl &folder)
    {
        if (!folder.isLocalFile() || !QDir(folder.toLocalFile()).exists()) {
            m_rootPath.clear();
            return {};
        }
        m_rootPath = QDir(folder.toLocalFile()).canonicalPath();
        return mapFromSource(m_files.setRootPath(m_rootPath));
    }

    Q_INVOKABLE QUrl fileUrl(const QModelIndex &index) const
    {
        const QModelIndex sourceIndex = mapToSource(index);
        return sourceIndex.isValid()
                   ? QUrl::fromLocalFile(m_files.filePath(sourceIndex)) : QUrl{};
    }

    Q_INVOKABLE bool isFolder(const QModelIndex &index) const
    {
        const QModelIndex sourceIndex = mapToSource(index);
        return sourceIndex.isValid() && m_files.isDir(sourceIndex);
    }

    Q_INVOKABLE QVariantMap fileDetails(const QModelIndex &index) const
    {
        const QModelIndex sourceIndex = mapToSource(index);
        if (!sourceIndex.isValid())
            return {};
        return detailsForPath(m_files.filePath(sourceIndex));
    }

    Q_INVOKABLE QVariantMap detailsForUrl(const QUrl &url) const
    {
        if (!url.isLocalFile())
            return {};
        return detailsForPath(url.toLocalFile());
    }

    Q_INVOKABLE QString relativePath(const QUrl &url) const
    {
        return detailsForUrl(url).value(QStringLiteral("relativePath")).toString();
    }

    Q_INVOKABLE QUrl urlForRelativePath(const QString &relative) const
    {
        if (m_rootPath.isEmpty() || relative.isEmpty() || QDir::isAbsolutePath(relative))
            return {};
        const QString path = QDir(m_rootPath).filePath(relative);
        return detailsForPath(path).isEmpty() ? QUrl{} : QUrl::fromLocalFile(path);
    }

    // Search is deliberately bounded for UI responsiveness. A "limited" result
    // means the user should narrow the query; it is never presented as exhaustive.
    Q_INVOKABLE QVariantMap searchFiles(const QString &query,
                                        const QString &filter = QStringLiteral("all"),
                                        int maxResults = 120) const
    {
        QVariantList results;
        int scanned = 0;
        bool limited = false;
        const QString needle = query.trimmed();
        if (m_rootPath.isEmpty() || needle.isEmpty())
            return {{"results", results}, {"scanned", scanned}, {"limited", limited}};

        const int limit = qBound(1, maxResults, 250);
        constexpr int maxScanned = 6500;
        constexpr qint64 maxMilliseconds = 75;
        QElapsedTimer timer;
        timer.start();
        QStringList pending{m_rootPath};

        while (!pending.isEmpty()) {
            if (scanned >= maxScanned || timer.elapsed() >= maxMilliseconds) {
                limited = true;
                break;
            }
            const QDir directory(pending.takeLast());
            const QFileInfoList entries = directory.entryInfoList(
                baseFilters(), QDir::DirsFirst | QDir::Name | QDir::IgnoreCase);

            for (const QFileInfo &info : entries) {
                if (scanned >= maxScanned || timer.elapsed() >= maxMilliseconds) {
                    limited = true;
                    break;
                }
                ++scanned;
                if (info.isSymLink() || info.isSymbolicLink())
                    continue;
                if (info.isDir()) {
                    if (isExcludedDirectory(info.fileName()))
                        continue;
                    pending.append(info.absoluteFilePath());
                }

                const QString relative = QDir(m_rootPath).relativeFilePath(info.absoluteFilePath());
                if (!relative.contains(needle, Qt::CaseInsensitive)
                    || !matchesType(info, filter))
                    continue;
                const QVariantMap details = detailsForPath(info.absoluteFilePath());
                if (!details.isEmpty())
                    results.append(details);
                if (results.size() >= limit) {
                    limited = true;
                    break;
                }
            }
            if (limited)
                break;
        }
        return {{"results", results}, {"scanned", scanned}, {"limited", limited}};
    }

    Q_INVOKABLE void copyText(const QString &text) const
    {
        if (!text.isEmpty() && QGuiApplication::clipboard())
            QGuiApplication::clipboard()->setText(text);
    }

signals:
    void showHiddenChanged();
    void typeFilterChanged();

protected:
    bool filterAcceptsRow(int row, const QModelIndex &parent) const override
    {
        const QModelIndex index = m_files.index(row, 0, parent);
        if (!index.isValid())
            return false;
        const QFileInfo info = m_files.fileInfo(index);
        if (info.isDir())
            return !isExcludedDirectory(info.fileName());
        return matchesType(info, m_typeFilter);
    }

private:
    QDir::Filters baseFilters() const
    {
        QDir::Filters flags = QDir::AllDirs | QDir::Files
                              | QDir::NoDotAndDotDot | QDir::NoSymLinks;
        if (m_showHidden)
            flags |= QDir::Hidden;
        return flags;
    }

    static bool isExcludedDirectory(const QString &name)
    {
        // Match the previous panel's node_modules exclusion; additionally avoid
        // traversing Git internals, which are never project source files.
        return name == QStringLiteral("node_modules") || name == QStringLiteral(".git");
    }

    static bool matchesType(const QFileInfo &info, const QString &filter)
    {
        if (filter != QStringLiteral("code") && filter != QStringLiteral("media"))
            return true;
        if (info.isDir())
            return false;
        const QString ext = info.suffix().toLower();
        static const QStringList codeExtensions{
            "c", "cc", "cpp", "cxx", "h", "hpp", "hxx", "qml", "js", "jsx",
            "ts", "tsx", "css", "scss", "html", "py", "go", "rs", "java",
            "swift", "kt", "vue", "svelte", "sh", "sql", "json", "yaml",
            "yml", "toml", "xml", "cmake"
        };
        static const QStringList mediaExtensions{
            "png", "jpg", "jpeg", "webp", "gif", "svg", "bmp", "ico",
            "avif", "mp4", "mov", "webm", "mp3", "wav", "ogg", "pdf"
        };
        return (filter == QStringLiteral("code") ? codeExtensions : mediaExtensions)
            .contains(ext);
    }

    QVariantMap detailsForPath(const QString &path) const
    {
        if (m_rootPath.isEmpty())
            return {};
        const QFileInfo info(path);
        if (!info.exists() || info.isSymLink() || info.isSymbolicLink())
            return {};
        const QString canonical = info.canonicalFilePath();
        const QString relative = QDir(m_rootPath).relativeFilePath(canonical);
        if (canonical.isEmpty() || relative == QStringLiteral("..")
            || relative.startsWith(QStringLiteral("../"))
            || QDir::isAbsolutePath(relative))
            return {};
        return {
            {"name", info.fileName()},
            {"relativePath", relative},
            {"absolutePath", canonical},
            {"url", QUrl::fromLocalFile(canonical)},
            {"extension", info.suffix().toLower()},
            {"folder", info.isDir()},
            {"size", static_cast<qlonglong>(info.isDir() ? 0 : info.size())},
            {"modified", info.lastModified().toString(QStringLiteral("yyyy-MM-dd hh:mm"))},
            {"exists", true}
        };
    }

    QFileSystemModel m_files;
    QString m_rootPath;
    QString m_typeFilter = QStringLiteral("all");
    bool m_showHidden = false;
};

#endif
