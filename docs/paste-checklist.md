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

## Additional checks

The same paste you already made into Word for the table above also
contains three labelled sections further down, after the bullet list.
Scroll down within that same pasted content and check these too.

| Check | Where to look | What to look for |
|---|---|---|
| Table cell line break | The "Line break in a table cell" section — the one-cell table below it | "first line" and "second line" appear as two separate lines *inside the same cell* — not fused into "first linesecond line" and not split into two rows. |
| Tight bullet list | The "Tight bullet list" section — the three items "one", "two", "three" | No unwanted extra vertical space between bullets — a tight list should not paste with the spacing of a loose (blank-line-separated) list. |
| Non-ASCII characters | The "Non-ASCII characters" section — the paragraph starting "The price went up" | The em dash, euro sign, and curly apostrophes paste intact. Garbled characters (e.g. `â€"` instead of `—`) mean the wrong text encoding was guessed. |

## The one that matters most

Outlook for Mac. If the table arrives as a real table there, the project
works. If it arrives as runs of text, say so — that single answer changes
the design.

Please also paste a screenshot of the Word and Outlook results.
