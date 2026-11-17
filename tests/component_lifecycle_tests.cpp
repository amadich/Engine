#include "componentlifecycle.h"
#include "componentinstallationstore.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTemporaryDir>
#include <QtTest/QtTest>

namespace {
bool writeFile(const QString &project, const QString &relative, const QByteArray &bytes)
{
    const QDir root(project);
    if (!root.mkpath(QFileInfo(relative).path()))
        return false;
    QFile file(root.filePath(relative));
    return file.open(QIODevice::WriteOnly) && file.write(bytes) == bytes.size();
}

QByteArray readFile(const QString &project, const QString &relative)
{
    QFile file(QDir(project).filePath(relative));
    return file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray();
}

QVariantMap navbarDefinition()
{
    return {{"name", "Navbar"},
            {"configTarget", "navbar.config.json"},
            {"files", QVariantList{
                QVariantMap{{"source", "template/EngineNavbar.tsx"}, {"target", "EngineNavbar.tsx"}},
                QVariantMap{{"source", "template/navbar.config.json"}, {"target", "navbar.config.json"}}
            }}};
}

bool prepareNavbar(const QString &project, const QString &folder)
{
    return writeFile(project, "package.json", "{\"name\":\"test-project\"}\n")
        && writeFile(project, folder + "/EngineNavbar.tsx",
                     "import config from './navbar.config.json'\nexport default config\n")
        && writeFile(project, folder + "/navbar.config.json", "{\"brand\":\"Demo\"}\n")
        && ComponentInstallationStore::record(project, "navbar", folder,
                                              navbarDefinition()).isEmpty();
}
}

class ComponentLifecycleTests : public QObject
{
    Q_OBJECT
private slots:
    void moveUpdatesImportsAndRemovesEmptySource();
    void movePreservesUnrelatedFiles();
    void moveRejectsDestinationCollision();
    void removalBlocksReferencesAndArchivesFiles();
};

void ComponentLifecycleTests::moveUpdatesImportsAndRemovesEmptySource()
{
    QTemporaryDir temp;
    QVERIFY(temp.isValid());
    const QString project = temp.path();
    QVERIFY(prepareNavbar(project, "src/components/navbar"));
    QVERIFY(writeFile(project, "src/App.tsx",
                      "import Navbar from './components/navbar/EngineNavbar'\n"));

    const QVariantMap preview = ComponentLifecycle::previewMove(
        project, "navbar", navbarDefinition(), "src/components/navbar", "src/ui/navigation");
    QCOMPARE(preview.value("error").toString(), QString());
    QCOMPARE(preview.value("files").toStringList().size(), 2);
    QCOMPARE(preview.value("references").toStringList().size(), 1);

    QString cleanup;
    QCOMPARE(ComponentLifecycle::move(project, "navbar", navbarDefinition(),
                                     "src/components/navbar", "src/ui/navigation", &cleanup),
             QString());
    QVERIFY(cleanup.isEmpty());
    QVERIFY(!QFileInfo(QDir(project).filePath("src/components/navbar")).exists());
    QVERIFY(QFileInfo(QDir(project).filePath("src/ui/navigation/EngineNavbar.tsx")).isFile());
    QVERIFY(readFile(project, "src/App.tsx")
                .contains("./ui/navigation/EngineNavbar"));
    QCOMPARE(ComponentInstallationStore::find(project, "navbar")
                 .value("directory").toString(), QString("src/ui/navigation"));
}

void ComponentLifecycleTests::movePreservesUnrelatedFiles()
{
    QTemporaryDir temp;
    QVERIFY(temp.isValid());
    const QString project = temp.path();
    QVERIFY(prepareNavbar(project, "src/components/navbar"));
    QVERIFY(writeFile(project, "src/components/navbar/KEEP_ME.txt", "USER DATA"));

    QString cleanup;
    QCOMPARE(ComponentLifecycle::move(project, "navbar", navbarDefinition(),
                                     "src/components/navbar", "src/widgets", &cleanup),
             QString());
    QVERIFY(!cleanup.isEmpty());
    QCOMPARE(readFile(project, "src/components/navbar/KEEP_ME.txt"), QByteArray("USER DATA"));
    QVERIFY(QFileInfo(QDir(project).filePath("src/components/navbar")).isDir());
}

void ComponentLifecycleTests::moveRejectsDestinationCollision()
{
    QTemporaryDir temp;
    QVERIFY(temp.isValid());
    const QString project = temp.path();
    QVERIFY(prepareNavbar(project, "src/components/navbar"));
    QVERIFY(writeFile(project, "src/new/EngineNavbar.tsx", "USER CODE"));

    QVERIFY(!ComponentLifecycle::previewMove(project, "navbar", navbarDefinition(),
                     "src/components/navbar", "src/new").value("error").toString().isEmpty());
    QVERIFY(!ComponentLifecycle::move(project, "navbar", navbarDefinition(),
                                     "src/components/navbar", "src/new").isEmpty());
    QCOMPARE(readFile(project, "src/new/EngineNavbar.tsx"), QByteArray("USER CODE"));
    QVERIFY(QFileInfo(QDir(project).filePath("src/components/navbar/EngineNavbar.tsx")).isFile());
}

void ComponentLifecycleTests::removalBlocksReferencesAndArchivesFiles()
{
    QTemporaryDir temp;
    QVERIFY(temp.isValid());
    const QString project = temp.path();
    QVERIFY(prepareNavbar(project, "src/components/navbar"));
    QVERIFY(writeFile(project, "src/App.tsx",
                      "import Navbar from './components/navbar/EngineNavbar'\n"));

    QVERIFY(!ComponentLifecycle::previewRemove(project, "navbar", navbarDefinition(),
                     "src/components/navbar").value("error").toString().isEmpty());
    QVERIFY(!ComponentLifecycle::remove(project, "navbar", navbarDefinition(),
                                       "src/components/navbar", nullptr).isEmpty());
    QVERIFY(QFileInfo(QDir(project).filePath("src/components/navbar/EngineNavbar.tsx")).isFile());

    QVERIFY(writeFile(project, "src/App.tsx", "export default function App() { return null }\n"));
    QString recovery;
    QString cleanup;
    QCOMPARE(ComponentLifecycle::remove(project, "navbar", navbarDefinition(),
                                        "src/components/navbar", &recovery, &cleanup), QString());
    QVERIFY(recovery.startsWith(".jeridiengine/trash/navbar-"));
    QVERIFY(QFileInfo(QDir(project).filePath(recovery + "/EngineNavbar.tsx")).isFile());
    QVERIFY(!QFileInfo(QDir(project).filePath("src/components/navbar")).exists());
    QVERIFY(ComponentInstallationStore::find(project, "navbar").isEmpty());
}

QTEST_GUILESS_MAIN(ComponentLifecycleTests)
#include "component_lifecycle_tests.moc"
