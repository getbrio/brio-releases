---
sidebar_position: 5
---

# Usage & Commands

Reference for flags, slash commands, keybindings, and the approval
prompt the `brio` CLI emits.

## Command-line flags

```bash
brio [--url URL] [--robot-id ID] [--yolo] [--continue] [-v] [--prod]
brio login [--no-browser]
brio logout
```

| Flag | Default | Purpose |
| --- | --- | --- |
| `--url` | `https://api.getbrio.org` (or `$BRIO_API_URL`) | Cloud API endpoint. Useful for staging. |
| `--robot-id` | `dev-robot` (or `$BRIO_ROBOT_ID`) | Robot identifier. Pairs your CLI session with a `RobotState` stream from the same id. |
| `--yolo` | off | Auto-approve every tool call. Skips all `bash` / `read_file` / `write_file` prompts. |
| `--continue` | off | Print the previous session transcript above the prompt at startup. |
| `-v`, `--verbose` | off | Mirror loguru output to stderr. Logs always go to `~/.brio.log` regardless. |
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
| `/usage` | Token usage since process start: fresh / cache-write / cache-read input tokens, output tokens, request count, tool-call count. |
| `/reset` | Delete the cloud session for this `robot-id` *and* zero local usage counters. Use between unrelated tasks. |
| `/quit` | Exit (same as `Ctrl-D` or typing `exit` / `quit`). |

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

When the agent wants to run a tool, the spinner row turns into a
prompt like:

```
▸ approve bash: colcon build --packages-select my_pkg? [y]es / [n]o / [a]lways bash / [d]eny all bash / [A]ll session
```

| Choice | Effect |
| --- | --- |
| `y` / `yes` | Approve this single call. |
| `n` / anything else | Deny this single call. |
| `a` | Approve **this type** (`bash` / `read_file` / `write_file`) for the rest of the session. |
| `d` | Deny **this type** for the rest of the session. |
| `A` (capital) | Approve **all tool types** for the rest of the session. |
| `Ctrl-C` | Deny without committing to a policy. |

Pre-approval flags (`a`, `A`, `--yolo`) and pre-denials (`d`) only
apply to the current `brio` process; they reset on exit.

## Tool calls the agent can request

| Type | Payload | Locally executed by | Limits |
| --- | --- | --- | --- |
| `bash` | argv list (no shell) | `subprocess.run(..., capture_output=True)` | 25 s timeout, stdout+stderr truncated to 200 lines. |
| `read_file` | file path | `Path(path).read_text()` | Warning injected if file > 2000 lines. |
| `write_file` | file path + content | `Path(path).write_text()`, parents created with `mkdir -p`. | None (be careful with `--yolo`). |

Anything outside this set is rejected client-side. The agent never
gets shell access — it only gets the argv list it asked for.

## Query size

The CLI rejects single prompts estimated above ~1500 tokens (~6000
characters) before sending. Trim or split.

## Local files

| Path | What |
| --- | --- |
| `~/.config/brio/config.env` | API key + URL. Written by `brio login`, mode `0600`. |
| `~/.brio.log` | Rotating loguru log (10 MB, 3 retained). Always written. |
| `~/.brio_history` | Input history for `Up`/`Down`. |
| `~/.brio_last_session` | Transcript saved on exit; restored by `--continue`. |
