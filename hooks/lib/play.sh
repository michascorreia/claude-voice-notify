#!/bin/bash
# play_audio <file> — cross-platform: afplay (macOS), ffplay/mpg123/paplay/aplay (Linux),
# Windows Media Player via PowerShell (Windows / Git Bash / MSYS / Cygwin).
# Also exports VN_PY (python3 → python fallback) for hooks to use.

if [ -z "$VN_PY" ]; then
  if command -v python3 >/dev/null 2>&1; then
    VN_PY=python3
  elif command -v python >/dev/null 2>&1; then
    VN_PY=python
  else
    VN_PY=python3
  fi
fi

case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*|Windows_NT*) VN_OS=windows ;;
  Darwin*) VN_OS=mac ;;
  Linux*)  VN_OS=linux ;;
  *)       VN_OS=unknown ;;
esac

play_audio() {
  [ -z "$1" ] && return 0
  [ -f "$1" ] || return 0
  case "$VN_OS" in
    mac)
      afplay "$1" >/dev/null 2>&1
      ;;
    linux)
      if command -v ffplay >/dev/null 2>&1; then
        ffplay -nodisp -autoexit -loglevel quiet "$1" >/dev/null 2>&1
      elif command -v mpg123 >/dev/null 2>&1; then
        mpg123 -q "$1" >/dev/null 2>&1
      elif command -v paplay >/dev/null 2>&1; then
        paplay "$1" >/dev/null 2>&1
      elif command -v aplay >/dev/null 2>&1; then
        aplay -q "$1" >/dev/null 2>&1
      fi
      ;;
    windows)
      local root="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-}}"
      local ps1="$root/hooks/lib/_play.ps1"
      [ -f "$ps1" ] || return 0
      local win_ps1 win_file
      if command -v cygpath >/dev/null 2>&1; then
        win_ps1=$(cygpath -w "$ps1")
        win_file=$(cygpath -w "$1")
      else
        win_ps1="$ps1"
        win_file="$1"
      fi
      powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden \
        -File "$win_ps1" "$win_file" >/dev/null 2>&1
      ;;
    *)
      if command -v afplay >/dev/null 2>&1; then
        afplay "$1" >/dev/null 2>&1
      elif command -v ffplay >/dev/null 2>&1; then
        ffplay -nodisp -autoexit -loglevel quiet "$1" >/dev/null 2>&1
      fi
      ;;
  esac
}
