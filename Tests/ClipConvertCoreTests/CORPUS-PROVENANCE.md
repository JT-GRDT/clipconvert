# Corpus provenance

## Positive fixtures (`Fixtures/*.md`)

The nine `.md` files in `Fixtures/` are real answers from ChatGPT, Claude and
Gemini, captured on Windows using each product's own copy button (not a text
selection) for three prompts:

1. "Compare Postgres, MySQL and SQLite in a table with at least four rows."
2. "Explain git rebase with a numbered list and a code example."
3. "Summarise the causes of WW1 with headings and sub-bullets."

Windows's clipboard HTML path introduced two mechanical artifacts on the way
from each chatbot's rendered answer back to Markdown text:

- every newline was doubled, and
- Markdown punctuation characters were backslash-escaped (e.g. `\*`, `\-`,
  `\&`).

These two artifacts were mechanically reversed before the files were saved:
newline runs were halved, HTML entities were unescaped, and backslashes
immediately preceding Markdown punctuation were stripped. **The fixtures are
therefore not byte-exact clipboard captures** — they are the best
reconstruction of the original Markdown obtainable from what the clipboard
handed back.

One artifact could not be fully reversed: nested list indentation arrived as
a single `&#x20;` (one non-breaking-adjacent space) regardless of nesting
depth, so sub-bullets that were indented two or four spaces in the original
answer are under-represented in these fixtures — several render as flat
sibling list items rather than a nested `<ul>`. This is visible in, for
example, `nested-headings-chatgpt.md` and `nested-headings-gemini.md`. It is
a property of the capture pipeline, not an editorial cleanup, and it has been
left as-is because reproducing it is the point of this corpus.

Beyond the two reversals above, file content was not otherwise edited.

## Negative corpus (`Negative/*.txt`)

The six `.txt` files in `Negative/` are synthetic, written from scratch for
this repository. They contain no real source code, credentials, hostnames,
paths, names or email addresses — only plausible, invented content shaped
like the real thing (comment markers, list-like lines, pipe-delimited log
fields, a dashed banner/separator) so they exercise the same detection paths
that real files would, without any file in this public repository containing
genuine third-party data.
