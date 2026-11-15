#ifndef CODESYNTAXHIGHLIGHTER_H
#define CODESYNTAXHIGHLIGHTER_H

#include <QColor>
#include <QQuickTextDocument>
#include <QRegularExpression>
#include <QSyntaxHighlighter>
#include <QtQml/qqmlregistration.h>

class CodeSyntaxHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit CodeSyntaxHighlighter(QObject *parent = nullptr);

    Q_INVOKABLE void configure(QQuickTextDocument *document,
                               const QString &fileName,
                               bool dark);

protected:
    void highlightBlock(const QString &text) override;

private:
    enum class Language { PlainText, Script, Json, Css, Html };

    static Language languageForFile(const QString &fileName);

    Language m_language = Language::PlainText;
    QColor m_keywordColor;
    QColor m_stringColor;
    QColor m_numberColor;
    QColor m_nameColor;
    QColor m_commentColor;
};

#endif