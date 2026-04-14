#!/bin/bash
# PostToolUse: speaks when categorized commands complete.
# Feature-gated: each KEY maps to a category; plays only if the category is enabled.
# Silence: export VOICE_NOTIFY_OFF=1

[ "$VOICE_NOTIFY_OFF" = "1" ] && exit 0

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PLUGIN_DATA="${CLAUDE_PLUGIN_DATA:-$PLUGIN_ROOT}"
CONFIG_FILE="$PLUGIN_DATA/config.json"

# play_audio <file> — cross-platform: afplay (macOS) or ffplay (Linux)
play_audio() {
  if command -v afplay >/dev/null 2>&1; then
    afplay "$1" >/dev/null 2>&1
  elif command -v ffplay >/dev/null 2>&1; then
    ffplay -nodisp -autoexit -loglevel quiet "$1" >/dev/null 2>&1
  fi
}

# feature_enabled <feature_name> <default_bool: "true"|"false">
feature_enabled() {
  local name="$1"
  local default_bool="$2"
  local default_exit=1 default_py="False"
  if [ "$default_bool" = "true" ]; then default_exit=0; default_py="True"; fi

  [ ! -f "$CONFIG_FILE" ] && return $default_exit

  CONFIG_FILE="$CONFIG_FILE" FEATURE="$name" DEFAULT="$default_py" python3 <<'PY'
import json, os, sys
cfg, name, default = os.environ['CONFIG_FILE'], os.environ['FEATURE'], os.environ['DEFAULT']
try:
    d = json.load(open(cfg))
    v = d.get('features', {}).get(name, default == 'True')
    sys.exit(0 if v else 1)
except Exception:
    sys.exit(0 if default == 'True' else 1)
PY
}

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
[ "$TOOL_NAME" != "Bash" ] && exit 0

COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
IS_ERROR=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_response',{}).get('isError', False))" 2>/dev/null)
INTERRUPTED=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_response',{}).get('interrupted', False))" 2>/dev/null)
CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)

[ "$INTERRUPTED" = "True" ] && exit 0

KEY=""
CATEGORY=""
case "$COMMAND" in
  *"npm run build"*|*"vite build"*|*"npm run build:dev"*|*"pnpm build"*|*"yarn build"*)
    KEY="build"; CATEGORY="build" ;;
  *"playwright test"*|*"npx playwright"*)
    KEY="e2e"; CATEGORY="build" ;;
  *"vitest run"*|*"npm run test"*|*"npm test"*|*"pnpm test"*|*"yarn test"*)
    if echo "$COMMAND" | grep -qE "watch|--watch"; then exit 0; fi
    KEY="tests"; CATEGORY="build" ;;
  *"npm run lint"*|*"eslint ."*|*"eslint src"*|*"pnpm lint"*|*"yarn lint"*)
    KEY="lint"; CATEGORY="build" ;;
  *"tsc --noEmit"*|*"npm run typecheck"*|*"pnpm typecheck"*|*"yarn typecheck"*)
    KEY="typecheck"; CATEGORY="build" ;;
  *"supabase functions deploy"*)
    KEY="deploy"; CATEGORY="git" ;;
  *"supabase db push"*)
    KEY="migration"; CATEGORY="git" ;;
  *"gh pr create"*)
    KEY="pr"; CATEGORY="git" ;;
  *"npx gitnexus analyze"*)
    KEY="gitnexus"; CATEGORY="git" ;;
  *)
    exit 0 ;;
esac

# Feature gate (build and git are OFF by default)
feature_enabled "$CATEGORY" "false" || exit 0

# Language
LANG_CODE="${CLAUDE_PLUGIN_OPTION_LANG:-}"
if [ -z "$LANG_CODE" ] && [ -f "$CONFIG_FILE" ]; then
  LANG_CODE=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('lang',''))" 2>/dev/null)
fi
if [ -z "$LANG_CODE" ] && [ -f "$PLUGIN_ROOT/config.txt" ]; then
  LANG_CODE=$(grep -E "^LANG=" "$PLUGIN_ROOT/config.txt" 2>/dev/null | head -1 | sed "s/^LANG=//" | tr -d '[:space:]')
fi
[ -z "$LANG_CODE" ] && LANG_CODE="pt-BR"
AUDIO_DIR="$PLUGIN_ROOT/audio/$LANG_CODE"

SUFFIX="ok"
[ "$IS_ERROR" = "True" ] && SUFFIX="fail"

AUDIO="$AUDIO_DIR/${KEY}_${SUFFIX}.m4a"
[ ! -f "$AUDIO" ] && exit 0

# Project name audio (opt-in via /voice-notify-setup)
PROJ_AUDIO=""
if feature_enabled "project_name" "false" && [ -f "$PLUGIN_DATA/project-name-enabled" ] && [ -n "$CWD" ]; then
  PROJ_AUDIO=$("$PLUGIN_ROOT/hooks/gen-project.sh" "$CWD" "$PLUGIN_ROOT" "$PLUGIN_DATA" "$LANG_CODE" 2>/dev/null)
fi

if [ -n "$PROJ_AUDIO" ] && [ -f "$PROJ_AUDIO" ]; then
  (play_audio "$PROJ_AUDIO"; play_audio "$AUDIO") &
else
  play_audio "$AUDIO" &
fi

exit 0
