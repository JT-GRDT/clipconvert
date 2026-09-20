# Paste fidelity checklist

Thanks for testing. This takes about 5 minutes.

## Setup

1. Download the `rtfprobe` artifact from the latest GitHub Actions run
   (Actions tab → newest run → Artifacts → `rtfprobe`), and unzip it.
2. Open Terminal, in the folder containing the file, and paste this one line:

   ```
   cd ~/Downloads && chmod +x rtfprobe && xattr -d com.apple.quarantine rtfprobe && ./rtfprobe
   ```

   (Adjust `~/Downloads` if you unzipped it somewhere else.) This marks the
   file runnable, removes macOS's "downloaded from the internet" block, and
   runs it. It should print `OK: wrote RTF (...) bytes`. If it hangs for
   more than ten seconds, press Ctrl+C and report that — it is a useful
   result.

## Test

Paste (Cmd+V) into each of these two apps. Do not use Paste and Match Style.

1. **Microsoft Word** — new blank document.
2. **Outlook for Mac** — new message.

Take a screenshot of each and send both back.

### What we're looking for

- A real table with visible gridlines, not just text with tabs.
- The header row is bold.
- The two-line cell ("first line" / "second line") shows as two lines
  inside one cell — not fused into one line, not split into two rows.
- The non-ASCII characters (`—` `€` `'`) look right, not garbled
  (e.g. `â€"` instead of `—`).
- List spacing looks sane — no huge gaps between bullets.

## The one that matters most

Outlook is the answer that matters most. If the table arrives there as a
real table, the project works. If it arrives as runs of text, say so —
that single answer changes the design.

If Word and Outlook both work, we may come back later and ask you to
repeat this with Gmail, Google Docs, Notes, and TextEdit — that's a
deliberate follow-up, not something we forgot now.
