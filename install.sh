#!/bin/bash
# claude-voice-notify — install.sh
# Sets up the plugin: venv, edge-tts, audio generation, and hooks in ~/.claude/settings.json
set -e

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS="$HOME/.claude/settings.json"

case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*|Windows_NT*) VN_OS=windows ;;
  Darwin*) VN_OS=mac ;;
  Linux*)  VN_OS=linux ;;
  *)       VN_OS=unknown ;;
esac

# Windows venvs put binaries in Scripts/ (with .exe); Unix in bin/.
if [ "$VN_OS" = "windows" ]; then
  VENV_BIN_SUBDIR="Scripts"
  EXE=".exe"
  INSTALL_HINT="install Python from https://python.org or via: winget install Python.Python.3.12"
else
  VENV_BIN_SUBDIR="bin"
  EXE=""
  if [ "$VN_OS" = "mac" ]; then
    INSTALL_HINT="install with: brew install python@3.12"
  else
    INSTALL_HINT="install via your package manager (e.g. apt install python3.12 python3.12-venv)"
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  claude-voice-notify — installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── 1. Detect Python 3.10+ ────────────────────────────────────────────────────
PYTHON=$(command -v python3.13 || command -v python3.12 || command -v python3.11 || command -v python3.10 || command -v python3 || command -v python || true)
if [ -z "$PYTHON" ]; then
  echo "✗ Python 3.10+ is required. $INSTALL_HINT"
  exit 1
fi
PY_VER=$("$PYTHON" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 10 ]; }; then
  echo "✗ Python $PY_VER too old. Need 3.10+. $INSTALL_HINT"
  exit 1
fi
echo "✓ Python $PY_VER"

# ── 2. Create venv + install edge-tts ─────────────────────────────────────────
VENV="$PLUGIN_DIR/.venv"
# Keep python3/pip names on Unix (matches pre-Windows behavior); Windows venvs only ship python.exe/pip.exe.
if [ "$VN_OS" = "windows" ]; then
  VENV_PY="$VENV/Scripts/python.exe"
  VENV_PIP="$VENV/Scripts/pip.exe"
else
  VENV_PY="$VENV/bin/python3"
  VENV_PIP="$VENV/bin/pip"
fi

if [ ! -d "$VENV" ]; then
  echo "→ Creating venv..."
  "$PYTHON" -m venv "$VENV"
fi
"$VENV_PIP" install -q --upgrade pip
"$VENV_PIP" install -q edge-tts
echo "✓ edge-tts installed"

# ── 3. Generate audio ─────────────────────────────────────────────────────────
LANG_CODE=$(grep -E "^LANG=" "$PLUGIN_DIR/config.txt" 2>/dev/null | head -1 | sed "s/^LANG=//" | tr -d '[:space:]')
[ -z "$LANG_CODE" ] && LANG_CODE="pt-BR"

echo "→ Generating audio for $LANG_CODE (this may take ~30s)..."
"$VENV_PY" "$PLUGIN_DIR/scripts/generate.py" "$LANG_CODE"
echo "✓ Audio ready"

# ── 4. Make hooks executable ──────────────────────────────────────────────────
if [ "$VN_OS" != "windows" ]; then
  chmod +x "$PLUGIN_DIR/hooks/"*.sh
  chmod +x "$PLUGIN_DIR/hooks/lib/"*.sh 2>/dev/null || true
  echo "✓ Hooks executable"
fi

# ── 5. Patch ~/.claude/settings.json ──────────────────────────────────────────
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

echo "→ Patching $SETTINGS..."
"$VENV_PY" "$PLUGIN_DIR/scripts/patch-settings.py" "$PLUGIN_DIR" "$SETTINGS"
echo "✓ Hooks registered in settings.json"

# ── 6. Copy aliases example if not present ────────────────────────────────────
ALIASES="$PLUGIN_DIR/audio/projects/aliases.txt"
ALIASES_EXAMPLE="$PLUGIN_DIR/audio/projects/aliases.example.txt"
if [ ! -f "$ALIASES" ] && [ -f "$ALIASES_EXAMPLE" ]; then
  cp "$ALIASES_EXAMPLE" "$ALIASES"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation complete!"
echo ""
echo "  Silence all notifications:"
echo "    export VOICE_NOTIFY_OFF=1"
echo ""
echo "  Customize project names:"
echo "    edit $PLUGIN_DIR/audio/projects/aliases.txt"
echo ""
echo "  Change language (pt-BR or en-US):"
echo "    edit $PLUGIN_DIR/config.txt"
echo "    then run: install.sh again to regenerate audio"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
