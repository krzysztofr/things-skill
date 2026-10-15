#!/usr/bin/env bash
# Add a to-do to Things 3 via the things:///add URL scheme.
# Usage: add.sh model="..." title="..." list="..." when="..." [key=value ...]
# Any Things "add" parameter works: notes, deadline, tags, heading,
# checklist-items. Newlines in checklist-items separate items.
# model= is not sent to Things; it goes into the "Added with" footer.
# Inside a Claude Code session, non-empty notes get session name + dir lines.
# Bash 3.2 compatible (macOS /bin/bash): no associative arrays.
set -euo pipefail

[[ $# -gt 0 ]] || { echo 'usage: add.sh model="..." title="..." list="..." when="..." [key=value ...]' >&2; exit 2; }

ARGS=(--arg reveal false)
SEEN=" "
NOTES=""
MODEL=""
for kv in "$@"; do
  [[ "$kv" == *=* ]] || { echo "not key=value: $kv" >&2; exit 2; }
  key=${kv%%=*}
  val=${kv#*=}
  [[ "$key" =~ ^[a-z-]+$ ]] || { echo "bad key: $key" >&2; exit 2; }
  if [[ -n "$val" ]]; then SEEN+="$key "; fi
  case "$key" in
    notes) NOTES=$val ;;
    model) MODEL=$val ;;
    *) ARGS+=(--arg "$key" "$val") ;;
  esac
done
for req in model title list when; do
  [[ "$SEEN" == *" $req "* ]] || { echo "$req is required" >&2; exit 2; }
done

# Session name (custom title, else AI title, else id) and the directory the
# session started in, read from the transcript.
# ponytail: relies on undocumented transcript JSONL fields (custom-title,
# ai-title, cwd); falls back to id + $PWD if they change.
if [[ -n "$NOTES" && -n "${CLAUDE_CODE_SESSION_ID:-}" ]]; then
  SID=$CLAUDE_CODE_SESSION_ID
  NAME=$SID
  DIR=$PWD
  for t in "$HOME"/.claude/projects/*/"$SID".jsonl; do
    [[ -f "$t" ]] || continue
    INFO=$(jq -rn 'reduce inputs as $e ({};
             .cwd //= $e.cwd
             | if $e.type == "custom-title" then .ct = $e.customTitle
               elif $e.type == "ai-title" then .at = $e.aiTitle else . end)
           | "\(.ct // .at // "")\t\(.cwd // "")"' "$t" 2>/dev/null || true)
    if [[ -n "${INFO%%$'\t'*}" ]]; then NAME=${INFO%%$'\t'*}; fi
    if [[ -n "${INFO#*$'\t'}" ]]; then DIR=${INFO#*$'\t'}; fi
  done
  # Continue a trailing markdown list, else start one after a blank line.
  LAST=${NOTES##*$'\n'}
  if [[ "$LAST" == "- "* ]]; then NOTES+=$'\n'; else NOTES+=$'\n\n'; fi
  NOTES+="- Session: $NAME"$'\n'"- Session dir: $DIR"
fi
FOOTER="Added with Claude Code ($MODEL, $(TZ=Europe/Warsaw date '+%Y-%m-%d %H:%M %Z'))"
if [[ -n "$NOTES" ]]; then NOTES+=$'\n\n'"$FOOTER"; else NOTES=$FOOTER; fi
ARGS+=(--arg notes "$NOTES")

QUERY=$(jq -rn "${ARGS[@]}" '$ARGS.named | to_entries | map("\(.key)=\(.value|@uri)") | join("&")')
open -g "things:///add?$QUERY"
echo "sent: things:///add?$QUERY"
