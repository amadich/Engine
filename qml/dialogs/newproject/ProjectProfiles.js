.pragma library

// Registry of templates actually implemented by ProjectScaffolder.
// Do not advertise generators that have no corresponding project template.
var frontend = [
    { id: "next-js", name: "Next.js · Colly", detail: "App Router · Tailwind CSS", icon: "react.svg", runtime: "Node.js 20.9+", family: "Frontend" },
    { id: "react-vite", name: "React + Vite", detail: "TypeScript · SPA", icon: "react.svg", runtime: "Node.js 20+", family: "Frontend" },
    { id: "vue-vite", name: "Vue + Vite", detail: "Vue 3 · TypeScript", icon: "vuejs.svg", runtime: "Node.js 20+", family: "Frontend" },
    { id: "html", name: "HTML / CSS / JS", detail: "Static website", icon: "html5.svg", runtime: "Browser", family: "Frontend" }
]
var backend = [
    { id: "spring-boot", name: "Spring Boot", detail: "Java · Maven", icon: "spring.svg", runtime: "Java 17 / 21", family: "Backend" },
    { id: "express-ts", name: "Express", detail: "Node.js · TypeScript", icon: "nodejs.svg", runtime: "Node.js 20+", family: "Backend" }
]

function allFrameworks() { return frontend.concat(backend) }
function get(framework) {
    const entries = allFrameworks()
    for (let i = 0; i < entries.length; i++)
        if (entries[i].id === framework) return entries[i]
    return entries[0]
}
function iconPath(framework) { return "qrc:/engine/assets/icons/lang/" + get(framework).icon }
function isBackend(framework) { return framework === "spring-boot" || framework === "express-ts" }
function displayName(framework) { return get(framework).name }
function architectureOptions(framework) {
    return isBackend(framework)
        ? [
            { id: "layered", name: "Layered architecture", detail: "Controllers / services / repositories", preview: "src / controller / service / repository" },
            { id: "feature-based", name: "Feature-based architecture", detail: "Modules grouped by business capability", preview: "src / features / shared" }
          ]
        : [
            { id: "standard", name: "Standard layout", detail: "Shared components and application files", preview: "src / components / assets" },
            { id: "feature-based", name: "Feature-based layout", detail: "Screens and features organized by domain", preview: "src / features / shared" }
          ]
}
function dependencyOptions(framework) {
    if (framework === "spring-boot") return [
        { key: "websocket", name: "Spring WebSocket", group: "Realtime", artifact: "spring-boot-starter-websocket", detail: "WebSocket handlers and handshake support", description: "Enables the Spring WebSocket Echo package." },
        { key: "security", name: "Spring Security + JWT", group: "Security", artifact: "spring-boot-starter-security + oauth2-resource-server", detail: "Security filter chain and JWT resource-server support", description: "Adds Spring Security and OAuth2 Resource Server dependencies. Enables Jeridi's JWT component packages. You must configure issuer, keys and authentication for production." },
        { key: "validation", name: "Validation", group: "Web", artifact: "spring-boot-starter-validation", detail: "Jakarta Bean Validation", description: "Adds Jakarta Validation annotations and the validation provider. Useful for validating request bodies and service inputs." },
        { key: "actuator", name: "Spring Boot Actuator", group: "Operations", artifact: "spring-boot-starter-actuator", detail: "Health, metrics and application information", description: "Adds production-ready health and metrics endpoints. Review which endpoints are exposed before deployment." },
        { key: "data-jpa", name: "Spring Data JPA", group: "Persistence", artifact: "spring-boot-starter-data-jpa", detail: "Repositories, ORM and transactions", description: "Adds JPA and Hibernate. A database configuration is needed before launching an application that uses JPA." },
        { key: "h2", name: "H2 (local development)", group: "Persistence", artifact: "com.h2database:h2", detail: "Embedded development database", description: "Pair with Spring Data JPA for a local database. Choose PostgreSQL for a persistent deployment." },
        { key: "postgresql", name: "PostgreSQL Driver", group: "Persistence", artifact: "org.postgresql:postgresql", detail: "JDBC runtime driver", description: "Adds the PostgreSQL JDBC driver. Set the database URL and credentials yourself using environment variables or external configuration." },
        { key: "devtools", name: "Spring Boot DevTools", group: "Development", artifact: "spring-boot-devtools", detail: "Development-time restart helpers", description: "Adds Spring Boot DevTools to the Maven project for local development." },
        { key: "cache", name: "Spring Cache", group: "Performance", artifact: "spring-boot-starter-cache", detail: "Caching abstraction", description: "Adds the Spring caching abstraction. Cache provider and configuration remain under your control." }
    ]
    if (framework === "express-ts") return [
        { key: "websocket", name: "WebSocket (ws)", group: "Realtime", artifact: "ws + @types/ws", detail: "WebSocket server and TypeScript declarations", description: "Enables the Express WebSocket Echo package." },
        { key: "cors", name: "CORS", group: "Security", artifact: "cors + @types/cors", detail: "Cross-origin request middleware", description: "Registers CORS middleware with a configurable development origin (CORS_ORIGIN). Restrict origins for production." },
        { key: "helmet", name: "Helmet", group: "Security", artifact: "helmet", detail: "HTTP security headers", description: "Adds Helmet and registers it on the Express application to set common security-related HTTP headers." },
        { key: "morgan", name: "Morgan", group: "Observability", artifact: "morgan + @types/morgan", detail: "HTTP request logging", description: "Adds Morgan and registers its development request logger in the generated Express server." }
    ]
    if (framework === "react-vite" || framework === "vue-vite") return [
        { key: "router", name: framework === "react-vite" ? "React Router" : "Vue Router", group: "Navigation", artifact: framework === "react-vite" ? "react-router-dom" : "vue-router", detail: "Client-side navigation", description: "Adds a routing library to package.json. Routes are not automatically wired into the app; you can add them using the code editor." },
        { key: "axios", name: "Axios", group: "Networking", artifact: "axios", detail: "HTTP client", description: "Adds Axios for HTTP requests. It is not imported until you decide where to use it." },
        { key: "state", name: framework === "react-vite" ? "Zustand" : "Pinia", group: "State", artifact: framework === "react-vite" ? "zustand" : "pinia", detail: "State management", description: "Adds a state-management library to package.json. No stores are generated until you create them." }
    ]
    return []
}
function previewPaths(framework, architecture, packageName) {
    if (framework === "spring-boot") return [
        "pom.xml", "src/main/java/", (packageName || "com.example.demo").replace(/\./g, "/") + "/",
        architecture === "feature-based" ? "  features/health/" : "  controller/",
        architecture === "feature-based" ? "  security/" : "  service/",
        "src/main/resources/", "  application.properties", ".jeridi/project.json"
    ]
    if (framework === "express-ts") return [
        "package.json", "tsconfig.json", "src/index.ts", architecture === "feature-based" ? "src/features/health/" : "src/routes/", "src/middleware/", ".env.example", ".jeridi/project.json"
    ]
    if (framework === "next-js") return ["package.json", "postcss.config.mjs", "components.json", "src/app/layout.tsx", "src/app/page.tsx", "src/app/library/", ".jeridi/project.json"]
    if (framework === "html") return ["index.html", "styles.css", "app.js", architecture === "feature-based" ? "features/" : "assets/", ".jeridi/project.json"]
    return ["package.json", "vite.config.ts", "index.html", "src/", framework === "react-vite" ? "  App.tsx" : "  App.vue", architecture === "feature-based" ? "  features/" : "  components/", ".jeridi/project.json"]
}
