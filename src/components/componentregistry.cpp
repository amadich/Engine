#include "componentregistry.h"

#include <QDirIterator>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJSEngine>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQmlEngine>
#include <QRegularExpression>
#include <QDebug>
#include <algorithm>

namespace {
constexpr int ComponentIdRole = Qt::UserRole + 1;
constexpr int ActivationRole = Qt::UserRole + 2;

bool safeRelativePath(const QString &path)
{
    if (path.isEmpty() || path.startsWith('/') || path.contains('\\'))
        return false;
    const QStringList segments = path.split('/');
    return std::all_of(segments.cbegin(), segments.cend(),
                       [](const QString &s) { return !s.isEmpty() && s != "." && s != ".."; });
}
}

ComponentRegistry::ComponentRegistry(QObject *parent)
    : QAbstractItemModel(parent), m_root(std::make_unique<Node>())
{
    loadPackages();
}

ComponentRegistry &ComponentRegistry::instance()
{
    static ComponentRegistry registry;
    return registry;
}

ComponentRegistry *ComponentRegistry::create(QQmlEngine *, QJSEngine *)
{
    auto *registry = &instance();
    QQmlEngine::setObjectOwnership(registry, QQmlEngine::CppOwnership);
    return registry;
}

ComponentRegistry::Node *ComponentRegistry::appendChild(
    Node *parentNode, const QString &name, const QString &componentId,
    const QString &activation)
{
    auto node = std::make_unique<Node>();
    node->name = name;
    node->componentId = componentId;
    node->activation = activation;
    node->parent = parentNode;
    node->row = static_cast<int>(parentNode->children.size());
    Node *result = node.get();
    parentNode->children.push_back(std::move(node));
    return result;
}

void ComponentRegistry::loadPackages()
{
    // Qt resources are traversed, so adding a package never modifies this class.
    QDirIterator it(QStringLiteral(":/component-packages"),
                    {QStringLiteral("component.json")}, QDir::Files,
                    QDirIterator::Subdirectories);
    QStringList manifests;
    while (it.hasNext())
        manifests.append(it.next());
    manifests.sort();

    for (const QString &manifestPath : manifests) {
        QFile manifest(manifestPath);
        if (!manifest.open(QIODevice::ReadOnly)) {
            qWarning() << "Cannot read component manifest:" << manifestPath;
            continue;
        }

        QJsonParseError parseError;
        const QJsonDocument document = QJsonDocument::fromJson(manifest.readAll(), &parseError);
        if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
            qWarning() << "Invalid component manifest:" << manifestPath << parseError.errorString();
            continue;
        }

        const QJsonObject json = document.object();
        const QString id = json.value("id").toString();
        const QString name = json.value("name").toString();
        const QString activation = json.value("activation").toString("inspect");
        const QJsonArray category = json.value("category").toArray();
        static const QRegularExpression idPattern(QStringLiteral("^[a-z][a-z0-9-]*$"));

        if (!idPattern.match(id).hasMatch() || id != QFileInfo(manifestPath).dir().dirName()
            || name.trimmed().isEmpty() || category.isEmpty()
            || (activation != "inspect" && activation != "install")
            || !json.value("files").isArray() || m_components.contains(id)) {
            qWarning() << "Invalid/duplicate component definition:" << manifestPath;
            continue;
        }

        QStringList categories;
        for (const QJsonValue &value : category) {
            if (!value.isString() || value.toString().trimmed().isEmpty()) {
                categories.clear();
                break;
            }
            categories.append(value.toString());
        }
        const QString inspector = json.value("inspector").toString();
        if (categories.isEmpty() || (!inspector.isEmpty()
            && (!safeRelativePath(inspector) || !inspector.startsWith("inspector/")
                || !inspector.endsWith(".qml")))) {
            qWarning() << "Invalid component category/inspector:" << manifestPath;
            continue;
        }

        m_components.insert(id, json.toVariantMap());
        m_order.append(id);

        Node *parentNode = m_root.get();
        for (const QString &categoryName : categories) {
            Node *existing = nullptr;
            for (const auto &child : parentNode->children) {
                if (child->componentId.isEmpty() && child->name == categoryName) {
                    existing = child.get();
                    break;
                }
            }
            parentNode = existing ? existing : appendChild(parentNode, categoryName);
        }
        appendChild(parentNode, name, id, activation);
    }
}

QModelIndex ComponentRegistry::index(int row, int column, const QModelIndex &parentIndex) const
{
    if (column != 0 || row < 0 || (parentIndex.isValid() && parentIndex.column() != 0))
        return {};
    const Node *parentNode = parentIndex.isValid()
        ? static_cast<const Node *>(parentIndex.internalPointer()) : m_root.get();
    if (row >= static_cast<int>(parentNode->children.size()))
        return {};
    return createIndex(row, column, parentNode->children.at(row).get());
}

QModelIndex ComponentRegistry::parent(const QModelIndex &childIndex) const
{
    if (!childIndex.isValid())
        return {};
    const Node *parentNode = static_cast<const Node *>(childIndex.internalPointer())->parent;
    if (!parentNode || parentNode == m_root.get())
        return {};
    return createIndex(parentNode->row, 0, const_cast<Node *>(parentNode));
}

int ComponentRegistry::rowCount(const QModelIndex &parentIndex) const
{
    if (parentIndex.isValid() && parentIndex.column() != 0)
        return 0;
    const Node *node = parentIndex.isValid()
        ? static_cast<const Node *>(parentIndex.internalPointer()) : m_root.get();
    return static_cast<int>(node->children.size());
}

int ComponentRegistry::columnCount(const QModelIndex &) const
{
    return 1;
}

QVariant ComponentRegistry::data(const QModelIndex &modelIndex, int role) const
{
    if (!modelIndex.isValid())
        return {};
    const Node *node = static_cast<const Node *>(modelIndex.internalPointer());
    switch (role) {
    case Qt::DisplayRole: return node->name;
    case ComponentIdRole: return node->componentId;
    case ActivationRole: return node->activation;
    default: return {};
    }
}

QHash<int, QByteArray> ComponentRegistry::roleNames() const
{
    return {{Qt::DisplayRole, "display"}, {ComponentIdRole, "componentId"},
            {ActivationRole, "activation"}};
}

QVariantList ComponentRegistry::components() const
{
    QVariantList result;
    for (const QString &id : m_order)
        result.append(m_components.value(id));
    return result;
}

QVariantMap ComponentRegistry::component(const QString &id) const
{
    return m_components.value(id);
}

QUrl ComponentRegistry::inspectorUrl(const QString &id) const
{
    const QString path = m_components.value(id).value("inspector").toString();
    if (!safeRelativePath(path) || !path.startsWith("inspector/") || !path.endsWith(".qml"))
        return {};
    return QUrl(QStringLiteral("qrc:/qt/qml/JeridiEngine/packages/%1/%2").arg(id, path));
}
