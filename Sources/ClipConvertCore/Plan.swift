import Foundation

/// Why a conversion was declined.
public enum SkipReason: Equatable {
    /// The pasteboard already carries an HTML flavor.
    case alreadyRich
    /// No convincing Markdown structure was found.
    case noMarkdownFound
    /// Nothing on the pasteboard but whitespace.
    case empty
}

/// What the shell should do with the pasteboard.
public enum ClipboardAction: Equatable {
    case convert(html: String)
    case skip(reason: SkipReason)
}

/// Decide what to do with the current pasteboard contents.
///
/// The AppKit shell calls this and obeys the result. No decision logic
/// lives in the shell, so the only untested code is the pasteboard I/O
/// itself.
///
/// - Parameters:
///   - plainText: the `public.utf8-plain-text` flavor.
///   - hasHTMLFlavor: whether `public.html` is also present.
public func plan(plainText: String, hasHTMLFlavor: Bool) -> ClipboardAction {
    if hasHTMLFlavor {
        return .skip(reason: .alreadyRich)
    }

    let trimmed = plainText.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
        return .skip(reason: .empty)
    }

    guard shouldConvert(plainText) else {
        return .skip(reason: .noMarkdownFound)
    }

    return .convert(html: markdownToHTML(plainText))
}
