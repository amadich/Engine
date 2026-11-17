#ifndef PROJECTFOLDERMODEL_H
#define PROJECTFOLDERMODEL_H

#include <QAbstractListModel>
#include <QSet>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

// Read-only, project-scoped folder browser. The flattened rows represent a
// proper expandable tree; search traverses folders without touching files.
class ProjectFolderModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QUrl projectFolder READ projectFolder WRITE setProjectFolder
               NOTIFY projectFolderChanged)
    Q_PROPERTY(QString searchText READ searchText WRITE setSearchText
               NOTIFY searchTextChanged)
    Q_PROPERTY(bool searchLimited READ searchLimited NOTIFY modelChanged)

public:
    enum Roles { NameRole = Qt::UserRole + 1, PathRole, LevelRole,
                 ExpandedRole, ExpandableRole, SearchResultRole };
    explicit ProjectFolderModel(QObject *parent = nullptr);

    QUrl projectFolder() const;
    void setProjectFolder(const QUrl &folder);
    QString searchText() const;
    void setSearchText(const QString &query);
    bool searchLimited() const;

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    Q_INVOKABLE void toggleExpanded(const QString &relativePath);

signals:
    void projectFolderChanged();
    void searchTextChanged();
    void modelChanged();

private:
    struct Entry {
        QString name;
        QString path;
        int level = 0;
        bool expanded = false;
        bool expandable = false;
        bool searchResult = false;
    };

    QStringList subfolders(const QString &relativePath) const;
    void appendExpanded(const QString &path, int level);
    void rebuild();

    QUrl m_projectFolder;
    QString m_root;
    QString m_search;
    QSet<QString> m_expanded;
    QVector<Entry> m_entries;
    bool m_searchLimited = false;
};

#endif
