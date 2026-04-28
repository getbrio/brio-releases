---
sidebar_position: 4
---

# Quickstart

From zero to your first BRIO session in five minutes. Assumes a Pro or
Max subscription on your account already.

## 1. Install

```bash
curl -fsSL https://github.com/getbrio/brio-releases/releases/latest/download/install.sh | bash
```

Verify:

```bash
brio --help
```

If `brio: command not found`, add `~/.local/bin` to your `PATH`. See
[Installation](./installation) for details.

## 2. Sign in

```bash
brio login
```

BRIO will:

1. print an 8-character user code (e.g. `ABCD-1234`),
2. open `https://getbrio.org/cli?code=ABCD-1234` in your browser,
3. ask you to sign in with Google and click **Approve**,
4. mint a per-user API key and write `~/.config/brio/config.env`
   (mode `0600`).

You'll see `✓ saved ~/.config/brio/config.env` when the handshake
finishes.

## 3. Run it

From any directory — ideally a ROS 2 workspace you'd like the agent to
reason over:

```bash
cd ~/ros2_ws
brio
```

You're now in the TUI:

```
┌──────────────────────────────────────┐
│ brio — logs: /home/you/.brio.log     │
│                                      │  ← scrollback
├──────────────────────────────────────┤
│ you> _                               │  ← input
├──────────────────────────────────────┤
│                                      │  ← spinner / approval prompt
└──────────────────────────────────────┘
```

## 4. Your first prompt

Try something concrete the agent can answer by reading your workspace:

```
What ROS 2 packages are in this workspace, and which ones build with colcon?
```

Press **Enter**. The spinner row shows `creating answer…`. Within a few
seconds the agent will request to run a tool — typically `bash` (e.g.
`ls src/`) or `read_file` (`package.xml`).

## 5. Approve the first tool call

The spinner row turns into an approval prompt:

```
▸ approve bash: ls src/? [y]es / [n]o / [a]lways bash / [d]eny all bash / [A]ll session
```

Press **`y`** to approve just this call.

After a couple of approve cycles the agent emits its final reply,
rendered as Markdown between `──── brio ────` separators.

**Tip.** Use **`a`** the second time you see a `bash` prompt to
auto-approve all `bash` calls for this session, and **`A`** to
auto-approve everything. Or pass `--yolo` at startup to skip prompts
entirely.

## 6. Wrap up

- `/usage` — token spend so far this session
- `/reset` — wipe agent memory and zero counters before a new task
- `Ctrl-D` (or type `exit`) — quit

Next session, run `brio --continue` to see the previous transcript
above the prompt.

## Where to next

- [Usage & commands](./usage) — every flag, key, and slash command.
- [Privacy & data handling](./privacy) — what leaves your machine.
- [Configuration](./configuration) — env overrides and the ROS 2
  state collector.
