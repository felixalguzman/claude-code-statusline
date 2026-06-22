# Claude Code Statusline

Powerline-style status line for [Claude Code](https://claude.com/claude-code). Reads the session JSON on stdin and prints one line of background-filled segments.

![style: powerline](https://img.shields.io/badge/style-powerline-blue)

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
