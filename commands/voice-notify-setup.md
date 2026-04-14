---
description: Install edge-tts in the plugin data dir so voice-notify can speak project names (neural TTS, requires Python 3.10+ and internet).
---

You are helping the user install the optional **project name** feature of `claude-voice-notify`. This uses Microsoft Edge TTS (free, neural voices) to say the project name before each notification.

## Setup

Resolve paths once at the start:

```bash
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/claude-voice-notify-michascorreia}"
ROOT_DIR="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/plugins/cache/michascorreia/claude-voice-notify/1.0.0}"
```

Use `$DATA_DIR` and `$ROOT_DIR` throughout.

## Steps

1. **Explain what will happen** and confirm:
   - "Vou configurar a fala do nome do projeto. Isso requer Python 3.10+ e internet na primeira vez. Posso seguir?"
   - If the user declines, stop.

2. **Detect Python 3.10+** via Bash (Windows uses `python`, Unix uses `python3`):
   ```bash
   command -v python3.13 || command -v python3.12 || command -v python3.11 || command -v python3.10 || command -v python3 || command -v python
   ```
   If none found or version < 3.10, tell the user: "❌ Python 3.10+ não encontrado. Instale com `brew install python@3.12` (macOS), pelo gerenciador do Linux, ou de python.org / `winget install Python.Python.3.12` (Windows)." and stop.

3. **Create venv and install edge-tts** inside `$DATA_DIR` (persistent across plugin updates). The venv binary layout differs by OS — detect it:
   ```bash
   VENV="$DATA_DIR/.venv"
   mkdir -p "$DATA_DIR"
   "$PY" -m venv "$VENV"   # $PY = whichever was found in step 2
   case "$(uname -s 2>/dev/null)" in
     MINGW*|MSYS*|CYGWIN*|Windows_NT*) BIN="Scripts"; EXE=".exe" ;;
     *) BIN="bin"; EXE="" ;;
   esac
   "$VENV/$BIN/pip${EXE}" install -q --upgrade pip
   "$VENV/$BIN/pip${EXE}" install -q edge-tts
   ```

4. **Enable the feature flags**:
   - Touch the flag file: `touch "$DATA_DIR/project-name-enabled"`
   - Update `$DATA_DIR/config.json` — set `features.project_name = true` (preserve other fields; create file with defaults if absent).

5. **Copy aliases example** so the user can customize project names:
   - If `$DATA_DIR/projects/aliases.txt` doesn't exist, copy `$ROOT_DIR/audio/projects/aliases.example.txt` to it.
   - Show the path and tell the user: "Edite esse arquivo pra customizar como o nome sai falado (ex: `meu-repo=Meu Projeto`)."

6. **Confirm** to the user:
   - "✓ Pronto! Na próxima vez que um hook tocar dentro de um repositório git, o nome do projeto será falado antes. Primeira vez por projeto pode demorar alguns segundos pra gerar."

## Notes

- Always use `$DATA_DIR` (NOT `$ROOT_DIR`). The venv must survive plugin updates.
- Never run `pip install` outside the venv.
- If pip install fails (no internet, etc), report the error and leave no half-state.
- Windows venvs put binaries in `Scripts/` with `.exe`; Unix venvs use `bin/`. `gen-project.sh` already probes both, but your install step must write to the correct one.
