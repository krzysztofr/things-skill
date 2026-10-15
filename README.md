# things-skill

A [Claude Code](https://claude.com/claude-code) skill that turns "remind me
to..." into a to-do in [Things 3](https://culturedcode.com/things/) on your
Mac - e.g. "remind me to test the prod deployment tomorrow".

Uses the local `things:///add` URL scheme: no token, no network. Claude picks
the Things project/area from your own list of clues, resolves dates like
"next Friday", and writes notes good enough to act on a week later -
including the name and directory of the Claude Code session the reminder
came from, so you can resume it.

## Requirements

- macOS with Things 3
- `jq`
- Things > Settings > General > Enable Things URLs (if to-dos do not appear)

## Installation

1. Install as a Claude Code plugin (the repo is its own marketplace):

   ```sh
   claude plugin marketplace add krzysztofr/things-skill
   claude plugin install things@things-skill
   ```

   Update later with `claude plugin update things`.

   Alternative for hacking on it - clone and symlink as a plain skill:

   ```sh
   git clone https://github.com/krzysztofr/things-skill.git ~/work/things-skill
   ln -s ~/work/things-skill/skills/things ~/.claude/skills/things
   ```

   Do not use both at once or Claude sees the skill twice.

2. Describe your lists:

   ```sh
   mkdir -p ~/.config/things
   cp lists.example.md ~/.config/things/lists.md
   ```

   Edit it: one `## <exact list name>` section per Things project or area,
   with plain-language clues on when to use it, and `Default <kind>:` lines
   (e.g. `Default personal:`, `Default work:`) for tasks that fit no
   section. Names must match Things exactly, emoji included, or the to-do
   lands in the Inbox. The file lives outside the plugin so updates never
   overwrite it.

3. Test:

   ```sh
   skills/things/add.sh model=manual title="Test things-skill" list="<one of your lists>" when=today
   ```

   Expected: `sent: things:///add?...`, exit code 0, and the to-do in Today.

## Usage

- "remind me to call the accountant on Friday"
- "remind me to check this PR's CI tomorrow at 9" (to-do with an alert)
- "add to Things: renew passport, deadline end of month"
- `/things renew passport` (plain skill) or `/things:things ...` (plugin)

Every to-do gets a list (your clues, else the matching default) and a date
(`today` unless you say otherwise). A "remind me" about the current
session's own work with no future time ("remind me to remove this firewall
exception") stays in the session instead.

Notes are added only when the title is not enough on its own: a short
prose part (what, why, next step), then a markdown list of handles (repo,
PR, Linear / GitHub issue, URL) plus the session name (your rename, else
the auto title) and the directory the session started in - the one to run
`claude --resume` from, which is not always the repo (e.g. worktrees).
Every to-do ends with `Added with Claude Code (<model>, <date time>)`.
Secrets never go in notes - Things syncs to Things Cloud.

Session name and directory are read from Claude Code's transcript files,
an undocumented format; if it changes, the script falls back to the
session id and the current directory. A rename made after the to-do was
sent is not reflected.

The skill confirms with title, list and date. The URL scheme returns no
result, so "sent" means handed to Things, not verified.

"notify me" requests are deliberately left to notification skills.

## Limitations

- Add only - no reading, completing or editing to-dos.
- Tags must already exist in Things; unknown tags are dropped silently.
