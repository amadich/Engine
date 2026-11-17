.pragma library

// Presentation-only console formatting. No filesystem access or project writes.
// Functions are pure to keep parser behavior testable without a running UI.

function stripAnsi(input) {
    return String(input === undefined || input === null ? "" : input)
        .replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "")
        .replace(/\x1b\][^\x07]*(?:\x07|\x1b\\)/g, "")
}

function normalizeLine(input) {
    return stripAnsi(input).replace(/\t/g, "    ").replace(/\u0000/g, "")
}

function classify(line, source) {
    const content = String(line).toLowerCase()
    if (/(^|\W)(error|failed|failure|fatal|exception|uncaught|cannot find|not found|segmentation fault)(\W|$)/.test(content)
            || /\bnpm\s+err!/.test(content))
        return "error"

    if (/(^|\W)(warn|warning|deprecated|deprecation)(\W|$)/.test(content))
        return "warning"

    if (/(^|\W)(ready|success|succeeded|saved|installed|completed|passed)(\W|$)/.test(content)
            || /finished with exit code 0/.test(content))
        return "success"

    return source === "engine" ? "system" : "info"
}

function matches(entry, level, query) {
    if (level === "error" && entry.level !== "error") return false
    if (level === "warning" && entry.level !== "warning") return false
    if (level === "info" && entry.level !== "info"
            && entry.level !== "success" && entry.level !== "system") return false
    if (level === "process" && entry.source !== "process") return false

    const text = String(query || "").trim().toLowerCase()
    return !text || (entry.message + " " + entry.source + " " + entry.level)
                         .toLowerCase().indexOf(text) !== -1
}

function levelColor(level) {
    if (level === "error") return "#F2858D"
    if (level === "warning") return "#E6B86B"
    if (level === "success") return "#36C596"
    if (level === "system") return "#83B5FF"
    return "#8494A7"
}

function levelLabel(level) {
    if (level === "error") return "ERROR"
    if (level === "warning") return "WARN"
    if (level === "success") return "OK"
    if (level === "system") return "ENGINE"
    return "INFO"
}

function formatForCopy(entry, includeTime) {
    const prefix = includeTime ? "[" + entry.time + "] " : ""
    return prefix + entry.message
}
