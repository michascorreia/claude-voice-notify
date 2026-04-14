#!/bin/bash
# Stop: speaks a short "done" when Claude finishes responding.
# Silence: export VOICE_NOTIFY_OFF=1

[ "$VOICE_NOTIFY_OFF" = "1" ] && exit 0

source "$(dirname "${BASH_SOURCE[0]}")/lib/play.sh"

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PLUGIN_DATA="${CLAUDE_PLUGIN_DATA:-$PLUGIN_ROOT}"

# Feature gate: task_done is ON by default, disabled only if explicitly set to false
CONFIG_FILE="$PLUGIN_DATA/config.json"
if [ -f "$CONFIG_FILE" ]; then
  ENABLED=$("$VN_PY" -c "import json,sys; d=json.load(open('$CONFIG_FILE')); print(d.get('features',{}).get('task_done', True))" 2>/dev/null)
  [ "$ENABLED" = "False" ] && exit 0
fi

LANG_CODE="${CLAUDE_PLUGIN_OPTION_LANG:-}"
if [ -z "$LANG_CODE" ] && [ -f "$CONFIG_FILE" ]; then
  LANG_CODE=$("$VN_PY" -c "import json; print(json.load(open('$CONFIG_FILE')).get('lang',''))" 2>/dev/null)
fi
if [ -z "$LANG_CODE" ] && [ -f "$PLUGIN_ROOT/config.txt" ]; then
  LANG_CODE=$(grep -E "^LANG=" "$PLUGIN_ROOT/config.txt" 2>/dev/null | head -1 | sed "s/^LANG=//" | tr -d '[:space:]')
fi
[ -z "$LANG_CODE" ] && LANG_CODE="pt-BR"

AUDIO="$PLUGIN_ROOT/audio/$LANG_CODE/task_done.m4a"
[ -f "$AUDIO" ] && play_audio "$AUDIO" &

exit 0
