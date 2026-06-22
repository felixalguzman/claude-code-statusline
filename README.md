# Claude Code Statusline

Powerline-style status line for [Claude Code](https://claude.com/claude-code). Reads the session JSON on stdin and prints one line of background-filled segments.

![style: powerline](https://img.shields.io/badge/style-powerline-blue)

![preview](preview.png)

## Segments

- **Profile** — `WORK` (red) / `PERSONAL` (blue), chosen from `CLAUDE_CONFIG_DIR`
- **Caveman mode** — shown when a `.caveman-active` flag file exists, with level
- **Directory** — basename of cwd
- **Git** — branch (`*` if dirty) + remote repo path, tagged `gh`/`gl`/`git`
- **Model** — display name
- **Lines changed** — `+added -removed`
- **Cost** — session cost in USD
- **Context window** — 10-cell bar + `%`, color by usage, `⚠200k` flag
- **Rate limits** — 5h / 7d subscription windows with reset countdown

Narrow terminals wrap onto a second line (identity row / metrics row).

## Optional segments

A couple of segments depend on your personal setup and simply skip themselves if the inputs aren't present — the script still runs fine without them:

- **Profile** reads the `CLAUDE_CONFIG_DIR` env var. A path containing `claude-work` shows `WORK`; anything else shows `PERSONAL`. Unset → `PERSONAL`.
- **Caveman mode** reads an optional flag file `$CLAUDE_CONFIG_DIR/.caveman-active` (falls back to `~/.claude/.caveman-active`). It holds a single level word (`lite`/`full`/`ultra`/…) and is written by the [caveman](https://github.com/anthropics/skills) Claude Code skill. No file → segment hidden. Not using caveman → ignore it.

No Claude Code skills or MCP servers are required to run the status line.

## Requirements

- `bash`
- `jq`
- `git`
- A **Nerd Font / Powerline font** in the terminal (for the `` arrow + glyphs)

## Install

```sh
mkdir -p ~/.claude-work
curl -fsSL https://raw.githubusercontent.com/felixalguzman/claude-code-statusline/main/statusline.sh \
  -o ~/.claude-work/statusline.sh
chmod +x ~/.claude-work/statusline.sh
```

Then point Claude Code at it in `settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /home/YOU/.claude-work/statusline.sh"
  }
}
```

Adjust the path to wherever you saved the script.

## License

MIT
