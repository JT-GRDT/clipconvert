import Foundation
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

    mutating func visitUnorderedList(_ list: UnorderedList) {
        html += "<ul>"
        descendInto(list)
        html += "</ul>"
    }

    mutating func visitOrderedList(_ list: OrderedList) {
        if list.startIndex != 1 {
            html += "<ol start=\"\(list.startIndex)\">"
        } else {
            html += "<ol>"
        }
        descendInto(list)
        html += "</ol>"
    }

    mutating func visitListItem(_ listItem: ListItem) {
        html += "<li>"
        descendInto(listItem)
        html += "</li>"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        html += "<blockquote>"
        descendInto(blockQuote)
        html += "</blockquote>"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        // No descendInto: a code block's content is a plain string.
        html += "<pre><code>" + escapeHTML(codeBlock.code) + "</code></pre>"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        html += "<hr>"
    }

    mutating func visitTable(_ table: Markdown.Table) {
        html += "<table border=\"1\" cellspacing=\"0\" cellpadding=\"4\">"
        descendInto(table)
        html += "</table>"
    }

    mutating func visitTableHead(_ head: Markdown.Table.Head) {
        // Head holds cells directly, so the row wrapper is added here.
        html += "<thead><tr>"
        descendInto(head)
        html += "</tr></thead>"
    }

    mutating func visitTableBody(_ body: Markdown.Table.Body) {
        html += "<tbody>"
        descendInto(body)
        html += "</tbody>"
    }

    mutating func visitTableRow(_ row: Markdown.Table.Row) {
        html += "<tr>"
        descendInto(row)
        html += "</tr>"
    }

    mutating func visitTableCell(_ cell: Markdown.Table.Cell) {
        let tag = cell.parent is Markdown.Table.Head ? "th" : "td"
        html += "<\(tag)>"
        descendInto(cell)
        html += "</\(tag)>"
    }

    mutating func visitHTMLBlock(_ htmlBlock: HTMLBlock) {
        // No descendInto: raw HTML has no child markup to walk.
        html += renderedRawHTML(htmlBlock.rawHTML)
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
        // No descendInto: raw HTML has no child markup to walk.
        html += renderedRawHTML(inlineHTML.rawHTML)
    }
}

/// Render a raw HTML fragment from the source Markdown.
///
/// `<br>` is GFM's only way to force a line break inside constructs like
/// table cells, and chatbots emit it, so it is passed through as an actual
/// break. Everything else is escaped and shown as visible literal text:
/// we cannot vouch for arbitrary HTML flowing into `NSAttributedString`
/// on the Mac side, but silently dropping it is the one failure mode the
/// spec rules out entirely. Showing the markup as text loses nothing.
private func renderedRawHTML(_ rawText: String) -> String {
    let normalized = rawText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if normalized == "<br>" || normalized == "<br/>" || normalized == "<br />" {
        return "<br>"
    }
    return escapeHTML(rawText)
}

/// Convert Markdown source into HTML suitable for the macOS pasteboard.
///
/// The result is a UTF-8 encoded HTML fragment (no `<html>`/`<body>`
/// wrapper, no `<meta charset>`). A consumer that turns it into an
/// `NSAttributedString` via `NSAttributedString(data:options:)` MUST pass
/// both `.documentType: .html` and
/// `.characterEncoding: String.Encoding.utf8.rawValue` in the options
/// dictionary. Without an explicit encoding, `NSAttributedString` guesses
/// at the byte encoding, and most real fixtures contain non-ASCII
/// characters (em dashes, curly quotes, currency symbols) that a wrong
/// guess turns into mojibake.
public func markdownToHTML(_ markdown: String) -> String {
    let document = Document(parsing: markdown)
    var renderer = HTMLRenderer()
    renderer.visit(document)
    return renderer.html
}
