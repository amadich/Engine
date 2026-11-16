#ifndef COMPONENTREGISTRY_H
#define COMPONENTREGISTRY_H

#include <QAbstractItemModel>
#include <QHash>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QUrl>
#include <QtQml/qqmlregistration.h>
#include <memory>
#include <vector>

class QQmlEngine;
class QJSEngine;

// The only component catalog. Each package provides its own component.json.
class ComponentRegistry : public QAbstractItemModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList components READ components CONSTANT)

public:
    explicit ComponentRegistry(QObject *parent = nullptr);

    static ComponentRegistry *create(QQmlEngine *engine, QJSEngine *scriptEngine);
    static ComponentRegistry &instance();

    QModelIndex index(int row, int column,
                      const QModelIndex &parent = {}) const override;
    QModelIndex parent(const QModelIndex &index) const override;
    int rowCount(const QModelIndex &parent = {}) const override;
    int columnCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QVariantList components() const;
    Q_INVOKABLE QVariantMap component(const QString &id) const;
    Q_INVOKABLE QUrl inspectorUrl(const QString &id) const;

private:
    struct Node {
        QString name;
        QString componentId;
        QString activation;
        Node *parent = nullptr;
        int row = 0;
        std::vector<std::unique_ptr<Node>> children;
    };

    void loadPackages();
    Node *appendChild(Node *parent, const QString &name,
                      const QString &componentId = {},
                      const QString &activation = {});

    std::unique_ptr<Node> m_root;
    QHash<QString, QVariantMap> m_components;
    QStringList m_order;
};

#endif
