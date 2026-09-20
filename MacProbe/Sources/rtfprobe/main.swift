import AppKit

// A deliberately representative sample: a table with a header row,
// inline code inside a cell, bold text, a heading and a list, plus
// three labelled sections covering the "Additional checks" in
// docs/paste-checklist.md (a line break inside a table cell, a tight
// bullet list, and a line of non-ASCII characters).
let html = """
<h2>Quarterly results</h2>
<p>Revenue was <strong>up 12%</strong> against forecast.</p>
<table border="1" cellspacing="0" cellpadding="4">
  <thead><tr><th>Region</th><th>Revenue</th><th>Flag</th></tr></thead>
  <tbody>
    <tr><td>EMEA</td><td>€1.2M</td><td><code>--eu</code></td></tr>
    <tr><td>APAC</td><td>€0.8M</td><td><code>--apac</code></td></tr>
  </tbody>
</table>
<ul><li>First point</li><li>Second point</li></ul>

<h3>Line break in a table cell</h3>
<table border="1" cellspacing="0" cellpadding="4">
  <tbody>
    <tr><td>first line<br>second line</td></tr>
  </tbody>
</table>

<h3>Tight bullet list</h3>
<ul><li>one</li><li>two</li><li>three</li></ul>

<h3>Non-ASCII characters</h3>
<p>The price went up — it's now €12, not what we'd hoped.</p>
"""

guard let data = html.data(using: .utf8) else {
    print("FAIL: could not encode HTML as UTF-8")
    exit(1)
}

let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
    .documentType: NSAttributedString.DocumentType.html,
    .characterEncoding: String.Encoding.utf8.rawValue
]

guard let attributed = try? NSAttributedString(
    data: data,
    options: options,
    documentAttributes: nil
) else {
    print("FAIL: NSAttributedString(html:) returned nil or threw")
    exit(1)
}

let fullRange = NSRange(location: 0, length: attributed.length)

guard let rtf = attributed.rtf(
    from: fullRange,
    documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
) else {
    print("FAIL: could not produce RTF")
    exit(1)
}

let pasteboard = NSPasteboard.general
pasteboard.clearContents()
pasteboard.setData(rtf, forType: .rtf)
pasteboard.setString(html, forType: .html)
pasteboard.setString(attributed.string, forType: .string)

print("OK: wrote RTF (\(rtf.count) bytes), HTML and plain text to the clipboard.")
print("Now paste into each app in docs/paste-checklist.md and record what you see.")
