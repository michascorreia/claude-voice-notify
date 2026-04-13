# claude-voice-notify

> Voice notifications for [Claude Code](https://claude.ai/code) — speaks when builds, tests, deploys, and migrations complete. Alerts destructive actions before they run.

Uses Microsoft Edge TTS (free, no account needed) with neural voices — **FranciscaNeural** (pt-BR) and **JennyNeural** (en-US).

## What it does

| Hook | Trigger | Example |
|------|---------|---------|
| `PostToolUse` | Build, tests, deploy, lint, typecheck, PR finish | *"Licita Pública. Compilação concluída."* |
| `PreToolUse` | `git push`, `rm -rf`, `supabase db push`, `sudo`, etc. | *"Licita Pública. Cuidado. Remoção recursiva de arquivos."* |
| `PostCompact` | Context auto-compacted by Claude Code | *"Contexto compactado."* |
| `Notification` | Claude waiting for permission or idle | *"Precisa de autorização."* |

**Project name:** Automatically detected from the git repo root. First time in a project, it generates audio in the background — you'll hear it from the second command onwards.

## Requirements

- **macOS** (uses `afplay` and `afconvert`)
- **Python 3.10+** (install with `brew install python@3.12` if missing)
- **Internet** on first run (edge-tts downloads from Microsoft's servers)

## Install

### Option 1 — Claude Code plugin (recommended)

In any Claude Code session:

```
/plugin marketplace add michascorreia/claude-voice-notify
/plugin install voice-notify@michascorreia-claude-voice-notify
```

Then run the setup (creates venv, generates audio, patches settings):

```bash
cd ~/.claude/plugins/voice-notify && ./install.sh
```

Restart Claude Code or open a new session.

### Option 2 — Manual (clone anywhere)

```bash
git clone https://github.com/michascorreia/claude-voice-notify.git
cd claude-voice-notify
./install.sh
```

Then restart Claude Code (or open a new session).

## Customize

### Language

Edit `config.txt`:

```
LANG=en-US   # or pt-BR
```

Then run `./install.sh` again to generate audio for the new language.

### Project name (accents, custom text)

Edit `audio/projects/aliases.txt` (created from `aliases.example.txt` on first install):

```
my-repo-slug=My Project Name
licita-publica=Licita Pública
```

Then delete the cached audio to force regeneration:

```bash
rm audio/projects/my-repo-slug.m4a
```

The new audio is generated automatically on the next hook trigger.

### Silence all notifications

```bash
export VOICE_NOTIFY_OFF=1
```

Add to your shell profile to make permanent.

### Regenerate audio

```bash
# All languages
python3 scripts/generate.py

# Single language
python3 scripts/generate.py pt-BR
python3 scripts/generate.py en-US
```

## Detected commands

| Category | Commands detected |
|----------|------------------|
| Build | `npm run build`, `vite build`, `pnpm build`, `yarn build` |
| Tests | `vitest run`, `npm test`, `pnpm test` |
| E2E | `playwright test`, `npx playwright` |
| Deploy | `supabase functions deploy` |
| Migration | `supabase db push` |
| Lint | `npm run lint`, `eslint .` |
| Typecheck | `tsc --noEmit`, `npm run typecheck` |
| PR | `gh pr create` |
| GitNexus | `npx gitnexus analyze` |

To add more commands, edit `hooks/voice-notify.sh` and add a new `case` entry.

## Uninstall

```bash
./uninstall.sh
```

This removes the hooks from `~/.claude/settings.json`. Audio files and the venv remain — delete the folder to remove everything.

## License

MIT © [michascorreia](https://github.com/michascorreia)
