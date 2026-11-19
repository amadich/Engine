#include "projectscaffolder.h"

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMap>
#include <QProcess>
#include <QRegularExpression>
#include <QSaveFile>
#include <QSet>

namespace {

const QMap<QString, QString> &frameworkKinds()
{
    static const QMap<QString, QString> kinds{
        {"react-vite", "frontend"}, {"next-js", "frontend"},
        {"vue-vite", "frontend"}, {"html", "frontend"},
        {"express-ts", "backend"}, {"spring-boot", "backend"}
    };
    return kinds;
}

QString toJavaClass(const QString &name)
{
    QString result;
    for (const QString &part : name.split(QRegularExpression("[-_]+"), Qt::SkipEmptyParts)) {
        if (!part.isEmpty())
            result += part.left(1).toUpper() + part.mid(1);
    }
    return result + "Application";
}

QString javaPackagePath(const QString &packageName)
{
    QString result = packageName;
    result.replace('.', '/');
    return result;
}

bool writeNewFile(const QDir &root, const QString &relative, const QByteArray &bytes)
{
    const QString path = root.filePath(relative);
    const QFileInfo info(path);
    const QString folder = QFileInfo(relative).path();
    if (info.exists() || info.isSymLink()
        || (folder != "." && !root.mkpath(folder)))
        return false;
    QSaveFile file(path);
    return file.open(QIODevice::WriteOnly)
           && file.write(bytes) == bytes.size() && file.commit();
}

QString springDependencyXml(const QStringList &items)
{
    // Only known Maven coordinates may be written to a generated pom.xml.
    const QMap<QString, QStringList> packages {
        {"security", {"spring-boot-starter-security", "spring-boot-starter-oauth2-resource-server"}},
        {"validation", {"spring-boot-starter-validation"}},
        {"actuator", {"spring-boot-starter-actuator"}},
        {"data-jpa", {"spring-boot-starter-data-jpa"}},
        {"devtools", {"spring-boot-devtools"}},
        {"cache", {"spring-boot-starter-cache"}}
    };
    QString xml;
    for (const QString &item : items) {
        if (item == "h2") {
            xml += "    <dependency><groupId>com.h2database</groupId>"
                   "<artifactId>h2</artifactId><scope>runtime</scope></dependency>\n";
            continue;
        }
        if (item == "postgresql") {
            xml += QStringLiteral("    <dependency>\n"
                                  "      <groupId>org.postgresql</groupId>\n"
                                  "      <artifactId>postgresql</artifactId>\n"
                                  "      <scope>runtime</scope>\n"
                                  "    </dependency>\n");
            continue;
        }
        for (const QString &artifact : packages.value(item)) {
            xml += QStringLiteral("    <dependency>\n"
                                  "      <groupId>org.springframework.boot</groupId>\n"
                                  "      <artifactId>%1</artifactId>\n"
                                  "    </dependency>\n").arg(artifact);
        }
    }
    return xml;
}

QString javascriptExtras(const QString &framework, const QStringList &items, bool development)
{
    // The IDs and versions are fixed here: user input never becomes package.json syntax.
    const QMap<QString, QString> production {
        {"cors", "\"cors\": \"^2.8.5\""},
        {"helmet", "\"helmet\": \"^8.0.0\""},
        {"morgan", "\"morgan\": \"^1.10.0\""},
        {"axios", "\"axios\": \"^1.8.0\""},
        {"router", framework == "vue-vite"
            ? "\"vue-router\": \"^4.5.0\""
            : "\"react-router-dom\": \"^7.0.0\""},
        {"state", framework == "vue-vite"
            ? "\"pinia\": \"^3.0.0\""
            : "\"zustand\": \"^5.0.0\""}
    };
    const QMap<QString, QString> dev {
        {"cors", "\"@types/cors\": \"^2.8.17\""},
        {"morgan", "\"@types/morgan\": \"^1.9.9\""}
    };
    QString result;
    for (const QString &item : items) {
        const QString entry = development ? dev.value(item) : production.value(item);
        if (!entry.isEmpty())
            result += ",\n    " + entry;
    }
    return result;
}

bool copyResourceTree(const QString &resourceRoot, const QDir &destination,
                      const QHash<QString, QString> &variables)
{
    QDirIterator files(resourceRoot, QDir::Files | QDir::Hidden,
                       QDirIterator::Subdirectories);
    while (files.hasNext()) {
        const QString resourcePath = files.next();
        QString relative = resourcePath.mid(resourceRoot.size() + 1);
        for (auto it = variables.cbegin(); it != variables.cend(); ++it)
            relative.replace(it.key(), it.value());
        // Templates ship with fixed paths. Defensive check for future additions.
        if (relative.startsWith('/') || relative.contains('\\')
            || relative.split('/').contains("..") || relative.split('/').contains("."))
            return false;
        QFile source(resourcePath);
        if (!source.open(QIODevice::ReadOnly))
            return false;
        QString contents = QString::fromUtf8(source.readAll());
        for (auto it = variables.cbegin(); it != variables.cend(); ++it)
            contents.replace(it.key(), it.value());
        if (!writeNewFile(destination, relative, contents.toUtf8()))
            return false;
    }
    return true;
}

bool validatePackage(const QString &name)
{
    const QRegularExpression pattern(
        QStringLiteral("^[a-z][a-z0-9]*(\\.[a-z][a-z0-9]*)+$"));
    return pattern.match(name).hasMatch();
}

}

QStringList ProjectScaffolder::supportedFrameworks()
{
    QStringList frameworks;
    for (const auto &id : frameworkKinds().keys()) {
        if (QDir(":/project-templates/" + id + "/common").exists())
            frameworks.append(id);
    }
    return frameworks;
}

ProjectScaffolder::Result ProjectScaffolder::create(const QVariantMap &options)
{
    Result result;
    const QString name = options.value("name").toString().trimmed();
    const QUrl parentUrl = options.value("parentFolder").toUrl();
    result.framework = options.value("framework").toString().trimmed().toLower();
    result.kind = frameworkKinds().value(result.framework);
    result.architecture = options.value("architecture").toString();
    result.packageName = options.value("packageName").toString().trimmed();
    const QRegularExpression safeName(QStringLiteral("^[a-z][a-z0-9_-]{0,63}$"));
    if (!safeName.match(name).hasMatch()) {
        result.error = "Project name must start with a lowercase letter and use only a-z, 0-9, _ or -.";
        return result;
    }
    if (!parentUrl.isLocalFile() || parentUrl.toLocalFile().isEmpty()) {
        result.error = "Select a local parent folder.";
        return result;
    }
    const QDir parent(parentUrl.toLocalFile());
    if (!parent.exists()) {
        result.error = "The selected parent folder does not exist.";
        return result;
    }
    if (result.kind.isEmpty()) {
        result.error = "Unsupported project framework: " + result.framework;
        return result;
    }
    const QStringList allowedArchitectures = result.framework == "spring-boot"
        || result.framework == "express-ts"
        ? QStringList{"layered", "feature-based"}
        : QStringList{"standard", "feature-based"};
    if (!allowedArchitectures.contains(result.architecture)) {
        result.error = "Unsupported architecture for this framework.";
        return result;
    }
    if (result.framework == "spring-boot" && !validatePackage(result.packageName)) {
        result.error = "Java package must be dotted lowercase, e.g. com.example.demo.";
        return result;
    }
    const QString javaVersion = options.value("javaVersion", "17").toString();
    if (result.framework == "spring-boot" && javaVersion != "17" && javaVersion != "21") {
        result.error = "Supported Java versions are 17 and 21.";
        return result;
    }

    const QMap<QString, QStringList> allowedExtras {
        {"react-vite", {"router", "axios", "state"}},
        {"vue-vite", {"router", "axios", "state"}},
        {"html", {}},
        {"next-js", {}},
        {"express-ts", {"cors", "helmet", "morgan"}},
        {"spring-boot", {"security", "validation", "actuator", "data-jpa", "postgresql", "h2", "devtools", "cache"}}
    };
    QSet<QString> seen;
    for (const QVariant &value : options.value("dependencies").toList()) {
        const QString dep = value.toString();
        if (!allowedExtras.value(result.framework).contains(dep)) {
            result.error = "Unsupported dependency selected: " + dep;
            return result;
        }
        if (!seen.contains(dep)) {
            result.dependencies.append(dep);
            seen.insert(dep);
        }
    }

    const int serverPort = options.value("serverPort",
        result.framework == "spring-boot" ? 8080 : 3000).toInt();
    if (result.kind == "backend" && (serverPort < 1024 || serverPort > 65535)) {
        result.error = "Server port must be between 1024 and 65535.";
        return result;
    }
    result.projectPath = parent.absoluteFilePath(name);
    if (QFileInfo::exists(result.projectPath) || QFileInfo(result.projectPath).isSymLink()) {
        result.error = "A project with this name already exists in the destination.";
        return result;
    }
    if (!parent.mkdir(name)) {
        result.error = "Cannot create the project directory. Check permissions.";
        return result;
    }
    QDir project(result.projectPath);
    const QHash<QString, QString> values {
        {"__NAME__", name},
        {"__PACKAGE__", result.packageName},
        {"__PACKAGE_PATH__", javaPackagePath(result.packageName)},
        {"__JAVA_VERSION__", javaVersion},
        {"__CLASS_NAME__", toJavaClass(name)},
        {"__SPRING_DEPENDENCIES__", springDependencyXml(result.dependencies)},
        {"__JS_EXTRAS__", javascriptExtras(result.framework, result.dependencies, false)},
        {"__JS_DEV_EXTRAS__", javascriptExtras(result.framework, result.dependencies, true)},
        {"__SERVER_PORT__", QString::number(serverPort)},
        {"__DESCRIPTION__", options.value("description").toString().trimmed()},
        {"__CORS_IMPORT__", result.dependencies.contains("cors")
             ? "import cors from \"cors\";" : ""},
        {"__CORS_USE__", result.dependencies.contains("cors")
             ? "app.use(cors({ origin: process.env.CORS_ORIGIN || \"http://localhost:5173\" }));" : ""},
        {"__HELMET_IMPORT__", result.dependencies.contains("helmet") ? "import helmet from \"helmet\";" : ""},
        {"__HELMET_USE__", result.dependencies.contains("helmet") ? "app.use(helmet());" : ""},
        {"__MORGAN_IMPORT__", result.dependencies.contains("morgan") ? "import morgan from \"morgan\";" : ""},
        {"__MORGAN_USE__", result.dependencies.contains("morgan") ? "app.use(morgan(\"dev\"));" : ""},
        {"__HEALTH_IMPORT__", result.architecture == "layered"
             ? "routes/health" : "features/health/routes"}
    };
    const QString templateRoot = ":/project-templates/" + result.framework;
    const QString common = templateRoot + "/common";
    const QString architecture = templateRoot + "/architectures/" + result.architecture;
    if (!QDir(common).exists()
        || !copyResourceTree(common, project, values)
        || (QDir(architecture).exists()
            && !copyResourceTree(architecture, project, values))) {
        project.removeRecursively(); // Only the directory created above.
        result.error = "Could not populate the new project from its templates.";
        return result;
    }
    // Common folders for future components. Files are added only on installation.
    const QString packageFolder = "src/main/java/" + javaPackagePath(result.packageName);
    if (result.framework == "spring-boot") {
        project.mkpath(packageFolder + "/security");
        project.mkpath(packageFolder + (result.architecture == "layered"
            ? "/service" : "/features"));
    } else if (result.framework == "express-ts") {
        project.mkpath("src/middleware");
    } else if (result.kind == "frontend") {
        project.mkpath(result.architecture == "feature-based"
            ? "src/features" : "src/components");
    }

    QJsonObject metadata {
        {"schemaVersion", 1},
        {"name", name},
        {"kind", result.kind},
        {"framework", result.framework},
        {"architecture", result.architecture},
        {"packageName", result.framework == "spring-boot" ? result.packageName : ""},
        {"javaVersion", result.framework == "spring-boot" ? javaVersion : ""},
        {"serverPort", result.kind == "backend" ? serverPort : 0},
        {"description", options.value("description").toString().trimmed()},
        {"dependencies", QJsonArray::fromStringList(result.dependencies)}
    };
    if (!project.mkpath(".jeridi")
        || !writeNewFile(project, ".jeridi/project.json",
                         QJsonDocument(metadata).toJson(QJsonDocument::Indented))) {
        project.removeRecursively();
        result.error = "Could not save project metadata.";
        return result;
    }

    if (options.value("initializeGit").toBool()) {
        QProcess git;
        git.setWorkingDirectory(result.projectPath);
        git.start("git", {"init", "--quiet"});
        if (git.waitForStarted(3000) && git.waitForFinished(5000)
            && git.exitStatus() == QProcess::NormalExit && git.exitCode() == 0)
            result.gitInitialized = true;
    }
    return result;
}

QVariantMap ProjectScaffolder::detect(const QString &projectPath)
{
    const QDir root(projectPath);
    QFile metadata(root.filePath(".jeridi/project.json"));
    if (metadata.open(QIODevice::ReadOnly)) {
        const auto document = QJsonDocument::fromJson(metadata.readAll());
        if (document.isObject()) {
            const auto obj = document.object();
            const QString framework = obj.value("framework").toString();
            if (frameworkKinds().value(framework) == obj.value("kind").toString()
                && obj.value("schemaVersion").toInt() == 1)
                return obj.toVariantMap();
        }
    }
    if (QFileInfo::exists(root.filePath("pom.xml"))) {
        // Treat externally created Maven projects conservatively.
        QFile pom(root.filePath("pom.xml"));
        if (pom.open(QIODevice::ReadOnly)) {
            const QByteArray xml = pom.readAll();
            if (xml.contains("spring-boot")) {
                QStringList dependencies;
                if (xml.contains("<artifactId>spring-boot-starter-security</artifactId>")
                    && xml.contains("<artifactId>spring-boot-starter-oauth2-resource-server</artifactId>"))
                    dependencies.append("security");
                if (xml.contains("<artifactId>spring-boot-starter-data-jpa</artifactId>"))
                    dependencies.append("data-jpa");
                if (xml.contains("<artifactId>spring-boot-starter-validation</artifactId>"))
                    dependencies.append("validation");
                QString packageName;
                const QString sourceRoot = root.filePath("src/main/java");
                QDirIterator javaFiles(sourceRoot, {"*.java"}, QDir::Files | QDir::NoSymLinks,
                                       QDirIterator::Subdirectories);
                while (javaFiles.hasNext()) {
                    QFile source(javaFiles.next());
                    if (source.size() > 128 * 1024 || !source.open(QIODevice::ReadOnly)
                        || !source.readAll().contains("@SpringBootApplication"))
                        continue;
                    QString candidate = QDir(sourceRoot).relativeFilePath(QFileInfo(source).path());
                    candidate.replace('/', '.');
                    if (!validatePackage(candidate))
                        continue;
                    if (!packageName.isEmpty() && packageName != candidate) {
                        packageName.clear();
                        break;
                    }
                    packageName = candidate;
                }
                return {{"kind", "backend"}, {"framework", "spring-boot"},
                        {"architecture", "layered"}, {"dependencies", dependencies},
                        {"packageName", packageName}};
            }
        }
    }
    if (QFileInfo::exists(root.filePath("package.json"))) {
        QFile pkg(root.filePath("package.json"));
        if (pkg.open(QIODevice::ReadOnly)) {
            const auto d = QJsonDocument::fromJson(pkg.readAll());
            const auto deps = d.object().value("dependencies").toObject();
            const auto dev = d.object().value("devDependencies").toObject();
            if (deps.contains("next") || dev.contains("next"))
                return {{"kind", "frontend"}, {"framework", "next-js"},
                        {"architecture", "standard"}};
            if (deps.contains("react") && dev.contains("vite"))
                return {{"kind", "frontend"}, {"framework", "react-vite"},
                        {"architecture", "standard"}};
            if (deps.contains("vue") && dev.contains("vite"))
                return {{"kind", "frontend"}, {"framework", "vue-vite"},
                        {"architecture", "standard"}};
            if (deps.contains("express"))
                return {{"kind", "backend"}, {"framework", "express-ts"},
                        {"architecture", "layered"}};
        }
        return {{"kind", "frontend"}, {"framework", "unknown"},
                {"architecture", "standard"}};
    }
    if (QFileInfo::exists(root.filePath("index.html")))
        return {{"kind", "frontend"}, {"framework", "html"},
                {"architecture", "standard"}};
    return {};
}

bool ProjectScaffolder::compatible(const QString &projectPath, const QVariantMap &definition)
{
    const QString framework = detect(projectPath).value("framework").toString();
    const QStringList supported = definition.value("frameworks").toStringList();
    return !framework.isEmpty() && supported.contains(framework);
}

QString ProjectScaffolder::suggestedDirectory(const QString &projectPath,
                                               const QVariantMap &definition)
{
    const QVariantMap profile = detect(projectPath);
    const QString framework = profile.value("framework").toString();
    const QString preferred = definition.value("defaultDirectory").toString();
    if (!preferred.isEmpty()) {
        if (framework == "react-vite" && definition.contains("viteFiles"))
            return "src/components/colly/" + QFileInfo(preferred).fileName();
        if (framework == "next-js" && preferred.startsWith("src/app/")
            && !QDir(QDir(projectPath).filePath("src/app")).exists()
            && QDir(QDir(projectPath).filePath("app")).exists())
            return preferred.mid(4);
        return preferred;
    }
    if (framework == "spring-boot") {
        const QString name = profile.value("packageName").toString();
        if (validatePackage(name))
            return "src/main/java/" + javaPackagePath(name);
        return "src/main/java";
    }
    if (framework == "express-ts")
        return "src";
    if (profile.value("architecture").toString() == "feature-based") {
        if (framework == "html")
            return "features/shared";
        if (framework == "react-vite" || framework == "vue-vite")
            return "src/features/shared/components";
    }
    if (framework == "html")
        return "components";
    return definition.value("legacyDirectory").toString().isEmpty()
        ? QStringLiteral("src/components")
        : definition.value("legacyDirectory").toString();
}
