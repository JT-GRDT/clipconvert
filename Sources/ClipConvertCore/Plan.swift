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

public extension SkipReason {
    /// Short, user-facing text explaining why nothing happened. Intended
    /// for the notification the shell shows after a no-op paste.
    var message: String {
        switch self {
        case .alreadyRich:
            return "Clipboard already has formatting — left unchanged."
        case .noMarkdownFound:
            return "No Markdown found — clipboard left unchanged."
        case .empty:
            return "Clipboard is empty."
        }
    }
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
///   - force: bypasses only the `shouldConvert` heuristic (the "Force
///     Convert" menu item). It never bypasses the `alreadyRich` or
///     `empty` checks: converting already-rich content can only destroy
///     formatting the user already has, and there is nothing to convert
///     in an empty clipboard, so forcing past either would either harm
///     the user or do nothing.
public func plan(
    plainText: String,
    hasHTMLFlavor: Bool,
    force: Bool = false
) -> ClipboardAction {
    if hasHTMLFlavor {
        return .skip(reason: .alreadyRich)
    }

    let trimmed = plainText.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
        return .skip(reason: .empty)
    }

    guard force || shouldConvert(plainText) else {
        return .skip(reason: .noMarkdownFound)
    }

    return .convert(html: markdownToHTML(plainText))
}
