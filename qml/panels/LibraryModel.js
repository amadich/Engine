.pragma library

// Stateless view-model helpers. No Qt objects, no filesystem access.
// Unit-testable independently of the QML rendering layer.

function counts(all, installed, favorites) {
    let installedTotal = 0
    let favoriteTotal = 0
    for (let i = 0; i < all.length; ++i) {
        const id = String(all[i].id || "")
        if (installed[id]) ++installedTotal
        if (favorites[id]) ++favoriteTotal
    }
    return { catalog: all.length, installed: installedTotal, favorites: favoriteTotal }
}

function matches(definition, installed, favorites, mode, query) {
    const id = String(definition.id || "")
    if (mode === "installed" && !installed[id]) return false
    if (mode === "favorites" && !favorites[id]) return false
    if (!query) return true

    const categories = definition.category || []
    const files = definition.files || []
    let targets = ""
    for (let i = 0; i < files.length; ++i)
        targets += " " + String(files[i].target || "")
    const haystack = (String(definition.name || "") + " " + id + " "
                      + categories.join(" ") + " " + String(definition.description || "")
                      + targets).toLowerCase()
    return haystack.indexOf(query) !== -1
}

function buildRows(all, installed, favorites, mode, sortMode, search, expandedGroups) {
    const query = (search || "").trim().toLowerCase()
    const tree = { children: [], items: [], path: "" }
    let matched = 0

    for (let i = 0; i < all.length; ++i) {
        const def = all[i]
        if (!matches(def, installed, favorites, mode, query)) continue
        ++matched
        const categories = def.category && def.category.length > 0
                           ? def.category : ["Uncategorized"]
        let node = tree
        for (let j = 0; j < categories.length; ++j) {
            const name = String(categories[j])
            const path = node.path ? node.path + "/" + name : name
            let child = null
            for (let k = 0; k < node.children.length; ++k) {
                if (node.children[k].path === path) {
                    child = node.children[k]
                    break
                }
            }
            if (!child) {
                child = { name: name, path: path, children: [], items: [], count: 0 }
                node.children.push(child)
            }
            node = child
        }
        node.items.push({
            kind: "component", id: String(def.id || ""),
            name: String(def.name || def.id || "Unnamed"),
            fileCount: (def.files || []).length,
            category: categories.join(" / "), depth: categories.length,
            installed: !!installed[String(def.id || "")],
            favorite: !!favorites[String(def.id || "")]
        })
    }

    function sortTree(node) {
        node.children.sort(function(a, b) { return a.name.localeCompare(b.name) })
        node.items.sort(function(a, b) {
            if (sortMode === "installed" && a.installed !== b.installed)
                return a.installed ? -1 : 1
            return a.name.localeCompare(b.name)
        })
        node.count = node.items.length
        for (let i = 0; i < node.children.length; ++i) {
            sortTree(node.children[i])
            node.count += node.children[i].count
        }
    }
    sortTree(tree)

    const rows = []
    function flatten(node, depth) {
        const open = query.length > 0 ||
            (Object.prototype.hasOwnProperty.call(expandedGroups, node.path)
             ? !!expandedGroups[node.path] : depth === 0)
        rows.push({ kind: "category", name: node.name, path: node.path,
                    count: node.count, depth: depth, expanded: open })
        if (!open) return
        for (let i = 0; i < node.children.length; ++i)
            flatten(node.children[i], depth + 1)
        for (let i = 0; i < node.items.length; ++i)
            rows.push(node.items[i])
    }
    for (let i = 0; i < tree.children.length; ++i)
        flatten(tree.children[i], 0)

    return { rows: rows, matched: matched }
}

function expandAll(all, expand) {
    const result = ({})
    for (let i = 0; i < all.length; ++i) {
        const cats = all[i].category || ["Uncategorized"]
        let path = ""
        for (let j = 0; j < cats.length; ++j) {
            path = path ? path + "/" + String(cats[j]) : String(cats[j])
            result[path] = expand
        }
    }
    return result
}
