#include "projectfoldermodel.h"

#include <QDir>
#include <QFileInfo>
#include <QQueue>

namespace {
bool ignored(const QString &name)
{
    static const QSet<QString> names = {
        ".git", ".jeridiengine", "node_modules", ".next", ".nuxt",
        ".vite", ".svelte-kit", "dist", "build", "coverage", "target"
    };
    return names.contains(name);
}

bool safeRelativeFolder(const QString &path)
{
    if (path == ".")
        return true;
    if (path.isEmpty() || path.startsWith('/') || path.contains('\\'))
        return false;
    for (const QString &part : path.split('/')) {
        if (part.isEmpty() || part == "." || part == "..")
            return false;
    }
    return true;
}
}

ProjectFolderModel::ProjectFolderModel(QObject *parent) : QAbstractListModel(parent)
{
    m_expanded.insert(".");
}

QUrl ProjectFolderModel::projectFolder() const { return m_projectFolder; }

void ProjectFolderModel::setProjectFolder(const QUrl &folder)
{
    if (m_projectFolder == folder)
        return;
    m_projectFolder = folder;
    m_root = folder.isLocalFile() ? QDir(folder.toLocalFile()).canonicalPath() : QString();
    m_expanded.clear();
    m_expanded.insert(".");
    m_expanded.insert("src");
    rebuild();
    emit projectFolderChanged();
}

QString ProjectFolderModel::searchText() const { return m_search; }

void ProjectFolderModel::setSearchText(const QString &query)
{
    const QString normalized = query.trimmed();
    if (m_search == normalized)
        return;
    m_search = normalized;
    rebuild();
    emit searchTextChanged();
}

bool ProjectFolderModel::searchLimited() const { return m_searchLimited; }

int ProjectFolderModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_entries.size();
}

QVariant ProjectFolderModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size())
        return {};
    const Entry &item = m_entries.at(index.row());
    switch (role) {
    case NameRole: return item.name;
    case PathRole: return item.path;
    case LevelRole: return item.level;
    case ExpandedRole: return item.expanded;
    case ExpandableRole: return item.expandable;
    case SearchResultRole: return item.searchResult;
    default: return {};
    }
}

QHash<int, QByteArray> ProjectFolderModel::roleNames() const
{
    return {{NameRole, "folderName"}, {PathRole, "folderPath"},
            {LevelRole, "folderLevel"}, {ExpandedRole, "folderExpanded"},
            {ExpandableRole, "folderExpandable"}, {SearchResultRole, "searchResult"}};
}

QStringList ProjectFolderModel::subfolders(const QString &relativePath) const
{
    if (m_root.isEmpty() || !safeRelativeFolder(relativePath))
        return {};
    const QDir folder(QDir(m_root).filePath(relativePath));
    QStringList result;
    for (const QFileInfo &info : folder.entryInfoList(
            QDir::Dirs | QDir::Hidden | QDir::NoSymLinks | QDir::NoDotAndDotDot,
            QDir::Name | QDir::IgnoreCase)) {
        if (info.isDir() && !info.isSymLink() && !ignored(info.fileName()))
            result.append(info.fileName());
    }
    return result;
}

void ProjectFolderModel::appendExpanded(const QString &path, int level)
{
    if (m_entries.size() >= 3000)
        return;
    const bool root = path == ".";
    const QString name = root ? QFileInfo(m_root).fileName()
                              : path.section('/', -1);
    const bool expanded = m_expanded.contains(path);
    const QStringList children = subfolders(path);
    m_entries.append({root ? QStringLiteral("Project root") : name,
                      path, level, expanded, !children.isEmpty(), false});
    if (!expanded)
        return;
    for (const QString &child : children) {
        if (m_entries.size() >= 3000) {
            m_searchLimited = true;
            return;
        }
        const QString childPath = root ? child : path + "/" + child;
        appendExpanded(childPath, level + 1);
    }
}

void ProjectFolderModel::rebuild()
{
    beginResetModel();
    m_entries.clear();
    m_searchLimited = false;
    if (!m_root.isEmpty() && QFileInfo(m_root).isDir()) {
        if (m_search.isEmpty()) {
            appendExpanded(".", 0);
        } else {
            QQueue<QString> queue;
            queue.enqueue(".");
            int visited = 0;
            while (!queue.isEmpty()) {
                if (++visited > 5000 || queue.size() > 5000 || m_entries.size() >= 350) {
                    m_searchLimited = true;
                    break;
                }
                const QString path = queue.dequeue();
                if (path.contains(m_search, Qt::CaseInsensitive)) {
                    m_entries.append({path == "." ? QStringLiteral("Project root") : path,
                                      path, 0, false, false, true});
                }
                for (const QString &child : subfolders(path))
                    queue.enqueue(path == "." ? child : path + "/" + child);
            }
        }
    }
    endResetModel();
    emit modelChanged();
}

void ProjectFolderModel::toggleExpanded(const QString &relativePath)
{
    if (!m_search.isEmpty() || !safeRelativeFolder(relativePath))
        return;
    if (m_expanded.contains(relativePath))
        m_expanded.remove(relativePath);
    else
        m_expanded.insert(relativePath);
    rebuild();
}
