import Foundation

/// Which Markdown features were spotted in a block of text.
public struct MarkdownSignals: Equatable {
    public var tableDelimiter = false
    public var fence = false
    public var heading = false
    public var unorderedList = false
    public var orderedList = false
    public var blockQuote = false
    public var bold = false
    public var link = false

    public init() {}
}

/// Matches `pattern` anywhere in `text`. Returns false if the pattern
/// itself is invalid, so a bad regex can never cause a conversion.
func matches(_ pattern: String, _ text: String) -> Bool {
    guard let regex = try? NSRegularExpression(
        pattern: pattern,
        options: [.anchorsMatchLines]
    ) else {
        return false
    }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return regex.firstMatch(in: text, options: [], range: range) != nil
}

/// Inspect `text` for Markdown features. Purely descriptive — the
/// decision of what to do with the signals lives in `shouldConvert`.
public func detectSignals(_ text: String) -> MarkdownSignals {
    var signals = MarkdownSignals()

    // A table delimiter row needs at least two columns, which is what
    // separates it from a horizontal rule.
    signals.tableDelimiter = matches(
        #"^ {0,3}\|?[ \t]*:?-{1,}:?[ \t]*(\|[ \t]*:?-{1,}:?[ \t]*)+\|?[ \t]*$"#,
        text
    )
    signals.fence = matches(#"^ {0,3}(```|~~~)"#, text)
    signals.heading = matches(#"^ {0,3}#{1,6}[ \t]+\S"#, text)
    signals.unorderedList = matches(#"^ {0,3}[-*+][ \t]+\S"#, text)
    signals.orderedList = matches(#"^ {0,3}\d{1,9}[.)][ \t]+\S"#, text)
    signals.blockQuote = matches(#"^ {0,3}>[ \t]?\S"#, text)

    // Inline signals, restricted to the two that are rare in source code.
    signals.bold = matches(#"\*\*[^*\n]+\*\*"#, text)
    signals.link = matches(#"\[[^\]\n]+\]\([^)\s]+\)"#, text)

    return signals
}

public extension MarkdownSignals {
    /// Signals that only Markdown produces. Sufficient on their own.
    var hasStrong: Bool { tableDelimiter || fence }

    /// Block structure that other formats also produce (YAML, shell, code).
    var hasBlock: Bool {
        heading || unorderedList || orderedList || blockQuote
    }

    /// Inline formatting that is rare outside Markdown.
    var hasInline: Bool { bold || link }
}

/// Whether clipboard text is Markdown worth converting.
///
/// Conservative by design: a strong signal converts on its own, but weak
/// block structure must be corroborated by inline formatting. A missed
/// conversion is a minor annoyance; converting someone's source code is
/// the failure that gets the app uninstalled.
public func shouldConvert(_ text: String) -> Bool {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return false }

    let signals = detectSignals(trimmed)
    if signals.hasStrong { return true }
    return signals.hasBlock && signals.hasInline
}
