.pragma library

// Small, deterministic editor helpers. No language server or network access.
// They intentionally do not claim semantic analysis of a whole project.
function caretInfo(text, position) {
    const before = text.slice(0, Math.max(0, position))
    const lastBreak = before.lastIndexOf("\n")
    return { line: before.split("\n").length, column: before.length - lastBreak }
}

function importContext(text, position) {
    const start = text.lastIndexOf("\n", Math.max(0, position - 1)) + 1
    const fragment = text.slice(start, position)
    // Handle ESM, require(), dynamic import(), CSS @import and local C/C++ headers.
    const match = fragment.match(/(?:\bfrom\s*|\bimport\s*(?:\(\s*)?|\brequire\s*\(\s*|@import\s*|#include\s*)["']([^"'\n]*)$/)
    if (!match) return null
    const prefix = match[1]
    if (!(prefix.startsWith(".") || prefix.startsWith("@/") || prefix.startsWith("~/"))) return null
    const tail = (text.slice(position).match(/^[^"'\n]*/) || [""])[0]
    return { prefix: prefix, start: position - prefix.length, end: position + tail.length }
}

function extractImports(text, fileName) {
    const items = []
    const seen = new Set()
    const lines = text.split("\n")
    const java = /\.java$/i.test(fileName)
    for (let i = 0; i < lines.length && items.length < 180; ++i) {
        const line = lines[i]
        const specs = []
        if (java) {
            const m = line.match(/^\s*import\s+(?:static\s+)?([\w.]+)(?:\.\*)?\s*;/)
            if (m) specs.push(m[1])
        } else {
            const esm = /\b(?:import|export)\s+(?:[^\n]*?\s+from\s*)?["']([^"']+)["']/g
            const dynamic = /\b(?:require|import)\s*\(\s*["']([^"']+)["']/g
            const css = /@import\s+["']([^"']+)["']/g
            const cpp = /^\s*#include\s*"([^"]+)"/
            let m
            while ((m = esm.exec(line)) !== null) specs.push(m[1])
            while ((m = dynamic.exec(line)) !== null) specs.push(m[1])
            while ((m = css.exec(line)) !== null) specs.push(m[1])
            const header = line.match(cpp)
            if (header) specs.push("./" + header[1])
        }
        for (const spec of specs) {
            const key = spec + ":" + (i + 1)
            if (!seen.has(key)) {
                seen.add(key)
                items.push({ specifier: spec, line: i + 1 })
            }
        }
    }
    return items
}

function extractSymbols(text, fileName) {
    const items = []
    const lines = text.split("\n")
    for (let i = 0; i < lines.length && items.length < 240; ++i) {
        const line = lines[i]
        let m = line.match(/^\s*(?:export\s+)?(?:default\s+)?(?:async\s+)?function\s+([\w$]+)/)
        let kind = "function"
        if (!m) { m = line.match(/^\s*(?:(?:export|default|public|private|protected|abstract|final|data|sealed|open)\s+)*class\s+(\w+)/); kind = "class" }
        if (!m) { m = line.match(/^\s*(?:(?:export|public|private|protected|default)\s+)*(?:interface|type|enum|record)\s+(\w+)/); kind = "type" }
        if (!m) { m = line.match(/^\s*(?:export\s+)?(?:const|let|var)\s+([\w$]+)\s*=/); kind = "variable" }
        if (!m && /\.(java|kt|cpp|h)$/i.test(fileName)) {
            m = line.match(/^\s*(?:public|private|protected|static|final|suspend|override|virtual|inline|\s)+\s*[\w<>\[\],?]+\s+(\w+)\s*\(/)
            kind = "method"
        }
        if (!m && /\.(css|scss)$/i.test(fileName)) { m = line.match(/^\s*([.#][\w-]+)\s*\{/); kind = "selector" }
        if (m) items.push({ name: m[1], kind: kind, line: i + 1 })
    }
    return items
}

function matches(text, query, matchCase) {
    if (!query) return []
    const haystack = matchCase ? text : text.toLowerCase()
    const needle = matchCase ? query : query.toLowerCase()
    const result = []
    let start = 0
    while (start < haystack.length && result.length < 20000) {
        const index = haystack.indexOf(needle, start)
        if (index < 0) break
        result.push(index)
        start = index + Math.max(1, needle.length)
    }
    return result
}
