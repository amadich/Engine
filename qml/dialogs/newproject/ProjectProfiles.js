.pragma library

var frontend = [
    { id: "react-vite", name: "React + Vite", icon: "⚛", detail: "TypeScript / SPA" },
    { id: "vue-vite", name: "Vue + Vite", icon: "◆", detail: "Vue 3 / TypeScript" },
    { id: "html", name: "HTML / CSS / JS", icon: "⌘", detail: "Static website" }
]

var backend = [
    { id: "spring-boot", name: "Spring Boot", icon: "◉", detail: "Java 17 / Maven" },
    { id: "express-ts", name: "Express", icon: "↗", detail: "Node.js / TypeScript" }
]

function isBackend(framework) {
    return framework === "spring-boot" || framework === "express-ts"
}

function displayName(framework) {
    const all = frontend.concat(backend)
    for (let i = 0; i < all.length; ++i) {
        if (all[i].id === framework) return all[i].name
    }
    return framework
}

function dependencyOptions(framework) {
    if (framework === "spring-boot")
        return [
            { key: "security", name: "Spring Security + OAuth2 Resource Server",
              detail: "Enables Spring JWT components in the library." },
            { key: "validation", name: "Bean Validation",
              detail: "Add Jakarta Validation annotations and provider." },
            { key: "actuator", name: "Spring Boot Actuator",
              detail: "Operational health and metrics endpoints." }
        ]
    if (framework === "express-ts")
        return [
            { key: "cors", name: "CORS middleware",
              detail: "Allow only the configured development origin." }
        ]
    return []
}
