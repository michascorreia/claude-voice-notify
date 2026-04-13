---
description: Configure voice notifications — toggle categories (basic, task done, build, git, alerts, project name) and language.
---

You are helping the user configure the **claude-voice-notify** plugin.

## Setup

Resolve the data directory once at the start:

```bash
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugins/data/claude-voice-notify-michascorreia}"
```

Use `$DATA_DIR` throughout (not `$DATA_DIR`) because the env var may not be set when a skill runs.

## Steps

1. **Read the current config** from `$DATA_DIR/config.json`. If the file doesn't exist, use these defaults:
   ```json
   {
     "lang": "pt-BR",
     "features": {
       "basic": true,
       "task_done": true,
       "build": false,
       "git": false,
       "alerts": false,
       "project_name": false
     }
   }
   ```

2. **Show the user a checklist** with the current state, like this (use ✅ for enabled, ⬜ for disabled):

   ```
   🔊 Voice Notify — Configuração

   Idioma: pt-BR

   Categorias:
     1. ✅ Básico           — permissão, idle, contexto compactado
     2. ✅ Task concluída   — som curto quando Claude termina
     3. ⬜ Build & Tests    — build, testes, lint, typecheck
     4. ⬜ Git & Deploy     — PR, deploy, migração, gitnexus
     5. ⬜ Alertas          — git push main, rm -rf, db push, sudo
     6. ⬜ Nome do projeto  — fala o nome do projeto (requer /voice-notify-setup)

   Envie os números das categorias que deseja ALTERNAR (ex: "3 5"),
   ou "idioma pt-BR" / "idioma en-US" para mudar o idioma,
   ou "salvar" para confirmar, ou "cancelar" para sair.
   ```

3. **Wait for user input**. Parse the input:
   - Numbers (e.g., `3 5`): toggle those categories
   - `idioma pt-BR` or `idioma en-US`: change language
   - `salvar` / `save`: write config and exit
   - `cancelar` / `cancel`: discard changes
   - Loop back to step 2 showing updated state until the user saves or cancels

4. **When saving**:
   - Ensure `$DATA_DIR` directory exists (`mkdir -p`)
   - Write the JSON to `$DATA_DIR/config.json` with 2-space indentation
   - Confirm to the user: "✓ Configuração salva. As mudanças valem pra nova sessão do Claude Code."
   - If `project_name` was just enabled but `$DATA_DIR/project-name-enabled` doesn't exist, tell the user: "⚠️ Pra usar nome do projeto, rode `/voice-notify-setup` (instala Python + edge-tts)."

## Important

- Read/write files using the Bash tool (`cat`, `mkdir -p`, write JSON with `python3 -c`).
- Map keys: 1=basic, 2=task_done, 3=build, 4=git, 5=alerts, 6=project_name.
- Keep the UI in Portuguese (Brazilian) by default; switch to English if the user's language preference is en-US.
- Never modify anything outside `$DATA_DIR`.
