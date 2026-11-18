#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QtWebView/QtWebView>

int main(int argc, char *argv[])
{
    QtWebView::initialize();

    QQuickStyle::setStyle("Basic");
    QCoreApplication::setAttribute(Qt::AA_DontUseNativeMenuBar);
    QGuiApplication app(argc, argv);

    // Application Identity
    QCoreApplication::setOrganizationName("Jeridi");
    QCoreApplication::setOrganizationDomain("jeridi.dev");
    QCoreApplication::setApplicationName("JeridiEngine");

    QCoreApplication::setApplicationVersion("0.5.0");

    QQmlApplicationEngine engine;

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );

    engine.loadFromModule("JeridiEngine", "Main");
    return app.exec();
}
