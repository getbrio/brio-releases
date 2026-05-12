---
sidebar_position: 5
---

# Usage & Commands

Reference for flags, slash commands, keybindings, and the approval
prompt the `brio` CLI emits.

## Command-line flags

```bash
brio [--yolo] [--continue] [-v] [--debug] [--no-upgrade-check] [--prod]
brio login [--no-browser]
brio logout
```

| Flag | Default | Purpose |
| --- | --- | --- |
| `--yolo` | off | Auto-approve every tool call. Bypasses both the verb gate and the directory-sandbox gate. |
| `--continue` | off | Restore the previous session transcript and reuse its `session_id`. |
| `-v`, `--verbose` | off | Also stream INFO+ logs to stderr. Per-session JSON logs are always written. |
| `--debug` | off | Stream all DEBUG+ logs to stderr; the TUI also opens a debug pane. |
| `--no-upgrade-check` | off | Skip the startup call to `/v1/cli/latest-version`. |
| `--prod` | off | Dev-only. Read `.env.prod` from cwd instead of `.env.local`. |

### Subcommands

- `brio login` — RFC 8628 device-authorization flow. Writes
  `$XDG_CONFIG_HOME/brio/config.env` (`~/.config/brio/config.env`) at
  mode `0600`. `--no-browser` suppresses auto-open of the approval URL.
- `brio logout` — delete that config file.

## Slash commands

Type a `/` in the input row and the spinner row above it shows matches.
**`Tab`** completes the top match.

| Command | Effect |
| --- | --- |
| `/help` | List commands. |
| `/usage` | Token usage since process start plus the per-user 5h rolling-window snapshot. |
| `/clear` | Drop conversation history and per-turn state. Keeps `session_id` and token totals. |
| `/compact [focus]` | Summarize history into one block via a Haiku-backed summarizer. Optional `[focus]` steers what to keep. |
| `/reset` | Wipe the cloud session *and* zero local usage counters. Use between unrelated tasks. |
| `/sendlogs` | Upload this session's log file to support for debugging. |
| `/quit` | Exit (same as `Ctrl-D` or typing `exit` / `quit`). |

:::warning Copying text from the TUI

The TUI captures the mouse for scrollback, so a normal click-drag
**will not** select text. To copy from the log buffer, **hold `Shift`
while you click-drag** (or `Shift` + double-click for a word). Then
copy with your terminal's usual shortcut (`Cmd-C` on macOS,
`Ctrl-Shift-C` on most Linux terminals).

> 📋 **`Shift` + drag to select. Without `Shift`, the mouse scrolls
> instead of selecting.**

:::

## Keybindings

| Key | Action |
| --- | --- |
| `Enter` | Submit the current line. If an approval prompt is active, the line is the answer instead. |
| `Up` / `Down` | Walk through input history (`~/.brio_history`). |
| `Tab` | Complete the current slash command. |
| `PgUp` / `PgDn` | Scroll the log buffer 10 lines. Mouse wheel works too. |
| `Ctrl-Home` | Jump to the top of the log. |
| `Ctrl-End` | Jump back to the live tail. |
| `Ctrl-C` | If an approval prompt is open: deny it. Otherwise: exit. |
| `Ctrl-D` | Exit. |

## Approval prompts

Two independent gates fire before any tool runs:

**1. Verb gate** — per tool type. When the agent wants to run a tool,
the spinner row turns into:

```
▸ approve bash: colcon build --packages-select my_pkg? [y]es / [n]o / [a]lways bash / [d]eny all bash / [A]ll session
```

| Choice | Effect |
| --- | --- |
| `y` / `yes` | Approve this single call. |
| `n` / anything else | Deny this single call. |
| `a` | Approve **this type** for the rest of the session. |
| `d` | Deny **this type** for the rest of the session. |
| `A` (capital) | Approve **all tool types** for the rest of the session. |
| `Ctrl-C` | Deny without committing to a policy. |

**2. Directory gate** — per filesystem path. When a tool touches a
directory outside the CLI's startup `cwd`, you get:

```
▸ approve directory access: /opt/ros/humble — [y]es once / [n]o / [a]lways this dir
```

`a` is recursive: approving `/a/b` grants `/a/b/**` for the rest of the
session. The `[A]ll-session` verb shortcut does **not** bypass this
gate — only `--yolo` does. Directories named in your prompt are
auto-approved at turn start.

All gates reset on process exit.

## Tool calls the agent can request

The agent emits structured events; the CLI executes them locally. The
agent never gets a shell.

**ROS 2 / build** — preferred, typed:
`ros2` (e.g. `ros2 topic echo /scan`), `colcon` (e.g. `colcon build`).

**Filesystem**:
`read_file`, `write_file`, `apply_patch`, `list_dir`, `which`, `mkdir`,
`rm`, `cp`, `mv`.

**Shell escape** (last resort):
`bash` — runs `bash -c <command>`. 25 s default timeout, output
truncated to 200 lines.

**Composite**:
`batch` — one approval covers a list of sub-events that share an
intent. The TUI unwraps the result so you see each sub-call's output.

Anything outside this set is rejected client-side.

## Query size

The CLI rejects single prompts estimated above ~1500 tokens (~6000
characters) before sending. Trim or split.

## Local files

| Path | What |
| --- | --- |
| `~/.config/brio/config.env` | API key + URL. Written by `brio login`, mode `0600`. |
| `~/.local/share/brio/logs/{date}/{session_id}.log` | Per-session JSON log (loguru). |
| `~/.brio_history` | Input history for `Up`/`Down`. |
| `~/.brio_last_session` | Transcript saved on exit; restored by `--continue`. |
| `~/.brio_last_session_id` | Session id reused by `--continue`. |
