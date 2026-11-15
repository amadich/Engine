#ifndef PROJECTFILESMODEL_H
#define PROJECTFILESMODEL_H

#include <QDir>
#include <QFileSystemModel>
#include <QSortFilterProxyModel>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

class ProjectFilesModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit ProjectFilesModel(QObject *parent = nullptr)
        : QSortFilterProxyModel(parent)
    {
        m_files.setFilter(QDir::AllDirs | QDir::Files
                          | QDir::NoDotAndDotDot | QDir::NoSymLinks);
        m_files.setReadOnly(true);
        m_files.setOption(QFileSystemModel::DontUseCustomDirectoryIcons);
        setSourceModel(&m_files);
    }

    Q_INVOKABLE QModelIndex openFolder(const QUrl &folder)
    {
        if (!folder.isLocalFile() || !QDir(folder.toLocalFile()).exists()) {
            return {};
        }

        return mapFromSource(m_files.setRootPath(folder.toLocalFile()));
    }

    Q_INVOKABLE QUrl fileUrl(const QModelIndex &index) const
    {
        const QModelIndex sourceIndex = mapToSource(index);
        if (!sourceIndex.isValid()) {
            return {};
        }

        return QUrl::fromLocalFile(m_files.filePath(sourceIndex));
    }

    Q_INVOKABLE bool isFolder(const QModelIndex &index) const
    {
        const QModelIndex sourceIndex = mapToSource(index);
        return sourceIndex.isValid() && m_files.isDir(sourceIndex);
    }

protected:
    bool filterAcceptsRow(int row, const QModelIndex &parent) const override
    {
        const QModelIndex index = m_files.index(row, 0, parent);
        return !m_files.isDir(index)
               || m_files.fileName(index) != QStringLiteral("node_modules");
    }

private:
    QFileSystemModel m_files;
};

#endif