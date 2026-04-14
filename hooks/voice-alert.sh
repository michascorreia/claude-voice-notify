#!/bin/bash
# PreToolUse: audio alert for destructive/sensitive actions.
# Feature-gated: "alerts" category (default OFF — enable via /voice-notify-config).
# Silence: export VOICE_NOTIFY_OFF=1

[ "$VOICE_NOTIFY_OFF" = "1" ] && exit 0

# play_audio <file> — cross-platform: afplay (macOS) or ffplay (Linux)
play_audio() {
  if command -v afplay >/dev/null 2>&1; then
    afplay "$1" >/dev/null 2>&1
  elif command -v ffplay >/dev/null 2>&1; then
    ffplay -nodisp -autoexit -loglevel quiet "$1" >/dev/null 2>&1
  fi
}

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
[ "$TOOL_NAME" != "Bash" ] && exit 0

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PLUGIN_DATA="${CLAUDE_PLUGIN_DATA:-$PLUGIN_ROOT}"
CONFIG_FILE="$PLUGIN_DATA/config.json"

# Feature gate: alerts OFF by default
if [ -f "$CONFIG_FILE" ]; then
  ENABLED=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('features',{}).get('alerts', False))" 2>/dev/null)
  [ "$ENABLED" != "True" ] && exit 0
else
  exit 0
fi

LANG_CODE=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('lang',''))" 2>/dev/null)
if [ -z "$LANG_CODE" ] && [ -f "$PLUGIN_ROOT/config.txt" ]; then
  LANG_CODE=$(grep -E "^LANG=" "$PLUGIN_ROOT/config.txt" 2>/dev/null | head -1 | sed "s/^LANG=//" | tr -d '[:space:]')
fi
[ -z "$LANG_CODE" ] && LANG_CODE="pt-BR"

AUDIO_DIR="$PLUGIN_ROOT/audio/$LANG_CODE"

COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)

KEY=""
case "$COMMAND" in
  *"git push"*"origin main"*|*"git push"*"main"*|*"git push --force"*|*"git push -f"*)
    KEY="alert_push_main" ;;
  *"git push"*)
    KEY="alert_push" ;;
  *"supabase db reset"*)
    KEY="alert_db_reset" ;;
  *"supabase db push"*)
    if echo "$COMMAND" | grep -q "\-\-local"; then exit 0; fi
    KEY="alert_db_push" ;;
  *"supabase functions deploy"*)
    KEY="alert_func_deploy" ;;
  *"supabase secrets"*|*"supabase link"*)
    KEY="alert_db_prod" ;;
  *"rm -rf"*|*"rm -fr"*)
    KEY="alert_rm_rf" ;;
  *"rm "*)
    if echo "$COMMAND" | grep -qE "rm /tmp/|rm .*cache/"; then exit 0; fi
    KEY="alert_rm" ;;
  *"sudo "*)
    KEY="alert_sudo" ;;
  *"gh pr merge"*)
    KEY="alert_pr_merge" ;;
  *"gh release"*)
    KEY="alert_release" ;;
  *"npm publish"*|*"pnpm publish"*|*"yarn publish"*)
    KEY="alert_publish" ;;
  *"pkill"*|*"kill -9"*)
    KEY="alert_kill" ;;
  *"git reset --hard"*|*"git clean -f"*|*"git checkout ."*|*"git restore ."*|*"git branch -D"*)
    KEY="alert_destructive" ;;
  *)
    exit 0 ;;
esac

AUDIO="$AUDIO_DIR/${KEY}.m4a"
[ ! -f "$AUDIO" ] && exit 0

PROJ_AUDIO=""
PROJ_ENABLED=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('features',{}).get('project_name', False))" 2>/dev/null)
if [ "$PROJ_ENABLED" = "True" ] && [ -f "$PLUGIN_DATA/project-name-enabled" ] && [ -n "$CWD" ]; then
  PROJ_AUDIO=$("$PLUGIN_ROOT/hooks/gen-project.sh" "$CWD" "$PLUGIN_ROOT" "$PLUGIN_DATA" "$LANG_CODE" 2>/dev/null)
fi

if [ -n "$PROJ_AUDIO" ] && [ -f "$PROJ_AUDIO" ]; then
  (play_audio "$PROJ_AUDIO"; play_audio "$AUDIO") &
else
  play_audio "$AUDIO" &
fi

exit 0
