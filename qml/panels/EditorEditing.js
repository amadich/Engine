.pragma library

function wordRange(text, position) {
    const left = (text.slice(0, position).match(/[\w$-]+$/) || [""])[0]
    const right = (text.slice(position).match(/^[\w$-]+/) || [""])[0]
    return { start: position - left.length, end: position + right.length, prefix: left }
}

function suggestions(text, range, fileName) {
    if (!range.prefix) return []
    const suffix = fileName.toLowerCase().split(".").pop()
    let keywords = []
    if (["tsx", "ts", "jsx", "js", "vue"].includes(suffix))
        keywords = ["import", "export", "default", "const", "let", "function", "return", "interface", "type", "async", "await", "true", "false", "null", "undefined", "useState", "useEffect", "class", "extends", "implements", "try", "catch", "throw", "new", "map", "filter", "reduce", "Promise", "console", "await", "typeof"]
    else if (suffix === "java")
        keywords = ["public", "private", "protected", "class", "interface", "record", "enum", "static", "final", "void", "String", "return", "new", "import", "package", "extends", "implements", "@RestController", "@Service", "@Repository", "@Autowired", "@GetMapping", "@PostMapping", "@RequestMapping", "@Configuration", "@Bean", "@Entity"]
    else if (["cpp", "h", "hpp", "cc"].includes(suffix))
        keywords = ["include", "namespace", "class", "struct", "public", "private", "protected", "virtual", "override", "const", "constexpr", "auto", "return", "nullptr", "static", "void", "QString", "QObject", "Q_PROPERTY", "Q_INVOKABLE", "Q_OBJECT"]
    else if (suffix === "qml")
        keywords = ["import", "Item", "Rectangle", "Text", "Label", "Button", "property", "readonly", "signal", "function", "anchors", "Layout", "width", "height", "visible", "color", "Component", "Connections", "Repeater", "ListView", "onClicked"]
    else if (suffix === "json") keywords = ["true", "false", "null"]
    else if (suffix === "css")
        keywords = ["display", "position", "padding", "margin", "color", "background-color", "border-radius", "align-items", "justify-content", "transition", "flex", "grid", "font-size", "gap", "overflow"]
    else if (["yml", "yaml"].includes(suffix)) keywords = ["name", "version", "services", "environment", "ports", "image", "build", "volumes", "depends_on"]
    const other = text.slice(0, range.start) + " " + text.slice(range.end)
    const words = other.match(/[A-Za-z_$][\w$-]*/g) || []
    const prefix = range.prefix.toLowerCase()
    return Array.from(new Set(keywords.concat(words)))
        .filter(word => word.toLowerCase() !== prefix && word.toLowerCase().startsWith(prefix))
        .sort((a, b) => {
            const aExact = a.startsWith(range.prefix) ? 0 : 1
            const bExact = b.startsWith(range.prefix) ? 0 : 1
            return aExact - bExact || a.localeCompare(b)
        }).slice(0, 12)
}

function newline(text, start, end) {
    const lineStart = start > 0 ? text.lastIndexOf("\n", start - 1) + 1 : 0
    const before = text.slice(lineStart, start)
    const leading = before.match(/^[ \t]*/)[0]
    const opening = before.replace(/[ \t]+$/, "").slice(-1)
    const closing = ({ "{": "}", "[": "]", "(": ")" })[opening]
    const indent = leading + (closing ? "  " : "")
    const firstLine = "\n" + indent
    const paired = closing && text.charAt(end) === closing
    return { text: firstLine + (paired ? "\n" + leading : ""), cursor: start + firstLine.length }
}
