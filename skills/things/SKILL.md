---
name: things
description: Use when the user asks to be reminded about something - "remind me to...", "remind me tomorrow...", "add a reminder" - or explicitly asks to add a task / to-do to Things ("add to Things", "/things"). Exception - a "remind me" tied to the current session's own work with no future time (revert this, remove that temporary rule) is tracked in the session, not sent to Things. Do NOT use for "notify me" requests - those go to notification skills.
---

# things

Adds a to-do to Things 3 on this Mac through the `things:///add` URL
scheme. Local only, no token, no network.

## Things or the session?

- Things: the reminder points past this session (a date, "tomorrow",
  "next week", a follow-up), or is unrelated to the session's work
  ("remind me to buy milk"), or the user names Things.
- Session: the reminder is about the current session's own work and has no
  future time ("remind me to remove the firewall exception" while adding
  it). Do not call Things - keep it and raise it before claiming the task
  done or when the user wraps up.

## Pick the list - always

1. Read `~/.config/things/lists.md`. It holds `Default <kind>:` lines
   (e.g. `Default personal:`, `Default work:`) and one
   `## <exact list name>` section per project/area with clues on when to
   use it. If the file is missing, stop and tell the user to create it from
   `lists.example.md` in the repo - never send a to-do without a list.
2. Match the task (its wording plus conversation context, e.g. the current
   working directory, repo owner) against the clues. User naming a list
   explicitly wins.
3. No list fits: decide which kind the task is (work vs personal, from the
   same context) and use that `Default <kind>:` list.
4. Two lists fit equally: pick one, name it in the confirmation.

Use the list name exactly as written in the file, emoji included - Things
matches it literally and silently falls back to Inbox on a mismatch.

## Set the time - always

Every to-do gets `when`. No time given: `when=today`.

- `today`, `tomorrow`, `evening`, `YYYY-MM-DD`, or `YYYY-MM-DD@HH:MM` for an
  alert ("remind me in 45 min" = today at now + 45 min).
- `someday` / `anytime` only when the user says so explicitly.
- All user times are Warsaw local time. Resolve relative phrases ("next
  Friday", "in 3 days", "end of month") to `YYYY-MM-DD` yourself from `date`
  output - do not pass natural language to Things. "Tonight" = `evening`.

## Title, notes, checklist

Title: short, actionable, verb first.

Notes - test: can the user act on this in a week, without this session?

- Self-contained title ("Buy milk", "Call the accountant about VAT"): no
  notes.
- To-do comes out of session work: notes, max ~8 lines. Prose first
  (what and why, plus the next step or exact command if known), then the
  task's attributes as a markdown list, one `- Label: value` per line,
  only those that apply:
  - `- Repo: <path>`
  - `- PR: #<n>` / `- Linear: <ID>` / `- Issue: #<n>`
  - `- URL:`, `- Host:`, `- Env:` (environment only if known from the
    project's declared mapping, never guessed from a name)
- Whatever the user explicitly asks to note always goes in.
- Never put secrets, tokens, passwords or credentials in notes - Things
  syncs to Things Cloud.

`add.sh` adds the rest itself - do not write these lines:
- to non-empty notes: `- Session: <name>` (the user's session rename, else
  the auto title) and `- Session dir: <dir the session started in>`;
- to every to-do: footer `Added with Claude Code (<model>, <date time>)`.

Example notes (as passed to `add.sh`):

```
Deployed the new auth flow to prod today. Run the smoke tests and check
error rates before announcing.

- Repo: ~/work/foo
- PR: #42
- Linear: FOO-123
```

Checklist instead of notes when the task naturally has 2+ steps.

Other optional params, only when the user mentions them:

| Param | Values |
|-------|--------|
| `deadline` | `YYYY-MM-DD` |
| `tags` | comma-separated; must already exist in Things, unknown tags are dropped silently |
| `heading` | exact heading name inside the chosen project |

## Send

Run `add.sh` from this skill's base directory (Claude Code prints "Base
directory for this skill" when the skill loads). Pass each field as one
`key=value` argument; use `$'...'` quoting for newlines. `model` is your
own model name (e.g. `Claude Opus 5.5`); it only feeds the footer:

```sh
"<base directory>/add.sh" model="Claude Opus 5.5" title="Test prod deployment" \
  list="🏢 Praca" when=2026-10-16 \
  notes=$'Deployed today. Run smoke tests before announcing.\n\n- Repo: ~/work/foo\n- PR: #42' \
  checklist-items=$'Smoke test login\nCheck error logs'
```

`add.sh` refuses a call without `model`, `title`, `list` or `when`.

Exit 0 means the URL was handed to Things - not that the to-do was
verified (the scheme returns nothing). Confirm in one line: title, list,
when (and deadline if set), phrased as "sent", not "added and verified".
Non-zero exit: quote the error and stop.

## Notes

- One `add.sh` call per to-do. Several tasks = several calls.
- Add only. Reading, completing or editing to-dos is out of scope.
- If to-dos never appear: Things > Settings > General > Enable Things URLs.
