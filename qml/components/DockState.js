// Pure workspace layout rules.  Keep persistence/validation separate from the UI.
// A panel has exactly one home zone, and its visibility is independent of its zone.
var panelIds = ["components", "files", "output", "inspector", "preview"]
var zones = ["left", "center", "right"]

function defaults() {
    return [
        { id: "components", zone: "left", visible: true },
        { id: "files", zone: "left", visible: true },
        { id: "output", zone: "center", visible: true },
        { id: "inspector", zone: "right", visible: true },
        { id: "preview", zone: "right", visible: false }
    ]
}

function validZone(zone) { return zones.indexOf(zone) !== -1 }
function validId(id) { return panelIds.indexOf(id) !== -1 }

function parse(raw) {
    var parsed
    try { parsed = JSON.parse(raw) } catch (e) { return defaults() }
    if (!Array.isArray(parsed)) return defaults()
    var result = []
    var seen = {}
    for (var i = 0; i < parsed.length; ++i) {
        var item = parsed[i]
        if (!item || !validId(item.id) || seen[item.id]) continue
        var fallback = defaults().find(function(p) { return p.id === item.id })
        result.push({ id: item.id,
                      zone: validZone(item.zone) ? item.zone : fallback.zone,
                      visible: typeof item.visible === "boolean" ? item.visible : fallback.visible })
        seen[item.id] = true
    }
    var initial = defaults()
    for (var j = 0; j < initial.length; ++j) {
        if (!seen[initial[j].id]) result.push(initial[j])
    }
    return result
}

function orderedInZone(panels, zone) {
    return panels.filter(function(p) { return p.zone === zone })
                 .map(function(p) { return p.id })
}

function isVisible(panels, id) {
    var panel = panels.find(function(p) { return p.id === id })
    return !!(panel && panel.visible)
}

function setVisible(panels, id, value) {
    return panels.map(function(p) {
        return { id: p.id, zone: p.zone, visible: p.id === id ? !!value : p.visible }
    })
}

function move(panels, id, zone) {
    if (!validId(id) || !validZone(zone)) return panels
    var next = panels.filter(function(p) { return p.id !== id })
    var panel = panels.find(function(p) { return p.id === id })
    next.push({ id: id, zone: zone, visible: panel.visible })
    return next
}

function reorder(panels, id, delta) {
    var source = panels.findIndex(function(p) { return p.id === id })
    if (source < 0) return panels
    var zone = panels[source].zone
    var same = panels.filter(function(p) { return p.zone === zone })
    var from = same.findIndex(function(p) { return p.id === id })
    var to = from + delta
    if (to < 0 || to >= same.length) return panels
    var other = same[to].id
    var next = panels.slice()
    var a = next.findIndex(function(p) { return p.id === id })
    var b = next.findIndex(function(p) { return p.id === other })
    var temp = next[a]; next[a] = next[b]; next[b] = temp
    return next
}

function preset(name) {
    var p = defaults()
    if (name === "code") return p.map(function(x) {
        return { id: x.id, zone: x.zone, visible: false }
    })
    if (name === "preview") {
        p = move(p, "preview", "center")
        p = setVisible(p, "preview", true)
        p = setVisible(p, "output", false)
    } else if (name === "debug") {
        p = setVisible(p, "output", true)
        p = setVisible(p, "preview", false)
    }
    return p
}


// Workspace geometry (0.6.2): pure calculations, no QML object mutation.
// Geometry-only workspace engine (0.6.2).
// No QML object reparenting, no nested SplitView, no item insertion/removal.
// All five dock panels and the editor stay instantiated for their entire lifetime.
var ids = ["components", "files", "output", "inspector", "preview"]
var zones = ["left", "center", "right"]

function clamp(value, lo, hi) {
    return Math.max(lo, Math.min(hi, value))
}

function emptyRect() {
    return { x: 0, y: 0, width: 0, height: 0, visible: false, fill: false }
}

function calculate(width, height, toolbarHeight, panels, focus, leftPreference, rightPreference, preferred) {
    var w = Math.max(0, Number(width) || 0)
    var h = Math.max(0, Number(height) || 0)
    var top = Math.max(0, Number(toolbarHeight) || 0)
    var usableH = Math.max(0, h - top)
    var result = { editor: emptyRect(), components: emptyRect(), files: emptyRect(),
                   output: emptyRect(), inspector: emptyRect(), preview: emptyRect(),
                   leftHandle: emptyRect(), rightHandle: emptyRect() }
    if (w < 1 || usableH < 1) return result

    var active = []
    for (var i = 0; i < panels.length; i++) {
        var p = panels[i]
        if (p && ids.indexOf(p.id) !== -1 && p.visible === true)
            active.push(p)
    }

    // Focus modes are guaranteed to be usable even with every tool window hidden.
    if (focus === "editor") {
        result.editor = { x: 0, y: top, width: w, height: usableH, visible: true, fill: true }
        return result
    }
    if (ids.indexOf(focus) !== -1) {
        result[focus] = { x: 0, y: top, width: w, height: usableH, visible: true, fill: true }
        return result
    }

    var left = active.filter(function(p) { return p.zone === "left" }).map(function(p) { return p.id })
    var center = active.filter(function(p) { return p.zone === "center" }).map(function(p) { return p.id })
    var right = active.filter(function(p) { return p.zone === "right" }).map(function(p) { return p.id })
    var gap = 5
    var handles = (left.length ? gap : 0) + (right.length ? gap : 0)
    var availableW = Math.max(0, w - handles)
    var leftW = left.length ? clamp(Number(leftPreference) || 260, 170, Math.max(170, availableW * 0.43)) : 0
    var rightW = right.length ? clamp(Number(rightPreference) || 300, 170, Math.max(170, availableW * 0.43)) : 0
    var minCenter = Math.min(350, availableW * 0.4)
    if (leftW + rightW > availableW - minCenter) {
        var sideSpace = Math.max(0, availableW - minCenter)
        var factor = sideSpace / Math.max(1, leftW + rightW)
        leftW *= factor
        rightW *= factor
    }
    var centerW = Math.max(0, availableW - leftW - rightW)
    var centerX = leftW + (left.length ? gap : 0)
    var rightX = centerX + centerW + (right.length ? gap : 0)

    function pref(id) {
        var p = preferred && Number(preferred[id])
        return isFinite(p) && p >= 90 ? p : (id === "output" ? 250 : 260)
    }
    function stack(list, x, y, columnW, columnH) {
        if (!list.length || columnW <= 0 || columnH <= 0) return
        var spacing = 4
        var remaining = Math.max(0, columnH - spacing * (list.length - 1))
        var yy = y
        for (var j = 0; j < list.length; j++) {
            var countLeft = list.length - j
            var hh
            if (countLeft === 1) {
                hh = remaining
            } else {
                var minHeight = Math.min(105, remaining / countLeft)
                hh = clamp(pref(list[j]), minHeight, Math.max(minHeight, remaining - (countLeft - 1) * minHeight))
            }
            result[list[j]] = { x: x, y: yy, width: columnW, height: hh,
                                visible: true, fill: countLeft === 1 }
            yy += hh + spacing
            remaining = Math.max(0, remaining - hh)
        }
    }
    stack(left, 0, top, leftW, usableH)
    stack(right, rightX, top, rightW, usableH)

    // Editor is permanent, takes remaining center space above center-zone panels.
    // If many panels are moved into center, reduce their height proportionally.
    var centerSpacing = 4
    var editorMinimum = Math.min(190, usableH * 0.38)
    var dockSpace = Math.max(0, usableH - editorMinimum - centerSpacing * center.length)
    var requested = center.reduce(function(sum, id) { return sum + pref(id) }, 0)
    var scale = requested > dockSpace && requested > 0 ? dockSpace / requested : 1
    var docksTotal = center.reduce(function(sum, id) { return sum + pref(id) * scale }, 0)
    var editorH = Math.max(0, usableH - docksTotal - centerSpacing * center.length)
    result.editor = { x: centerX, y: top, width: centerW, height: editorH,
                      visible: true, fill: center.length === 0 }
    var cy = top + editorH + centerSpacing
    for (var k = 0; k < center.length; k++) {
        var ph = pref(center[k]) * scale
        if (k === center.length - 1) ph = Math.max(0, top + usableH - cy)
        result[center[k]] = { x: centerX, y: cy, width: centerW, height: ph,
                              visible: true, fill: k === center.length - 1 }
        cy += ph + centerSpacing
    }

    if (left.length && centerW > 0)
        result.leftHandle = { x: leftW, y: top, width: gap, height: usableH, visible: true, fill: false }
    if (right.length && centerW > 0)
        result.rightHandle = { x: centerX + centerW, y: top, width: gap, height: usableH, visible: true, fill: false }
    return result
}
