import Markdown

/// Number of top-level blocks in a Markdown document.
/// Exists to prove the swift-markdown dependency links and parses correctly.
func parsedBlockCount(_ markdown: String) -> Int {
    let document = Document(parsing: markdown)
    return document.childCount
}

/// Whether the first top-level block parses as a GFM table.
/// Exists to prove the table extension is enabled — the one parser
/// capability the product cannot ship without.
func firstBlockIsTable(_ markdown: String) -> Bool {
    let document = Document(parsing: markdown)
    return document.child(at: 0) is Markdown.Table
}
