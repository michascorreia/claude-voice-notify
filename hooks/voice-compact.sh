#!/bin/bash
# PostCompact: speaks when context is auto-compacted.
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

AUDIO="$PLUGIN_ROOT/audio/$LANG_CODE/compact_done.m4a"
[ -f "$AUDIO" ] && play_audio "$AUDIO" &

exit 0
