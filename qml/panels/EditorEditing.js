.pragma library

function wordRange(text, position) {
    const left = (text.slice(0, position).match(/[\w$-]+$/) || [""])[0]
    const right = (text.slice(position).match(/^[\w$-]+/) || [""])[0]
    return { start: position - left.length, end: position + right.length, prefix: left }
}

function suggestions(text, range, fileName) {
    if (!range.prefix)
        return []

    let keywords = []
    if (/\.(tsx?|jsx?)$/i.test(fileName))
        keywords = ["import", "export", "default", "const", "let", "function",
                    "return", "interface", "type", "async", "await", "true", "false", "null"]
    else if (/\.json$/i.test(fileName))
        keywords = ["true", "false", "null"]
    else if (/\.css$/i.test(fileName))
        keywords = ["display", "position", "padding", "margin", "color",
                    "background-color", "border-radius", "align-items",
                    "justify-content", "transition"]

    const other = text.slice(0, range.start) + " " + text.slice(range.end)
    const words = other.match(/[A-Za-z_$][\w$-]*/g) || []
    return Array.from(new Set(keywords.concat(words)))
        .filter(word => word !== range.prefix && word.indexOf(range.prefix) === 0)
        .sort().slice(0, 8)
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

    return {
        text: firstLine + (paired ? "\n" + leading : ""),
        cursor: start + firstLine.length
    }
}
