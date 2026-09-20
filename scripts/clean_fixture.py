"""Reverse the two systematic artifacts in the captured chatbot fixtures.

The capture path introduced two defects that the models did not produce:

  1. Every newline is doubled (CRLF CRLF), which puts a blank line between
     every table row. A GFM table needs consecutive lines, so this alone
     stops the fixtures parsing as tables at all.
  2. Markdown punctuation is backslash-escaped ("\\*\\*Type\\*\\*"), so bold
     markers would render as literal asterisks.

Neither can be what the model emitted, because the table renders correctly
in the chat window. Halving the newlines is lossless precisely because the
doubling is uniform: a real paragraph break arrives as four newlines and
comes back as two.

WHEN YOU NEED THIS
------------------
Adding fixtures to Tests/ClipConvertCoreTests/Fixtures/. Capture an answer
using the chatbot's own copy button -- NOT a mouse selection, which puts
HTML on the clipboard and yields a tab-separated mess with no pipes at all.
Paste into Notepad, save as UTF-8, then run this over the file before
moving it into Fixtures/.

A correctly captured and cleaned table fixture starts:

    | Feature | PostgreSQL | MySQL | SQLite |
    | --- | --- | --- | --- |

Backslashes before punctuation, "&#x20;" entities, or a blank line between
every row mean it has not been cleaned yet. No pipes at all means the
capture itself was wrong -- go back to the copy button.

Usage (python is not on PATH by default on this machine):

    & "$env:LOCALAPPDATA\\Programs\\Python\\Python310\\python.exe" scripts\\clean_fixture.py incoming\\*.md

Do not run it twice over the same file: halving the newlines a second time
would collapse genuine paragraph breaks.
"""

import html
import re
import sys
from pathlib import Path

ESCAPED_PUNCT = re.compile(r"\\([\*#_`\[\]()~+\-.!>|])")


def clean(text: str) -> str:
    text = text.replace("\r\n", "\n").replace("\r", "\n")

    # Halve runs of newlines: "\n\n" -> "\n", "\n\n\n\n" -> "\n\n".
    def halve(match: "re.Match[str]") -> str:
        return "\n" * max(1, len(match.group(0)) // 2)

    text = re.sub(r"\n{2,}", halve, text)

    # The capture path also turned some characters into HTML entities --
    # notably "&#x20;" for the leading spaces that carry list nesting, which
    # is structure we cannot afford to lose.
    text = html.unescape(text)

    text = ESCAPED_PUNCT.sub(r"\1", text)
    return text.strip() + "\n"


def main() -> int:
    paths = [Path(p) for p in sys.argv[1:]]
    if not paths:
        print("usage: clean_fixture.py FILE...", file=sys.stderr)
        return 2

    for path in paths:
        if not path.is_file() or path.stat().st_size == 0:
            print(f"SKIP  {path.name} (missing or empty)")
            continue
        original = path.read_text(encoding="utf-8")
        cleaned = clean(original)
        path.write_text(cleaned, encoding="utf-8", newline="\n")
        print(f"OK    {path.name}: {len(original)} -> {len(cleaned)} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
