// Pure formatting helpers; no filesystem operations and no project writes.
function iconFor(name, folder) {
    if (folder) return "folder.svg";
    var ext = String(name || "").split(".").pop().toLowerCase();
    if (["png", "jpg", "jpeg", "webp", "svg", "gif", "bmp", "ico", "avif"].indexOf(ext) >= 0)
        return "image.svg";
    if (["tsx", "jsx", "qml", "vue", "svelte"].indexOf(ext) >= 0)
        return "cube_blue.svg";
    if (["json", "yaml", "yml", "toml", "xml"].indexOf(ext) >= 0)
        return "cube_block.svg";
    return "file.svg";
}

function formatBytes(size) {
    var value = Number(size);
    if (!isFinite(value) || value < 0) return "—";
    if (value < 1024) return value + " B";
    var units = ["KB", "MB", "GB", "TB"];
    var index = -1;
    do { value /= 1024; ++index; } while (value >= 1024 && index < units.length - 1);
    return value.toFixed(value < 10 ? 1 : 0) + " " + units[index];
}

function fileKind(details) {
    if (!details || !details.name) return "No selection";
    if (details.folder) return "Folder";
    var ext = String(details.extension || "").toUpperCase();
    return ext ? ext + " file" : "File";
}

function isFavorite(favorites, relativePath) {
    return !!(favorites && relativePath && favorites[relativePath]);
}

function safeFavorites(json, projectKey) {
    try {
        var all = JSON.parse(json || "{}");
        var entries = all[projectKey] || [];
        if (!Array.isArray(entries)) return {};
        var result = {};
        for (var i = 0; i < entries.length; ++i) {
            if (typeof entries[i] === "string" && entries[i].length)
                result[entries[i]] = true;
        }
        return result;
    } catch (e) {
        return {};
    }
}

function serializeFavorites(json, projectKey, favorites) {
    var all = {};
    try {
        all = JSON.parse(json || "{}");
        if (!all || typeof all !== "object" || Array.isArray(all)) all = {};
    } catch (e) { all = {}; }
    if (projectKey) all[projectKey] = Object.keys(favorites || {}).filter(function(key) {
        return !!favorites[key];
    });
    return JSON.stringify(all);
}
