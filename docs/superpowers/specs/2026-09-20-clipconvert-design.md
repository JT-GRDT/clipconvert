# ClipConvert — Design Spec

**Date:** 2026-09-20
**Status:** Approved for planning
**Working name:** ClipConvert (changeable)

## Problem

AI chatbots write answers in Markdown. The chat window renders it, but the
copy button places the raw Markdown *source* on the clipboard — pipes,
asterisks, hashes. Pasting into Word, Outlook, Gmail or Docs produces
`| a | b |` instead of a table and `**bold**` instead of bold.

macOS has no native fix. Windows does, via PowerToys Advanced Paste. The
existing Mac options are fragmented hobby scripts or browser extensions
tied to specific sites. A clipboard-level utility works with every AI
source and every destination app.

## Goals (v1)

One macOS menu bar app, one global hotkey. Pressing it converts Markdown
on the clipboard into rich text, so the next paste into any app produces
native tables, bold and headings.

That is the entire v1. It is deliberately one direction.

## Non-goals (v1)

- **Rich text → Markdown.** Deferred to v2. See "Why one direction" below.
- **Auto-paste.** Simulating Cmd+V needs Accessibility permission, a scary
  onboarding prompt and an App Store review question. The user presses
  Cmd+V themselves.
- **Image OCR, file conversion, Docling, web version.** Later, if ever.
- **Code signing and notarization.** Not needed until distribution;
  defers the $99/yr Apple Developer account.

### Why one direction

The going-in direction (Excel/web → Markdown) is a weaker problem than it
appears. When you copy an Excel range, the clipboard's plain-text flavor
is already TSV, and current LLMs parse TSV correctly. The genuine wins
there are narrower — stripping nav and CSS junk out of copied web pages,
and reducing token count — and they do not justify v1 scope.

The coming-out direction has unambiguous pain, no good Mac solution, and
a demo that lands in five seconds.

Note for v2: selecting and dragging over a *rendered* AI answer already
puts real HTML on the clipboard. The problem is specifically the copy
button, which writes plain text only. This is also the basis of the
detection rule below.

## Development constraints

These are unusual and they drive the architecture more than anything else.

- The developer works on **Windows 11** and has **no Mac**.
- The developer has **no prior Swift or Xcode experience**.
- A friend with a Mac is available for **occasional** testing only — not a
  reliable per-commit loop.

Consequences:

- Xcode, `xcodebuild`, codesigning and `notarytool` are macOS-only. The
  AppKit layer cannot be compiled or run locally.
- Swift itself **does** run on Windows (official toolchain from swift.org:
  `swift build` / `swift test`, Foundation and SwiftPM, no AppKit). Pure
  Swift code gets a normal local edit-run-fail-fix loop.
- Therefore: **maximise the code that is pure Swift, minimise the code that
  is AppKit.** Everything blind must also be everything trivial.

## Architecture

Two SwiftPM targets in one repository.

### `ClipConvertCore` — pure Swift, no AppKit

All logic. Builds and tests locally on Windows, and in CI on Linux.

Public surface, roughly:

```swift
enum ClipboardAction {
    case convert(html: String)
    case skip(reason: SkipReason)
}

enum SkipReason {
    case alreadyRich       // HTML flavor present on pasteboard
    case noMarkdownFound   // no structural signal
    case empty
}

func plan(plainText: String, hasHTMLFlavor: Bool) -> ClipboardAction
func markdownToHTML(_ markdown: String) -> String
func shouldConvert(_ text: String) -> Bool
func detectSignals(_ text: String) -> MarkdownSignals
```

Detection is two-tier. `detectSignals` is purely descriptive — it reports
which Markdown features are present. `shouldConvert` applies the rule:

- **Strong signals** (a table delimiter row, a code fence) convert on their
  own. Nothing but Markdown produces them.
- **Weak block signals** (headings, list markers, blockquotes) must be
  corroborated by an **inline signal** (`**bold**` or `[a](b)`). Weak
  signals alone are ambiguous — `# comment` appears in shell and Python,
  `- item` appears in YAML.

This is what keeps source code and config files safe: YAML has `#` comments
and `-` items but almost never `**bold**`, so it is left alone. Italics and
backticks are deliberately excluded from the inline set, because underscores
are pervasive in code and backticks are shell command substitution.

The shell calls `plan` and does what it says. No decisions live in the shell.

### `ClipConvertMac` — thin AppKit shell

A few hundred lines, no business logic:

- `NSStatusItem` menu bar item with menu: Convert, Force Convert (bypasses
  detection), Undo Last Conversion, Preferences, Quit
- Global hotkey via Carbon `RegisterEventHotKey` (works sandboxed, needs no
  Accessibility permission, unlike `NSEvent` global monitors)
- `NSPasteboard.general` reads and writes
- HTML → RTF via `NSAttributedString(data:options:[.documentType: .html])`
  then `.rtf(from:)`
- User notifications for result feedback

## Data flow

Hotkey fires, then:

1. Read `NSPasteboard.general`. Note which flavors are present.
2. If `public.html` is present, skip with `.alreadyRich`. Notify, stop. That
   clipboard already pastes correctly; touching it can only do harm.
3. Take `public.utf8-plain-text`. Ask the core for a plan.
4. Core checks for **structural** Markdown — a pipe table row, a fenced
   code block, a line-start ATX heading, a line-start list marker, a
   line-start blockquote. Stray `*` or `_` mid-sentence does **not**
   qualify. If nothing structural, skip with `.noMarkdownFound`.
5. Core returns HTML. Shell builds an `NSAttributedString` from it and
   derives RTF.
6. Shell snapshots the existing pasteboard contents in memory, then clears
   and writes three flavors: RTF, HTML, and the original plain text
   (preserved verbatim, so pasting into a terminal or editor still yields
   the Markdown source).
7. Notify the user what happened. Enable "Undo Last Conversion" in the menu,
   which restores the snapshot.

## Error handling

One governing rule: **when in doubt, do nothing and say so.**

A no-op the user notices is a minor annoyance. A silent wrong conversion
that mangles a copied code snippet is the failure that gets the app
uninstalled. Any throw or unexpected state anywhere in the pipeline leaves
the pasteboard completely untouched and produces a notification explaining
why nothing happened.

Detection is deliberately conservative — it is better to miss a conversion
the user wanted (they press the hotkey again after checking, or use an
explicit "Force convert" menu item) than to convert something they did not.

## Testing strategy

### Core — automated, runs on Windows and in CI

Golden-file tests. A corpus directory of real inputs and expected outputs:

```
Tests/Fixtures/
  simple-table.md            -> simple-table.html
  nested-lists.md            -> nested-lists.html
  table-with-inline-code.md  -> table-with-inline-code.html
  mixed-emphasis.md          -> mixed-emphasis.html
  fenced-block-with-pipes.md -> fenced-block-with-pipes.html
Tests/Detection/
  positive/   # must be detected as Markdown
  negative/   # must NOT be: python source, shell snippets, prose with
              # asterisks, file globs, identifiers with underscores
```

Inputs must be **real copied output** from ChatGPT, Claude and Gemini, not
hand-written Markdown. This corpus is the most durable asset the project
produces; it survives any rewrite.

The `negative/` set matters as much as the positive one — it is the guard
against the worst failure mode.

### Shell — manual, batched

A written checklist the friend works through once per milestone, not per
commit. For each of Word, Outlook for Mac, Gmail (Chrome and Safari), Google
Docs, Apple Notes and TextEdit: paste a converted table, a converted heading
plus list, and a converted code block; record what survived.

Outlook for Mac is the known-finicky target and the one that decides whether
the RTF path is needed at all.

## CI/CD

Public GitHub repository — macOS runner minutes are free for public repos
and bill at 10x on private ones. It is a portfolio piece regardless.

Two GitHub Actions jobs on every push:

- **core** (ubuntu-latest): `swift build && swift test`. Fast, free, covers
  the majority of the code.
- **mac** (macos-latest): builds `ClipConvertMac`, runs any shell-level
  tests, uploads the `.app` as a workflow artifact.

The artifact is unsigned, so the friend right-clicks and chooses Open the
first time (or clears the quarantine attribute). No Apple Developer account
required at this stage.

Later, notarization can also run on the macOS runner with secrets, meaning
even releases never require owning a Mac.

## Phase 0 — spikes

All three run before real building. Each can fail in a way that reshapes or
kills the project, so none of them are skippable.

**S1. Swift on Windows.** Install the official toolchain. Confirm
`swift build` and `swift test` work on a hello-world SwiftPM package.
*If it fails:* the local feedback loop is gone and the whole approach needs
rethinking. This is the linchpin — run it first.

**S2. Markdown library on Windows.** Does `swift-markdown` (Apple's,
cmark-gfm based) build and run under the Windows toolchain?
*If it fails:* hand-write a parser for the constrained subset actually
needed — tables, headings, bold, italic, lists, inline code, fenced code,
links. This is genuinely tractable and arguably the better answer anyway,
since the input is machine-generated Markdown from three known producers
rather than arbitrary user input.

**S3. HTML → RTF fidelity.** The one that needs the friend. Does
`NSAttributedString(html:)` then `.rtf(from:)` produce a table that survives
a paste into Word and Outlook for Mac?
*If tables break:* fall back to writing only the HTML flavor and let each
destination app do its own conversion — works acceptably in Word, Gmail and
Docs, less reliably in Outlook. *If both break:* the product does not work
and should be abandoned rather than patched. Hand-writing RTF table syntax
(`\cellx` offsets, row prologues) is a known tar pit and is explicitly out
of scope.

Secondary note for S3: `NSAttributedString(html:)` expects a main thread and
has historically been unreliable headless. Whether it runs on a CI runner at
all, or must be verified on the friend's machine, is part of this spike.

## Roadmap

| Phase | Content | Rough effort |
|---|---|---|
| 0 | Spikes S1–S3, repo and CI skeleton | ~1 week |
| 1 | `ClipConvertCore`: detection and Markdown→HTML, full test corpus | ~2 weeks |
| 2 | `ClipConvertMac`: menu bar, hotkey, pasteboard, RTF, undo | ~1–2 weeks |
| 3 | Preferences, launch-at-login, configurable hotkey, preview on uncertain detection | ~1 week |
| 4 | Apple Developer account, signing, notarization in CI, Sparkle updates, .dmg | ~1 week |
| 5 (optional) | v2: rich text → Markdown via JavaScriptCore and turndown.js | ~1 week |

Realistic wall-clock with zero Swift experience and evening availability:
**two to three months** to something shipped.

## Distribution

Direct download plus Sparkle, not the Mac App Store. No 30% cut, no review
friction, and this audience will happily download a `.dmg`. Sandboxing is
not required outside the store, which keeps the pasteboard and hotkey code
simple.

## Risks

**Commercial.** Accepted going in. Free alternatives exist, willingness to
pay for clipboard utilities is low, and the problem is one both Apple and
the AI vendors are motivated to make disappear — a native fix in a macOS
release or a corrected copy button could obsolete this at any time.
Realistic outcome is a portfolio piece and a Product Hunt / HN launch, with
a few hundred to a few thousand euros as a $10–20 one-time app at the
optimistic end.

**Execution.** The real risk. Learning Swift and AppKit simultaneously, with
no local AppKit compiler and blind UI iteration. Mitigated by the core/shell
split — the majority of the code is learned and debugged locally on Windows
with a normal feedback loop, and the blind part is the part with the least
thinking in it.

**Dependency.** The friend is a bottleneck on S3 and on every milestone
checklist. Batching manual checks and front-loading everything testable into
CI keeps the ask to roughly 20 minutes per milestone.

## Known detection limitations

Found by review of the implemented rule (2026-09-20), and accepted rather than
fixed. These convert when arguably they should not:

- **reStructuredText.** RST shares `**bold**` with Markdown and uses `*` for
  list items, so an RST snippet trips block + inline.
- **Changelog and commit-message bullets**, e.g. `- **Fixed**: crash on startup`.
- **Chat transcripts** from tools that use Markdown-ish bold, e.g. a Discord
  paste combining `>` quoting with `**bold**`.

The second case is the reason none of these are fixable: `- **Fixed**: ...` is
textually identical to the most common shape of genuine chatbot output — a
bulleted list with bold labels. Any rule that rejects one rejects the other, so
this false positive is inseparable from the product's primary true positive.

What bounds the damage is the decision that plain text is always preserved as a
pasteboard flavor: a paste into an editor, terminal or any plain-text target
still yields the original source. The cost of a false positive is therefore an
unwanted rich-text paste, undoable, not lost content.

Confirmed *safe* (no signals fire): Jira and Confluence markup, LaTeX, and JSON
or log output containing pipe characters.

Accepted false negatives — real Markdown that will not convert: bare numbered
or bulleted lists with no bold or link (little is lost, since such a list pastes
acceptably as plain text), single-column GFM tables, and answers whose only
inline markup is backticks.

## Decisions taken, for the record

- **No pandoc.** 100MB+ binary, bundling and licensing headache for a menu
  bar utility.
- **No Node or bundled JS runtime.** If v2 needs turndown.js,
  JavaScriptCore is a system framework and the turndown bundle is ~20KB.
- **No auto-paste in v1.** Avoids the Accessibility permission prompt.
- **Public repo.** Free macOS CI minutes; portfolio value.
- **Plain text is always preserved** as a pasteboard flavor after
  conversion, so no conversion is ever lossy from the user's point of view.
