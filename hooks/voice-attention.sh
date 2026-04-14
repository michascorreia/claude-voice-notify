#!/bin/bash
# Notification: speaks when Claude needs permission or is waiting for input.
# Feature-gated: "basic" category (default ON).
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

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PLUGIN_DATA="${CLAUDE_PLUGIN_DATA:-$PLUGIN_ROOT}"
CONFIG_FILE="$PLUGIN_DATA/config.json"

# Feature gate: basic ON by default
if [ -f "$CONFIG_FILE" ]; then
  ENABLED=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('features',{}).get('basic', True))" 2>/dev/null)
  [ "$ENABLED" = "False" ] && exit 0
fi

LANG_CODE=""
if [ -f "$CONFIG_FILE" ]; then
  LANG_CODE=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('lang',''))" 2>/dev/null)
fi
if [ -z "$LANG_CODE" ] && [ -f "$PLUGIN_ROOT/config.txt" ]; then
  LANG_CODE=$(grep -E "^LANG=" "$PLUGIN_ROOT/config.txt" 2>/dev/null | head -1 | sed "s/^LANG=//" | tr -d '[:space:]')
fi
[ -z "$LANG_CODE" ] && LANG_CODE="pt-BR"
AUDIO_DIR="$PLUGIN_ROOT/audio/$LANG_CODE"

INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('message',''))" 2>/dev/null)
CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)

KEY="attention_generic"
case "$MESSAGE" in
  *"permission"*|*"permissao"*|*"approve"*|*"authorize"*) KEY="attention_perm" ;;
  *"waiting"*|*"idle"*|*"input"*)                         KEY="attention_idle" ;;
esac

AUDIO="$AUDIO_DIR/${KEY}.m4a"
[ ! -f "$AUDIO" ] && exit 0

PROJ_AUDIO=""
if [ -f "$CONFIG_FILE" ]; then
  PROJ_ENABLED=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('features',{}).get('project_name', False))" 2>/dev/null)
  if [ "$PROJ_ENABLED" = "True" ] && [ -f "$PLUGIN_DATA/project-name-enabled" ] && [ -n "$CWD" ]; then
    PROJ_AUDIO=$("$PLUGIN_ROOT/hooks/gen-project.sh" "$CWD" "$PLUGIN_ROOT" "$PLUGIN_DATA" "$LANG_CODE" 2>/dev/null)
  fi
fi

if [ -n "$PROJ_AUDIO" ] && [ -f "$PROJ_AUDIO" ]; then
  (play_audio "$PROJ_AUDIO"; play_audio "$AUDIO") &
else
  play_audio "$AUDIO" &
fi

exit 0
