#!/bin/bash
# Generates and caches per-project name audio on demand.
# Usage: gen-project.sh <cwd> <plugin_root> <plugin_data> <lang_code>
# Prints the audio path to stdout (empty if not yet generated — triggers background generation).

CWD="$1"
PLUGIN_ROOT="$2"
PLUGIN_DATA="$3"
LANG_CODE="${4:-pt-BR}"

[ -z "$CWD" ] || [ -z "$PLUGIN_ROOT" ] && exit 0
[ -z "$PLUGIN_DATA" ] && PLUGIN_DATA="$PLUGIN_ROOT"
[ ! -d "$CWD" ] && exit 0

# Detect OS to pick venv layout + output format.
case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*|Windows_NT*) VN_OS=windows ;;
  Darwin*) VN_OS=mac ;;
  *)       VN_OS=linux ;;
esac

# Only announce inside a git repo
if ! git -C "$CWD" rev-parse --show-toplevel >/dev/null 2>&1; then
  exit 0
fi

REPO_ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && REPO_ROOT="$CWD"

# Per-project cache lives in PLUGIN_DATA (persists across updates)
PROJ_DIR="$PLUGIN_DATA/projects"
mkdir -p "$PROJ_DIR"

RAW=$(basename "$REPO_ROOT")
SLUG=$(echo "$RAW" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')
[ -z "$SLUG" ] && exit 0

# macOS keeps the existing .m4a cache; other platforms stream .mp3 from edge-tts directly.
if [ "$VN_OS" = "mac" ]; then
  EXT="m4a"
else
  EXT="mp3"
fi

AUDIO="$PROJ_DIR/${SLUG}.${EXT}"
LOCK="$PROJ_DIR/${SLUG}.lock"

if [ -f "$AUDIO" ]; then
  echo "$AUDIO"
  exit 0
fi

[ -f "$LOCK" ] && exit 0

# Aliases file — check PLUGIN_DATA first (user's custom), fall back to PLUGIN_ROOT example
TEXT=""
for ALIASES in "$PLUGIN_DATA/projects/aliases.txt" "$PLUGIN_ROOT/audio/projects/aliases.txt"; do
  if [ -f "$ALIASES" ]; then
    TEXT=$(grep -E "^${SLUG}=" "$ALIASES" 2>/dev/null | head -1 | sed "s/^${SLUG}=//")
    [ -n "$TEXT" ] && break
  fi
done
[ -z "$TEXT" ] && TEXT=$(echo "$SLUG" | sed 's/[-_]/ /g')

# Resolve edge-tts (user ran /voice-notify-setup which installed it here).
# Unix venvs use bin/; Windows venvs use Scripts/.
EDGE_TTS=""
for CAND in \
  "$PLUGIN_DATA/.venv/bin/edge-tts" \
  "$PLUGIN_DATA/.venv/Scripts/edge-tts.exe" \
  "$PLUGIN_DATA/.venv/Scripts/edge-tts"; do
  if [ -x "$CAND" ] || [ -f "$CAND" ]; then
    EDGE_TTS="$CAND"
    break
  fi
done
[ -z "$EDGE_TTS" ] && exit 0

case "$LANG_CODE" in
  en-US) VOICE="en-US-JennyNeural" ;;
  *)     VOICE="pt-BR-FranciscaNeural" ;;
esac

# Generate in background (non-blocking)
(
  touch "$LOCK"
  if [ "$VN_OS" = "mac" ]; then
    TMP_MP3="$PROJ_DIR/${SLUG}.tmp.mp3"
    "$EDGE_TTS" --voice "$VOICE" --rate "+5%" \
      --text "$TEXT" --write-media "$TMP_MP3" >/dev/null 2>&1
    if [ -f "$TMP_MP3" ]; then
      afconvert -f m4af -d aac "$TMP_MP3" "$AUDIO" >/dev/null 2>&1
      rm -f "$TMP_MP3"
    fi
  else
    # Linux/Windows: write .mp3 directly; players handle both mp3 and m4a.
    "$EDGE_TTS" --voice "$VOICE" --rate "+5%" \
      --text "$TEXT" --write-media "$AUDIO" >/dev/null 2>&1
  fi
  rm -f "$LOCK"
) &

exit 0
