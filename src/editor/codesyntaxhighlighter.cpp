#include "codesyntaxhighlighter.h"

#include <QFileInfo>

CodeSyntaxHighlighter::CodeSyntaxHighlighter(QObject *parent)
    : QSyntaxHighlighter(parent)
{
}

CodeSyntaxHighlighter::Language
CodeSyntaxHighlighter::languageForFile(const QString &fileName)
{
    const QString suffix = QFileInfo(fileName).suffix().toLower();

    if (suffix == "ts" || suffix == "tsx"
        || suffix == "js" || suffix == "jsx") {
        return Language::Script;
    }

    if (suffix == "json")
        return Language::Json;

    if (suffix == "css")
        return Language::Css;

    if (suffix == "html")
        return Language::Html;

    return Language::PlainText;
}

void CodeSyntaxHighlighter::configure(QQuickTextDocument *quickDocument,
                                      const QString &fileName,
                                      bool dark)
{
    m_language = languageForFile(fileName);

    m_keywordColor = QColor(dark ? "#C792EA" : "#7336A1");
    m_stringColor  = QColor(dark ? "#A5C76B" : "#367016");
    m_numberColor  = QColor(dark ? "#F0A66B" : "#9C4A10");
    m_nameColor    = QColor(dark ? "#82AAFF" : "#1957A6");
    m_commentColor = QColor(dark ? "#9298A5" : "#596474");

    QTextDocument *target = quickDocument ? quickDocument->textDocument() : nullptr;

    if (document() != target)
        setDocument(target);

    rehighlight();
}

void CodeSyntaxHighlighter::highlightBlock(const QString &text)
{
    // Each match is classified by its named group.
    static const QRegularExpression script(QStringLiteral(
        R"rx((?<comment>//.*|/\*.*?\*/)|(?<string>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)|(?<keyword>\b(?:import|export|from|default|const|let|function|return|type|interface|async|await|if|else|new|true|false|null|undefined)\b)|(?<name>(?<=<)/?[A-Za-z][\w.:-]*)|(?<number>\b\d+(?:\.\d+)?\b))rx"
        ));

    static const QRegularExpression json(QStringLiteral(
        R"rx((?<name>"(?:\\.|[^"\\])*"(?=\s*:))|(?<string>"(?:\\.|[^"\\])*")|(?<keyword>\b(?:true|false|null)\b)|(?<number>-?\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b))rx"
        ));

    static const QRegularExpression css(QStringLiteral(
        R"rx((?<comment>/\*.*?\*/)|(?<string>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')|(?<keyword>@[\w-]+)|(?<name>[\w-]+(?=\s*:))|(?<number>#[0-9a-fA-F]{3,8}\b|\b\d+(?:\.\d+)?(?:px|rem|em|ms|s|%)?))rx"
        ));

    static const QRegularExpression html(QStringLiteral(
        R"rx((?<comment><!--.*?-->)|(?<string>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')|(?<name>(?<=<)/?[A-Za-z][\w:-]*)|(?<keyword>[\w:-]+(?=\s*=)))rx"
        ));

    const QRegularExpression *pattern = nullptr;

    switch (m_language) {
    case Language::Script: pattern = &script; break;
    case Language::Json:   pattern = &json;   break;
    case Language::Css:    pattern = &css;    break;
    case Language::Html:   pattern = &html;   break;
    case Language::PlainText:
        return;
    }

    auto matches = pattern->globalMatch(text);

    while (matches.hasNext()) {
        const auto match = matches.next();
        QColor color = m_nameColor;

        if (match.capturedStart("comment") >= 0)
            color = m_commentColor;
        else if (match.capturedStart("string") >= 0)
            color = m_stringColor;
        else if (match.capturedStart("keyword") >= 0)
            color = m_keywordColor;
        else if (match.capturedStart("number") >= 0)
            color = m_numberColor;

        setFormat(match.capturedStart(), match.capturedLength(), color);
    }
}