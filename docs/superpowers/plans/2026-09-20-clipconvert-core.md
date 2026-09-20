# ClipConvert Core Implementation Plan (Phase 0 + 1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A tested, pure-Swift `ClipConvertCore` library that decides whether clipboard text is Markdown and converts it to HTML — plus the three Phase 0 spikes that prove the project is buildable and viable.

**Architecture:** One SwiftPM package. `ClipConvertCore` is pure Swift with no AppKit, so it builds and tests locally on Windows and on Linux CI. A separate throwaway `MacProbe` package answers the one question that needs a Mac. The AppKit shell is deliberately out of scope here.

**Tech Stack:** Swift 6 (swift.org Windows toolchain), SwiftPM, XCTest, swift-markdown (Apple), GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-20-clipconvert-design.md`

## Global Constraints

- `ClipConvertCore` MUST NOT import AppKit, Cocoa, or any Apple-platform-only framework. It must compile on Windows and Linux.
- Tests use XCTest, not swift-testing — XCTest is better documented and more reliably supported on the Windows toolchain.
- Detection is conservative by design: a missed conversion is acceptable, a wrong conversion is not.
- Every task ends with a passing test run and a commit.
- Never convert when the pasteboard already has an HTML flavor.

## Spike Gates

Tasks 1, 2 and 4 are gates. If one fails, **stop and report** rather than working around it:

- **Task 1 fails** → no local Swift on Windows. The whole approach needs rethinking.
- **Task 2 fails** → swift-markdown won't build on Windows. Stop; Tasks 7–10 must be replanned around a hand-written parser for the Markdown subset.
- **Task 4 fails on both RTF and HTML** → the product does not work. Abandon rather than patch. Hand-writing RTF table syntax is explicitly out of scope.

---

### Task 1: Swift toolchain on Windows + package scaffold (Spike S1)

**Files:**
- Create: `Package.swift`
- Create: `Sources/ClipConvertCore/ClipConvertCore.swift`
- Create: `Tests/ClipConvertCoreTests/SmokeTests.swift`
- Create: `.gitattributes`
- Create: `.gitignore`

**Interfaces:**
- Consumes: nothing
- Produces: a buildable SwiftPM package named `ClipConvert` with library product `ClipConvertCore`

- [ ] **Step 1: Install the Swift toolchain**

In PowerShell:

```powershell
winget install --id Swift.Toolchain -e
```

Close and reopen the terminal, then verify:

```powershell
swift --version
```

Expected: a version string, Swift 6.0 or newer. If `swift` is not recognised after reopening the terminal, install manually from https://www.swift.org/install/windows/ and confirm the installer added Swift to `PATH`.

**GATE:** if no working `swift` command, stop and report.

- [ ] **Step 2: Create `.gitignore` and `.gitattributes`**

`.gitignore`:

```
.build/
.swiftpm/
*.xcodeproj
.DS_Store
```

`.gitattributes` (silences the CRLF warnings seen earlier):

```
* text=auto eol=lf
```

- [ ] **Step 3: Create `Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClipConvert",
    products: [
        .library(name: "ClipConvertCore", targets: ["ClipConvertCore"])
    ],
    targets: [
        .target(name: "ClipConvertCore"),
        .testTarget(
            name: "ClipConvertCoreTests",
            dependencies: ["ClipConvertCore"]
        )
    ]
)
```

Note: no dependency yet — Task 2 adds swift-markdown. Keeping Task 1 dependency-free means a failure here is unambiguously a toolchain problem.

- [ ] **Step 4: Write the failing smoke test**

`Tests/ClipConvertCoreTests/SmokeTests.swift`:

```swift
import XCTest
@testable import ClipConvertCore

final class SmokeTests: XCTestCase {
    func testPackageBuildsAndTestsRun() {
        XCTAssertEqual(coreVersion, "0.1.0")
    }
}
```

- [ ] **Step 5: Run the test to verify it fails**

```powershell
swift test
```

Expected: FAIL — `cannot find 'coreVersion' in scope`.

- [ ] **Step 6: Write the minimal implementation**

`Sources/ClipConvertCore/ClipConvertCore.swift`:

```swift
/// Version marker for the core library.
public let coreVersion = "0.1.0"
```

- [ ] **Step 7: Run the test to verify it passes**

```powershell
swift test
```

Expected: PASS, 1 test.

- [ ] **Step 8: Commit**

```bash
git add Package.swift Sources Tests .gitignore .gitattributes
git commit -m "feat: scaffold SwiftPM package, verify Swift toolchain on Windows"
```

---

### Task 2: swift-markdown builds on Windows (Spike S2)

**Files:**
- Modify: `Package.swift`
- Create: `Tests/ClipConvertCoreTests/MarkdownLibraryTests.swift`
- Create: `Sources/ClipConvertCore/MarkdownParsing.swift`

**Interfaces:**
- Consumes: the package from Task 1
- Produces: `func parsedBlockCount(_ markdown: String) -> Int` — proves the dependency links and parses

- [ ] **Step 1: Check the latest swift-markdown release**

Open https://github.com/apple/swift-markdown/releases and note the newest tag. The version below assumes `0.6.0`; use the actual newest tag if it differs.

- [ ] **Step 2: Add the dependency to `Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClipConvert",
    products: [
        .library(name: "ClipConvertCore", targets: ["ClipConvertCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.6.0")
    ],
    targets: [
        .target(
            name: "ClipConvertCore",
            dependencies: [.product(name: "Markdown", package: "swift-markdown")]
        ),
        .testTarget(
            name: "ClipConvertCoreTests",
            dependencies: ["ClipConvertCore"]
        )
    ]
)
```

- [ ] **Step 3: Write the failing test**

`Tests/ClipConvertCoreTests/MarkdownLibraryTests.swift`:

```swift
import XCTest
@testable import ClipConvertCore

final class MarkdownLibraryTests: XCTestCase {
    func testParsesTopLevelBlocks() {
        let markdown = """
        # Title

        A paragraph.

        - one
        - two
        """
        // heading, paragraph, list
        XCTAssertEqual(parsedBlockCount(markdown), 3)
    }

    func testParsesGFMTable() {
        let markdown = """
        | a | b |
        |---|---|
        | 1 | 2 |
        """
        // A single table block, not three paragraphs.
        XCTAssertEqual(parsedBlockCount(markdown), 1)
    }
}
```

The second test matters more than the first: it proves the GFM table extension is active, which the whole product depends on.

- [ ] **Step 4: Run the test to verify it fails**

```powershell
swift test
```

Expected: the dependency resolves and clones, then FAIL — `cannot find 'parsedBlockCount' in scope`.

**GATE:** if dependency resolution or compilation of swift-markdown itself fails on Windows, stop and report. Do not work around it — Tasks 7–10 need replanning.

- [ ] **Step 5: Write the minimal implementation**

`Sources/ClipConvertCore/MarkdownParsing.swift`:

```swift
import Markdown

/// Number of top-level blocks in a Markdown document.
/// Exists to prove the swift-markdown dependency links and parses correctly.
func parsedBlockCount(_ markdown: String) -> Int {
    let document = Document(parsing: markdown)
    return document.childCount
}
```

- [ ] **Step 6: Run the test to verify it passes**

```powershell
swift test
```

Expected: PASS, 3 tests.

If `testParsesGFMTable` fails with a count of 3, tables are being parsed as paragraphs and the GFM extension is off. Check whether the installed swift-markdown version needs explicit parse options, and record the finding before continuing.

- [ ] **Step 7: Commit**

```bash
git add Package.swift Package.resolved Sources Tests
git commit -m "feat: add swift-markdown, verify GFM table parsing on Windows"
```

---

### Task 3: GitHub Actions CI

**Files:**
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: the package from Task 2
- Produces: CI that runs `swift test` on Linux for every push

- [ ] **Step 1: Write the workflow**

`.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
  pull_request:

jobs:
  core:
    name: Core (Linux)
    runs-on: ubuntu-latest
    container: swift:6.0
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: swift build
      - name: Test
        run: swift test
```

The macOS job is added in Task 4, where there is something for it to build.

- [ ] **Step 2: Create the GitHub repository and push**

```bash
gh repo create clipconvert --public --source=. --remote=origin --push
```

If `gh` is not installed, create the repository manually on github.com, then:

```bash
git remote add origin https://github.com/<your-username>/clipconvert.git
git branch -M main
git push -u origin main
```

- [ ] **Step 3: Verify CI passes**

```bash
gh run watch
```

Expected: the `Core (Linux)` job succeeds with 3 tests passing. This also confirms the core is genuinely platform-independent — if it passes on Windows but fails on Linux, something Apple-specific crept in.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: run core build and tests on Linux"
git push
```

---

### Task 4: HTML → RTF fidelity probe (Spike S3 — kill gate)

**Files:**
- Create: `MacProbe/Package.swift`
- Create: `MacProbe/Sources/rtfprobe/main.swift`
- Create: `docs/paste-checklist.md`
- Modify: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: nothing (deliberately standalone — this is throwaway code)
- Produces: an answer, not an API

This is the task that decides whether the product works. It needs your friend. Run it before writing any more core code, so a failure costs you two days rather than a month.

- [ ] **Step 1: Create the probe package**

`MacProbe/Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacProbe",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "rtfprobe")
    ]
)
```

It is a separate package so that `swift build` at the repository root on Windows never tries to compile AppKit code.

- [ ] **Step 2: Write the probe**

`MacProbe/Sources/rtfprobe/main.swift`:

```swift
import AppKit

// A deliberately representative sample: a table with a header row,
// inline code inside a cell, bold text, a heading and a list.
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
```

Note the known risk: `NSAttributedString(html:)` expects the main thread and has historically needed a run loop. Top-level code in `main.swift` runs on the main thread, which should be enough. If the probe hangs instead of printing, that is itself a finding — record it and report.

- [ ] **Step 3: Add the macOS CI job**

Append to `.github/workflows/ci.yml`:

```yaml
  probe:
    name: RTF probe (macOS)
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build probe
        working-directory: MacProbe
        run: swift build -c release
      - name: Upload probe binary
        uses: actions/upload-artifact@v4
        with:
          name: rtfprobe
          path: MacProbe/.build/release/rtfprobe
```

- [ ] **Step 4: Write the checklist for your friend**

`docs/paste-checklist.md`:

```markdown
# Paste fidelity checklist

Thanks for testing. This takes about 15 minutes.

## Setup

1. Download the `rtfprobe` artifact from the latest GitHub Actions run
   (Actions tab → newest run → Artifacts → `rtfprobe`), and unzip it.
2. In Terminal, in the folder containing the file:

   ```
   chmod +x rtfprobe
   xattr -d com.apple.quarantine rtfprobe
   ./rtfprobe
   ```

   It should print `OK: wrote RTF (...) bytes`. If it hangs for more than
   ten seconds, press Ctrl+C and report that — it is a useful result.

## Test

Paste (Cmd+V) into each app below and record what you see. Do not use
Paste and Match Style.

| App | Table has gridlines? | Header row bold? | "up 12%" bold? | Heading larger? | Bullets are bullets? |
|---|---|---|---|---|---|
| Microsoft Word | | | | | |
| Outlook for Mac (new message) | | | | | |
| Gmail in Chrome | | | | | |
| Google Docs | | | | | |
| Apple Notes | | | | | |
| TextEdit (rich text mode) | | | | | |

## The one that matters most

Outlook for Mac. If the table arrives as a real table there, the project
works. If it arrives as runs of text, say so — that single answer changes
the design.

Please also paste a screenshot of the Word and Outlook results.
```

- [ ] **Step 5: Push and get the artifact built**

```bash
git add MacProbe .github/workflows/ci.yml docs/paste-checklist.md
git commit -m "spike: HTML to RTF pasteboard probe for Mac fidelity testing"
git push
gh run watch
```

Expected: the `RTF probe (macOS)` job succeeds and uploads an `rtfprobe` artifact.

- [ ] **Step 6: Send the checklist to your friend and wait**

**GATE.** Record the results in `docs/paste-checklist.md` and commit them. Then:

- Tables survive in Word **and** Outlook → proceed as planned.
- Tables survive in Word but not Outlook → proceed, and record that Outlook is a known limitation for the v1 release notes.
- Tables survive nowhere via RTF → retest with HTML flavor only (delete the `setData(rtf,...)` line, rebuild, repeat). If HTML alone works in Word and Gmail, drop RTF from the design entirely and simplify the shell.
- Neither RTF nor HTML produces a table anywhere → **stop. The product does not work.** Report rather than patching.

- [ ] **Step 7: Commit the findings**

```bash
git add docs/paste-checklist.md
git commit -m "spike: record paste fidelity results from macOS testing"
git push
```

---

### Task 5: Detect block-level Markdown signals

**Files:**
- Create: `Sources/ClipConvertCore/Detection.swift`
- Create: `Tests/ClipConvertCoreTests/DetectionTests.swift`

**Interfaces:**
- Consumes: nothing from earlier tasks
- Produces:
  - `struct MarkdownSignals` with `Bool` properties `tableDelimiter`, `fence`, `heading`, `unorderedList`, `orderedList`, `blockQuote`, `bold`, `link` (the last two are populated in Task 6)
  - `func detectSignals(_ text: String) -> MarkdownSignals`

Detection rationale, for the implementer: a table delimiter row or a code fence is a **strong** signal — nothing but Markdown produces them. Headings and list markers are **weak**, because `# comment` appears in shell and Python, and `- item` appears in YAML. Task 6 adds the inline signals that disambiguate.

- [ ] **Step 1: Write the failing tests**

`Tests/ClipConvertCoreTests/DetectionTests.swift`:

```swift
import XCTest
@testable import ClipConvertCore

final class DetectionTests: XCTestCase {
    func testDetectsTableDelimiterRow() {
        let text = """
        | Region | Revenue |
        |--------|---------|
        | EMEA   | 1.2M    |
        """
        XCTAssertTrue(detectSignals(text).tableDelimiter)
    }

    func testDetectsAlignedTableDelimiterRow() {
        let text = """
        | a | b |
        |:---|---:|
        | 1 | 2 |
        """
        XCTAssertTrue(detectSignals(text).tableDelimiter)
    }

    func testSingleColumnDashLineIsNotATable() {
        // A horizontal rule or an underlined heading must not read as a table.
        XCTAssertFalse(detectSignals("-----").tableDelimiter)
    }

    func testDetectsCodeFence() {
        let text = """
        Here you go:

        ```swift
        let x = 1
        ```
        """
        XCTAssertTrue(detectSignals(text).fence)
    }

    func testDetectsHeading() {
        XCTAssertTrue(detectSignals("# Title").heading)
        XCTAssertTrue(detectSignals("### Deeper").heading)
    }

    func testHashWithoutSpaceIsNotAHeading() {
        // "#include" and "#1" are not headings.
        XCTAssertFalse(detectSignals("#include <stdio.h>").heading)
        XCTAssertFalse(detectSignals("#1 priority").heading)
    }

    func testDetectsUnorderedList() {
        XCTAssertTrue(detectSignals("- one\n- two").unorderedList)
        XCTAssertTrue(detectSignals("* one").unorderedList)
    }

    func testDetectsOrderedList() {
        XCTAssertTrue(detectSignals("1. first\n2. second").orderedList)
    }

    func testDetectsBlockQuote() {
        XCTAssertTrue(detectSignals("> quoted").blockQuote)
    }

    func testPlainProseHasNoBlockSignals() {
        let signals = detectSignals("Just an ordinary sentence about nothing.")
        XCTAssertFalse(signals.tableDelimiter)
        XCTAssertFalse(signals.fence)
        XCTAssertFalse(signals.heading)
        XCTAssertFalse(signals.unorderedList)
        XCTAssertFalse(signals.orderedList)
        XCTAssertFalse(signals.blockQuote)
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```powershell
swift test --filter DetectionTests
```

Expected: FAIL — `cannot find 'detectSignals' in scope`.

- [ ] **Step 3: Write the implementation**

`Sources/ClipConvertCore/Detection.swift`:

```swift
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
        #"^ {0,3}\|?[ \t]*:?-{3,}:?[ \t]*(\|[ \t]*:?-{3,}:?[ \t]*)+\|?[ \t]*$"#,
        text
    )
    signals.fence = matches(#"^ {0,3}(```|~~~)"#, text)
    signals.heading = matches(#"^ {0,3}#{1,6}[ \t]+\S"#, text)
    signals.unorderedList = matches(#"^ {0,3}[-*+][ \t]+\S"#, text)
    signals.orderedList = matches(#"^ {0,3}\d{1,9}[.)][ \t]+\S"#, text)
    signals.blockQuote = matches(#"^ {0,3}>[ \t]?\S"#, text)

    return signals
}
```

- [ ] **Step 4: Run the tests to verify they pass**

```powershell
swift test --filter DetectionTests
```

Expected: PASS, 10 tests.

- [ ] **Step 5: Commit**

```bash
git add Sources/ClipConvertCore/Detection.swift Tests/ClipConvertCoreTests/DetectionTests.swift
git commit -m "feat: detect block-level Markdown signals"
```

---

### Task 6: Inline signals and the conversion decision

**Files:**
- Modify: `Sources/ClipConvertCore/Detection.swift`
- Modify: `Tests/ClipConvertCoreTests/DetectionTests.swift`

**Interfaces:**
- Consumes: `MarkdownSignals`, `detectSignals(_:)`, `matches(_:_:)` from Task 5
- Produces: `func shouldConvert(_ text: String) -> Bool`

The rule: **convert if there is a strong signal, or if there is both a block signal and an inline signal.** Only bold (`**text**`) and links (`[text](url)`) count as inline signals — italics and backticks are excluded deliberately, because underscores are everywhere in source code and backticks are shell command substitution.

This rule is what keeps YAML and shell scripts safe. A YAML file has `# comment` and `- item` — two block signals, no inline signal — so it is left alone.

- [ ] **Step 1: Write the failing tests**

Append to `Tests/ClipConvertCoreTests/DetectionTests.swift`:

```swift
final class ShouldConvertTests: XCTestCase {
    // Strong signals convert on their own.

    func testTableConvertsAlone() {
        let text = """
        | a | b |
        |---|---|
        | 1 | 2 |
        """
        XCTAssertTrue(shouldConvert(text))
    }

    func testFencedCodeConvertsAlone() {
        XCTAssertTrue(shouldConvert("```python\nprint(1)\n```"))
    }

    // Weak signals need an inline signal alongside them.

    func testHeadingPlusBoldConverts() {
        XCTAssertTrue(shouldConvert("# Title\n\nThis is **important**."))
    }

    func testListPlusLinkConverts() {
        XCTAssertTrue(shouldConvert("- see [the docs](https://example.com)\n- and more"))
    }

    func testBareListDoesNotConvert() {
        // Loses nothing as plain text, so not worth the false-positive risk.
        XCTAssertFalse(shouldConvert("- milk\n- eggs\n- bread"))
    }

    func testBoldAloneDoesNotConvert() {
        XCTAssertFalse(shouldConvert("This is **important** and that is all."))
    }

    // The negative corpus: these must never convert.

    func testYAMLDoesNotConvert() {
        let yaml = """
        # deployment config
        services:
          - name: web
          - name: worker
        """
        XCTAssertFalse(shouldConvert(yaml))
    }

    func testShellScriptDoesNotConvert() {
        let shell = """
        # Install dependencies
        set -e
        npm install
        # Build the project
        npm run build
        """
        XCTAssertFalse(shouldConvert(shell))
    }

    func testPythonSourceDoesNotConvert() {
        let python = """
        # Compute the total
        def total(items):
            return sum(i.price for i in items)
        """
        XCTAssertFalse(shouldConvert(python))
    }

    func testCommandLineFlagsDoNotConvert() {
        XCTAssertFalse(shouldConvert("run --verbose -o out.txt"))
    }

    func testEmptyStringDoesNotConvert() {
        XCTAssertFalse(shouldConvert(""))
        XCTAssertFalse(shouldConvert("   \n  \n "))
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```powershell
swift test --filter ShouldConvertTests
```

Expected: FAIL — `cannot find 'shouldConvert' in scope`.

- [ ] **Step 3: Add inline detection and the decision rule**

In `Sources/ClipConvertCore/Detection.swift`, add to the end of `detectSignals` before `return signals`:

```swift
    // Inline signals, restricted to the two that are rare in source code.
    signals.bold = matches(#"\*\*[^*\n]+\*\*"#, text)
    signals.link = matches(#"\[[^\]\n]+\]\([^)\s]+\)"#, text)
```

Then append to the file:

```swift
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
```

- [ ] **Step 4: Run the tests to verify they pass**

```powershell
swift test
```

Expected: PASS, all tests across both detection classes.

- [ ] **Step 5: Commit**

```bash
git add Sources/ClipConvertCore/Detection.swift Tests/ClipConvertCoreTests/DetectionTests.swift
git commit -m "feat: add inline signals and conservative conversion rule"
```

---

### Task 7: HTML renderer — escaping, headings, paragraphs

**Files:**
- Create: `Sources/ClipConvertCore/HTMLRenderer.swift`
- Create: `Sources/ClipConvertCore/HTMLEscaping.swift`
- Create: `Tests/ClipConvertCoreTests/HTMLRendererTests.swift`

**Interfaces:**
- Consumes: swift-markdown from Task 2
- Produces:
  - `func escapeHTML(_ s: String) -> String`
  - `func markdownToHTML(_ markdown: String) -> String`
  - `struct HTMLRenderer: MarkupWalker` with `var html: String`

Before writing code, a note on the library: swift-markdown gives you an abstract syntax tree, not HTML — it has no built-in HTML renderer. You walk the tree with `MarkupWalker` and emit tags yourself. That is deliberate here: parsing is the hard part and Apple has solved it correctly, while HTML emission is the easy part we want full control over.

- [ ] **Step 1: Verify the walker API names**

swift-markdown's visit method names must match exactly or the overrides silently do nothing. Confirm against the source of the version you resolved:

```powershell
swift package resolve
type .build\checkouts\swift-markdown\Sources\Markdown\Walker\MarkupWalker.swift
```

Confirm these exist: `visitText`, `visitHeading`, `visitParagraph`, `visitEmphasis`, `visitStrong`, `visitLink`, `visitInlineCode`, `visitCodeBlock`, `visitUnorderedList`, `visitOrderedList`, `visitListItem`, `visitBlockQuote`, `visitSoftBreak`, `visitLineBreak`, `visitThematicBreak`, `visitTable`, `visitTableHead`, `visitTableBody`, `visitTableRow`, `visitTableCell`. If a name differs, use the real one throughout Tasks 7–10.

- [ ] **Step 2: Write the failing tests**

`Tests/ClipConvertCoreTests/HTMLRendererTests.swift`:

```swift
import XCTest
@testable import ClipConvertCore

final class HTMLEscapingTests: XCTestCase {
    func testEscapesMarkupCharacters() {
        XCTAssertEqual(escapeHTML("a < b & c > d"), "a &lt; b &amp; c &gt; d")
    }

    func testEscapesQuotes() {
        XCTAssertEqual(escapeHTML(#"say "hi""#), "say &quot;hi&quot;")
    }

    func testLeavesPlainTextAlone() {
        XCTAssertEqual(escapeHTML("nothing to do"), "nothing to do")
    }
}

final class HTMLRendererTests: XCTestCase {
    func testParagraph() {
        XCTAssertEqual(markdownToHTML("Hello."), "<p>Hello.</p>")
    }

    func testHeadingLevels() {
        XCTAssertEqual(markdownToHTML("# One"), "<h1>One</h1>")
        XCTAssertEqual(markdownToHTML("### Three"), "<h3>Three</h3>")
    }

    func testEscapesTextContent() {
        XCTAssertEqual(
            markdownToHTML("5 < 6 & 7 > 2"),
            "<p>5 &lt; 6 &amp; 7 &gt; 2</p>"
        )
    }

    func testMultipleBlocks() {
        XCTAssertEqual(
            markdownToHTML("# Title\n\nBody."),
            "<h1>Title</h1><p>Body.</p>"
        )
    }
}
```

- [ ] **Step 3: Run the tests to verify they fail**

```powershell
swift test --filter HTML
```

Expected: FAIL — `cannot find 'escapeHTML' in scope`.

- [ ] **Step 4: Write the escaping helper**

`Sources/ClipConvertCore/HTMLEscaping.swift`:

```swift
/// Escape the four characters that change meaning inside HTML.
func escapeHTML(_ s: String) -> String {
    var out = ""
    out.reserveCapacity(s.count)
    for character in s {
        switch character {
        case "&": out += "&amp;"
        case "<": out += "&lt;"
        case ">": out += "&gt;"
        case "\"": out += "&quot;"
        default: out.append(character)
        }
    }
    return out
}
```

- [ ] **Step 5: Write the renderer skeleton**

`Sources/ClipConvertCore/HTMLRenderer.swift`:

```swift
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
}

/// Convert Markdown source into HTML suitable for the macOS pasteboard.
public func markdownToHTML(_ markdown: String) -> String {
    let document = Document(parsing: markdown)
    var renderer = HTMLRenderer()
    renderer.visit(document)
    return renderer.html
}
```

- [ ] **Step 6: Run the tests to verify they pass**

```powershell
swift test --filter HTML
```

Expected: PASS, 7 tests.

- [ ] **Step 7: Commit**

```bash
git add Sources/ClipConvertCore/HTMLRenderer.swift Sources/ClipConvertCore/HTMLEscaping.swift Tests/ClipConvertCoreTests/HTMLRendererTests.swift
git commit -m "feat: HTML renderer with escaping, headings and paragraphs"
```

---

### Task 8: HTML renderer — inline elements

**Files:**
- Modify: `Sources/ClipConvertCore/HTMLRenderer.swift`
- Modify: `Tests/ClipConvertCoreTests/HTMLRendererTests.swift`

**Interfaces:**
- Consumes: `HTMLRenderer`, `markdownToHTML(_:)`, `escapeHTML(_:)` from Task 7
- Produces: no new public names — extends `HTMLRenderer` with inline handling

- [ ] **Step 1: Write the failing tests**

Append to `Tests/ClipConvertCoreTests/HTMLRendererTests.swift`:

```swift
final class InlineRenderingTests: XCTestCase {
    func testStrong() {
        XCTAssertEqual(
            markdownToHTML("This is **bold**."),
            "<p>This is <strong>bold</strong>.</p>"
        )
    }

    func testEmphasis() {
        XCTAssertEqual(
            markdownToHTML("This is *italic*."),
            "<p>This is <em>italic</em>.</p>"
        )
    }

    func testInlineCodeIsEscaped() {
        XCTAssertEqual(
            markdownToHTML("Run `a < b`."),
            "<p>Run <code>a &lt; b</code>.</p>"
        )
    }

    func testLink() {
        XCTAssertEqual(
            markdownToHTML("See [docs](https://example.com)."),
            #"<p>See <a href="https://example.com">docs</a>.</p>"#
        )
    }

    func testLinkDestinationIsEscaped() {
        XCTAssertEqual(
            markdownToHTML(#"[x](https://e.com/?a=1&b=2)"#),
            #"<p><a href="https://e.com/?a=1&amp;b=2">x</a></p>"#
        )
    }

    func testHardLineBreak() {
        // Two trailing spaces produce a hard break.
        XCTAssertEqual(
            markdownToHTML("one  \ntwo"),
            "<p>one<br>two</p>"
        )
    }

    func testSoftBreakBecomesSpace() {
        XCTAssertEqual(markdownToHTML("one\ntwo"), "<p>one two</p>")
    }
}
```

A note on `testSoftBreakBecomesSpace`: a soft break renders as a space rather than a newline because the output goes to `NSAttributedString`, where a literal newline would become a paragraph break the author did not write.

- [ ] **Step 2: Run the tests to verify they fail**

```powershell
swift test --filter InlineRenderingTests
```

Expected: FAIL — the emphasis test produces `<p>This is italic.</p>` with the tags missing, because `defaultVisit` descends without emitting anything.

- [ ] **Step 3: Add the inline visit methods**

Add inside `struct HTMLRenderer` in `Sources/ClipConvertCore/HTMLRenderer.swift`:

```swift
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
```

- [ ] **Step 4: Run the tests to verify they pass**

```powershell
swift test --filter InlineRenderingTests
```

Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add Sources/ClipConvertCore/HTMLRenderer.swift Tests/ClipConvertCoreTests/HTMLRendererTests.swift
git commit -m "feat: render inline Markdown elements to HTML"
```

---

### Task 9: HTML renderer — lists, quotes, code blocks, rules

**Files:**
- Modify: `Sources/ClipConvertCore/HTMLRenderer.swift`
- Modify: `Tests/ClipConvertCoreTests/HTMLRendererTests.swift`

**Interfaces:**
- Consumes: `HTMLRenderer` from Tasks 7–8
- Produces: no new public names

- [ ] **Step 1: Write the failing tests**

Append to `Tests/ClipConvertCoreTests/HTMLRendererTests.swift`:

```swift
final class BlockRenderingTests: XCTestCase {
    func testUnorderedList() {
        XCTAssertEqual(
            markdownToHTML("- one\n- two"),
            "<ul><li><p>one</p></li><li><p>two</p></li></ul>"
        )
    }

    func testOrderedList() {
        XCTAssertEqual(
            markdownToHTML("1. one\n2. two"),
            "<ol><li><p>one</p></li><li><p>two</p></li></ol>"
        )
    }

    func testNestedList() {
        let markdown = """
        - outer
          - inner
        """
        XCTAssertEqual(
            markdownToHTML(markdown),
            "<ul><li><p>outer</p><ul><li><p>inner</p></li></ul></li></ul>"
        )
    }

    func testBlockQuote() {
        XCTAssertEqual(
            markdownToHTML("> quoted"),
            "<blockquote><p>quoted</p></blockquote>"
        )
    }

    func testFencedCodeBlockIsEscaped() {
        let markdown = """
        ```swift
        if a < b { print("x") }
        ```
        """
        XCTAssertEqual(
            markdownToHTML(markdown),
            "<pre><code>if a &lt; b { print(&quot;x&quot;) }\n</code></pre>"
        )
    }

    func testThematicBreak() {
        XCTAssertEqual(markdownToHTML("---"), "<hr>")
    }
}
```

If `testUnorderedList` fails only on the presence or absence of the inner `<p>` tags, adjust the expected strings to match what swift-markdown actually produces — CommonMark distinguishes tight from loose lists, and the wrapping differs. The tags matter, the `<p>` nesting does not; correct the expectation rather than the renderer.

If `testFencedCodeBlockIsEscaped` fails only on the trailing `\n`, do the same — `CodeBlock.code` includes the final newline in some versions.

- [ ] **Step 2: Run the tests to verify they fail**

```powershell
swift test --filter BlockRenderingTests
```

Expected: FAIL — list markup missing entirely.

- [ ] **Step 3: Add the block visit methods**

Add inside `struct HTMLRenderer`:

```swift
    mutating func visitUnorderedList(_ list: UnorderedList) {
        html += "<ul>"
        descendInto(list)
        html += "</ul>"
    }

    mutating func visitOrderedList(_ list: OrderedList) {
        html += "<ol>"
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
```

- [ ] **Step 4: Run the tests to verify they pass**

```powershell
swift test --filter BlockRenderingTests
```

Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add Sources/ClipConvertCore/HTMLRenderer.swift Tests/ClipConvertCoreTests/HTMLRendererTests.swift
git commit -m "feat: render lists, quotes, code blocks and rules to HTML"
```

---

### Task 10: HTML renderer — tables

**Files:**
- Modify: `Sources/ClipConvertCore/HTMLRenderer.swift`
- Modify: `Tests/ClipConvertCoreTests/HTMLRendererTests.swift`

**Interfaces:**
- Consumes: `HTMLRenderer` from Tasks 7–9
- Produces: no new public names

This is the highest-value task in the plan — tables are the reason the product exists. The `border`, `cellspacing` and `cellpadding` attributes are not decoration: without them, Word and Outlook render a borderless grid that does not read as a table.

- [ ] **Step 1: Write the failing tests**

Append to `Tests/ClipConvertCoreTests/HTMLRendererTests.swift`:

```swift
final class TableRenderingTests: XCTestCase {
    func testSimpleTable() {
        let markdown = """
        | Region | Revenue |
        |--------|---------|
        | EMEA   | 1.2M    |
        """
        let expected = "<table border=\"1\" cellspacing=\"0\" cellpadding=\"4\">"
            + "<thead><tr><th>Region</th><th>Revenue</th></tr></thead>"
            + "<tbody><tr><td>EMEA</td><td>1.2M</td></tr></tbody>"
            + "</table>"
        XCTAssertEqual(markdownToHTML(markdown), expected)
    }

    func testTableWithInlineFormatting() {
        let markdown = """
        | Flag | Meaning |
        |------|---------|
        | `-v` | **verbose** |
        """
        let html = markdownToHTML(markdown)
        XCTAssertTrue(html.contains("<td><code>-v</code></td>"))
        XCTAssertTrue(html.contains("<td><strong>verbose</strong></td>"))
    }

    func testTableCellContentIsEscaped() {
        let markdown = """
        | Expr |
        |------|
        | a < b |
        """
        XCTAssertTrue(markdownToHTML(markdown).contains("<td>a &lt; b</td>"))
    }

    func testMultipleBodyRows() {
        let markdown = """
        | n |
        |---|
        | 1 |
        | 2 |
        """
        let html = markdownToHTML(markdown)
        XCTAssertTrue(html.contains("<tr><td>1</td></tr><tr><td>2</td></tr>"))
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```powershell
swift test --filter TableRenderingTests
```

Expected: FAIL — cell text appears with no table markup around it.

- [ ] **Step 3: Add the table visit methods**

Add inside `struct HTMLRenderer`:

```swift
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
```

- [ ] **Step 4: Run the tests to verify they pass**

```powershell
swift test --filter TableRenderingTests
```

Expected: PASS, 4 tests.

If `testSimpleTable` produces `<td>` where `<th>` was expected, the `cell.parent is Markdown.Table.Head` check is not matching. Print `type(of: cell.parent)` to find the real parent type and adjust the condition.

- [ ] **Step 5: Commit**

```bash
git add Sources/ClipConvertCore/HTMLRenderer.swift Tests/ClipConvertCoreTests/HTMLRendererTests.swift
git commit -m "feat: render GFM tables to HTML with borders for Word and Outlook"
```

---

### Task 11: The `plan` entry point

**Files:**
- Create: `Sources/ClipConvertCore/Plan.swift`
- Create: `Tests/ClipConvertCoreTests/PlanTests.swift`

**Interfaces:**
- Consumes: `shouldConvert(_:)` from Task 6, `markdownToHTML(_:)` from Task 7
- Produces:
  - `enum SkipReason: Equatable` with cases `alreadyRich`, `noMarkdownFound`, `empty`
  - `enum ClipboardAction: Equatable` with cases `convert(html: String)`, `skip(reason: SkipReason)`
  - `func plan(plainText: String, hasHTMLFlavor: Bool) -> ClipboardAction`

This is the single function the AppKit shell will call. Everything the shell does is dictated by its return value, so no decision logic ever lives in the untestable layer.

- [ ] **Step 1: Write the failing tests**

`Tests/ClipConvertCoreTests/PlanTests.swift`:

```swift
import XCTest
@testable import ClipConvertCore

final class PlanTests: XCTestCase {
    func testSkipsWhenHTMLFlavorPresent() {
        // Already rich: converting could only make it worse.
        let action = plan(plainText: "# Title\n\n**bold**", hasHTMLFlavor: true)
        XCTAssertEqual(action, .skip(reason: .alreadyRich))
    }

    func testSkipsEmptyClipboard() {
        XCTAssertEqual(
            plan(plainText: "", hasHTMLFlavor: false),
            .skip(reason: .empty)
        )
        XCTAssertEqual(
            plan(plainText: "  \n ", hasHTMLFlavor: false),
            .skip(reason: .empty)
        )
    }

    func testEmptyIsCheckedBeforeMarkdown() {
        // Whitespace must report .empty, not .noMarkdownFound.
        XCTAssertEqual(
            plan(plainText: "\n\n", hasHTMLFlavor: false),
            .skip(reason: .empty)
        )
    }

    func testSkipsPlainProse() {
        XCTAssertEqual(
            plan(plainText: "Just a sentence.", hasHTMLFlavor: false),
            .skip(reason: .noMarkdownFound)
        )
    }

    func testSkipsSourceCode() {
        let shell = "# Install\nset -e\nnpm install"
        XCTAssertEqual(
            plan(plainText: shell, hasHTMLFlavor: false),
            .skip(reason: .noMarkdownFound)
        )
    }

    func testConvertsTable() {
        let markdown = "| a | b |\n|---|---|\n| 1 | 2 |"
        guard case .convert(let html) = plan(plainText: markdown, hasHTMLFlavor: false) else {
            return XCTFail("expected .convert")
        }
        XCTAssertTrue(html.contains("<table"))
        XCTAssertTrue(html.contains("<th>a</th>"))
    }

    func testConvertsHeadingPlusBold() {
        guard case .convert(let html) = plan(
            plainText: "# Title\n\nThis is **important**.",
            hasHTMLFlavor: false
        ) else {
            return XCTFail("expected .convert")
        }
        XCTAssertTrue(html.contains("<h1>Title</h1>"))
        XCTAssertTrue(html.contains("<strong>important</strong>"))
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```powershell
swift test --filter PlanTests
```

Expected: FAIL — `cannot find 'plan' in scope`.

- [ ] **Step 3: Write the implementation**

`Sources/ClipConvertCore/Plan.swift`:

```swift
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
```

- [ ] **Step 4: Run the tests to verify they pass**

```powershell
swift test
```

Expected: PASS, the whole suite.

- [ ] **Step 5: Commit**

```bash
git add Sources/ClipConvertCore/Plan.swift Tests/ClipConvertCoreTests/PlanTests.swift
git commit -m "feat: add plan() entry point for the AppKit shell"
git push
```

---

### Task 12: Golden-file corpus from real AI output

**Files:**
- Create: `Tests/ClipConvertCoreTests/Fixtures/` (input `.md` and expected `.html` files)
- Create: `Tests/ClipConvertCoreTests/Negative/` (input `.txt` files that must not convert)
- Create: `Tests/ClipConvertCoreTests/GoldenFileTests.swift`
- Modify: `Package.swift`

**Interfaces:**
- Consumes: `markdownToHTML(_:)` from Task 7, `shouldConvert(_:)` from Task 6
- Produces: no new API — a regression harness

The unit tests so far use Markdown you wrote. This task uses Markdown the AIs actually produce, which is different: longer, more nested, and full of edge cases nobody invents deliberately. Per the spec, this corpus is the most durable asset the project produces.

- [ ] **Step 1: Collect real samples**

Ask ChatGPT, Claude and Gemini each for the following, and use each answer's **copy button** (not a text selection) to capture the raw Markdown. Save each as a `.md` file under `Tests/ClipConvertCoreTests/Fixtures/`:

1. "Compare Postgres, MySQL and SQLite in a table with at least four rows." → `table-comparison-{chatgpt,claude,gemini}.md`
2. "Explain git rebase with a numbered list and a code example." → `list-with-code-{chatgpt,claude,gemini}.md`
3. "Summarise the causes of WW1 with headings and sub-bullets." → `nested-headings-{chatgpt,claude,gemini}.md`

Nine files. Do not clean them up — the messiness is the point.

- [ ] **Step 2: Collect the negative corpus**

Save these as `.txt` under `Tests/ClipConvertCoreTests/Negative/`. Every one must be left alone:

- `python-source.txt` — a real Python file with `#` comments
- `shell-script.txt` — a real shell script with `#` comments
- `docker-compose.txt` — real YAML with comments and `-` list items
- `plain-email.txt` — ordinary prose with a `*` used for emphasis
- `csv-data.txt` — comma-separated data with a dashed separator line
- `log-output.txt` — application log lines containing `|` characters

- [ ] **Step 3: Declare the fixtures as test resources**

In `Package.swift`, change the test target to:

```swift
        .testTarget(
            name: "ClipConvertCoreTests",
            dependencies: ["ClipConvertCore"],
            resources: [
                .copy("Fixtures"),
                .copy("Negative")
            ]
        )
```

- [ ] **Step 4: Write the harness**

`Tests/ClipConvertCoreTests/GoldenFileTests.swift`:

```swift
import XCTest
@testable import ClipConvertCore

final class GoldenFileTests: XCTestCase {

    /// Set to true, run once, then set back to false. Regenerates every
    /// .html file from current renderer output. Review the diff before
    /// committing — that diff is the actual review.
    static let regenerate = false

    func testFixturesMatchGoldenOutput() throws {
        let fixtures = try urls(inResourceDirectory: "Fixtures", extension: "md")
        XCTAssertFalse(fixtures.isEmpty, "no fixtures found — check Package.swift resources")

        for markdownURL in fixtures {
            let markdown = try String(contentsOf: markdownURL, encoding: .utf8)
            let actual = markdownToHTML(markdown)
            let goldenURL = markdownURL.deletingPathExtension().appendingPathExtension("html")

            if Self.regenerate {
                try actual.write(to: goldenURL, atomically: true, encoding: .utf8)
                continue
            }

            guard let expected = try? String(contentsOf: goldenURL, encoding: .utf8) else {
                XCTFail("missing golden file for \(markdownURL.lastPathComponent) — set regenerate = true once")
                continue
            }

            XCTAssertEqual(
                actual,
                expected,
                "output changed for \(markdownURL.lastPathComponent)"
            )
        }
    }

    func testAllFixturesAreDetectedAsMarkdown() throws {
        for markdownURL in try urls(inResourceDirectory: "Fixtures", extension: "md") {
            let markdown = try String(contentsOf: markdownURL, encoding: .utf8)
            XCTAssertTrue(
                shouldConvert(markdown),
                "real AI output was not detected: \(markdownURL.lastPathComponent)"
            )
        }
    }

    func testNegativeCorpusIsNeverConverted() throws {
        let samples = try urls(inResourceDirectory: "Negative", extension: "txt")
        XCTAssertFalse(samples.isEmpty, "no negative samples found")

        for sampleURL in samples {
            let text = try String(contentsOf: sampleURL, encoding: .utf8)
            XCTAssertFalse(
                shouldConvert(text),
                "false positive — would have mangled \(sampleURL.lastPathComponent)"
            )
        }
    }

    private func urls(
        inResourceDirectory directory: String,
        extension ext: String
    ) throws -> [URL] {
        guard let base = Bundle.module.url(forResource: directory, withExtension: nil) else {
            XCTFail("resource directory \(directory) not found in test bundle")
            return []
        }
        let contents = try FileManager.default.contentsOfDirectory(
            at: base,
            includingPropertiesForKeys: nil
        )
        return contents.filter { $0.pathExtension == ext }.sorted { $0.path < $1.path }
    }
}
```

- [ ] **Step 5: Generate the golden files and review them**

Set `regenerate` to `true`, run `swift test --filter GoldenFileTests`, then set it back to `false`.

Now **read every generated `.html` file.** This is the real verification step in this task — the tests only prove the output is stable, not that it is correct. Look for: dropped table cells, unescaped `&`, lost nesting in sub-bullets, code blocks that swallowed following text.

Fix any renderer bugs you find, regenerate, and read again.

- [ ] **Step 6: Run the full suite**

```powershell
swift test
```

Expected: PASS. If `testNegativeCorpusIsNeverConverted` fails, the detection rule from Task 6 needs tightening — that failure is the harness doing exactly its job, so fix the rule rather than removing the sample.

- [ ] **Step 7: Commit**

```bash
git add Package.swift Tests/ClipConvertCoreTests
git commit -m "test: golden-file corpus from real ChatGPT, Claude and Gemini output"
git push
```

---

## Done when

- `swift test` passes on Windows and on Linux CI.
- The negative corpus never converts.
- Real AI output from all three chatbots renders to HTML you have read and judged correct.
- Spike S3's results are recorded in `docs/paste-checklist.md`.

## Next

Write the Phase 2 plan for `ClipConvertMac` — `NSStatusItem`, `RegisterEventHotKey`, pasteboard read/write, undo snapshot. Its shape depends on the S3 findings, so write it after Task 4 reports, not before.
