# claude-voice-notify

> Voice notifications for [Claude Code](https://claude.ai/code) — speaks when Claude asks permission, finishes a task, and (optionally) when builds, tests, deploys and destructive commands happen.

Uses pre-generated neural TTS audio (Microsoft Edge — **FranciscaNeural** pt-BR / **JennyNeural** en-US). Zero dependencies for basic use.

## Why this exists

When you use Claude Code for non-trivial tasks, you end up stuck in a loop:

- 👀 Alt-tabbing every few seconds to check if Claude finished
- ⏳ Claude asks for permission and blocks — you only notice minutes later
- 🔁 Builds, tests and deploys force you to babysit the terminal
- 🧠 Your focus breaks on every check, and it takes time to get back in flow

This plugin plays a short neural TTS cue for the events that actually matter, so you can stay focused on something else and come back only when needed.

## Install

```
/plugin marketplace add michascorreia/claude-voice-notify
/plugin install claude-voice-notify@michascorreia
```

That's it. After restarting Claude Code (or running `/reload-plugins`), the plugin speaks by default when:

- Claude needs **permission** or is **waiting** for input
- Claude **finishes** a task (short "Pronto." / "Done.")
- Context is **compacted** automatically

**Platforms:** macOS (uses `afplay`, zero deps), Linux (needs one of `ffplay`/`mpg123`/`paplay`/`aplay`), Windows (needs Git Bash + Windows 10/11 — uses Windows Media Player via PowerShell).

## Configure

Run the config command to toggle categories:

```
/voice-notify-config
```

A checklist appears — enable only what you want:

| Category | Default | What it speaks |
|---|---|---|
| **Básico** | ✅ ON | permission, idle, compacted |
| **Task concluída** | ✅ ON | short "Pronto." when Claude stops |
| **Build & Tests** | ⬜ OFF | build, tests, lint, typecheck, e2e |
| **Git & Deploy** | ⬜ OFF | PR, deploy, migration, gitnexus |
| **Alertas** | ⬜ OFF | `git push main`, `rm -rf`, `db push`, `sudo`, etc. |
| **Nome do projeto** | ⬜ OFF | speaks project name before each cue |

You can also switch language (`pt-BR` / `en-US`) from the same command.

Defaults are intentionally minimal — turn more on only if you miss it. Audio fatigue is real; fewer cues means each one still gets your attention.

## Project name (optional, neural)

To have the plugin say your **project name** (e.g., "Licita Pública") before each notification:

```
/voice-notify-setup
```

This installs Python + `edge-tts` inside the plugin's data directory (persists across updates, isolated from your system). After setup, names are generated once per project on first trigger and cached.

Customize pronunciation in `${CLAUDE_PLUGIN_DATA}/projects/aliases.txt`:

```
my-repo-slug=My Project Name
licita-publica=Licita Pública
```

Useful when you keep multiple Claude Code sessions open — you can tell which project just pinged you.

## Silence all notifications

```bash
export VOICE_NOTIFY_OFF=1
```

Add to your shell profile to persist.

## Detected commands

| Category | Commands |
|---|---|
| Build | `npm run build`, `vite build`, `pnpm build`, `yarn build` |
| Tests | `vitest run`, `npm test`, `pnpm test` |
| E2E | `playwright test`, `npx playwright` |
| Lint | `npm run lint`, `eslint .` |
| Typecheck | `tsc --noEmit`, `npm run typecheck` |
| Deploy | `supabase functions deploy` |
| Migration | `supabase db push` |
| PR | `gh pr create` |
| GitNexus | `npx gitnexus analyze` |
| Alerts | `git push` (main/force), `rm -rf`, `supabase db push/reset`, `sudo`, `npm publish`, `gh release`, `kill -9`, destructive git |

Edit `hooks/voice-notify.sh` or `hooks/voice-alert.sh` to add more.

## Who this is for

**Good fit:**
- 👨‍💻 Devs who live in Claude Code for hours a day
- 🔄 Anyone running long builds/tests and tired of babysitting the terminal
- 🧑‍🚀 People juggling multiple Claude Code sessions (enable "project name" to tell them apart)
- 🎧 Working in a quiet enough environment to hear a short cue

**Not a fit:**
- Anyone always wearing headphones with loud music
- People who find TTS voices annoying (personal preference)
- Linux without any audio player installed (`ffplay`, `mpg123`, `paplay`, or `aplay`)

## Limitations (honest)

- **Player depends on the OS.** macOS uses `afplay` (built in). Linux falls back to `ffplay`/`mpg123`/`paplay`/`aplay` in that order — if none are installed, nothing plays. Windows uses the WMPlayer COM object via PowerShell (Git Bash required to run the bash hooks).
- **No visual fallback.** If you can't hear it, you miss it. There's no system notification fallback.
- **Can become noise if you enable everything.** Start minimal; only enable more categories if you actively miss them.
- **First-time "project name" generation costs ~2-3s** and needs internet (Microsoft Edge TTS). After that, it's cached.
- **Command detection is pattern-matching.** If you run builds via custom aliases or non-standard npm scripts, they may not trigger. Easy to extend in `hooks/voice-notify.sh`.
- **No automated tests yet.** The hooks work, but future refactors need manual verification.
- **Niche audience.** Claude Code plugins are still a new ecosystem.

## Uninstall

```
/plugin uninstall claude-voice-notify@michascorreia
```

## Development

Regenerate audio after editing `scripts/generate.py`:

```bash
./install.sh      # creates venv, installs edge-tts, regenerates audio
```

## License

MIT © [michascorreia](https://github.com/michascorreia)
