import Markdown

/// Walks a parsed Markdown document and accumulates HTML.
///
/// Every `visit` method that emits a wrapping tag must call
/// `descendInto` between the opening and closing tag, or the element's
/// children are silently dropped.
struct HTMLRenderer: MarkupWalker {
    var html = ""

    mutating func defaultVisit(_ markup: any Markup) {
        descendInto(markup)
    }

    mutating func visitText(_ text: Markdown.Text) {
        html += escapeHTML(text.string)
    }

    mutating func visitHeading(_ heading: Heading) {
        html += "<h\(heading.level)>"
        descendInto(heading)
        html += "</h\(heading.level)>"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) {
        html += "<p>"
        descendInto(paragraph)
        html += "</p>"
    }

    mutating func visitStrong(_ strong: Strong) {
        html += "<strong>"
        descendInto(strong)
        html += "</strong>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        html += "<em>"
        descendInto(emphasis)
        html += "</em>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        // No descendInto: inline code has no child markup.
        html += "<code>" + escapeHTML(inlineCode.code) + "</code>"
    }

    mutating func visitLink(_ link: Markdown.Link) {
        let destination = escapeHTML(link.destination ?? "")
        html += "<a href=\"\(destination)\">"
        descendInto(link)
        html += "</a>"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        html += " "
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        html += "<br>"
    }
}

/// Convert Markdown source into HTML suitable for the macOS pasteboard.
public func markdownToHTML(_ markdown: String) -> String {
    let document = Document(parsing: markdown)
    var renderer = HTMLRenderer()
    renderer.visit(document)
    return renderer.html
}
