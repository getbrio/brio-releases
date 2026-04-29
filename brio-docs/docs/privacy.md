---
sidebar_position: 6
---

# Privacy & Data Handling

BRIO's agent runs in our cloud; the tools the agent uses run on your
machine. This page is the explicit list of what crosses that boundary.

## What leaves your machine

Everything sent to the BRIO API is over TLS to `api.getbrio.org` (or
the `--url` you configure), authenticated with the API key in
`~/.config/brio/config.env`.

### When you submit a prompt

`POST /v1/debug` with:

- the prompt text you typed,
- your `robot_id` (used as the cloud session key),
- a `RobotState` snapshot — `robot_id`, `ros2_distro`, TF transforms,
  diagnostics, ROS 2 node names. The CLI itself sends an **empty**
  state by default; populated state only flows in if you also run the
  optional Jetson ROS 2 collector node.

### When you approve a tool call

`POST /v1/cli/result` with:

- the `tool_call_id`,
- the **output** of the tool. For `bash`, that's stdout+stderr (capped
  at 200 lines). For `read_file`, that's the file's full contents
  (with a warning header if > 2000 lines). For `write_file`, it's a
  short status string.
- an `error` field on non-zero exit / exception.

In other words: anything in a file the agent reads, or anything a
shell command prints, is shipped to the cloud. **Treat your BRIO
session like you'd treat pasting that file into a chat window.**

### What we do *not* receive

- Files the agent never asked to read.
- Files in directories the agent never `ls`'d into.
- Output from commands you denied at the approval prompt.
- Anything if the CLI isn't running.

## What stays on your machine

| Path | Contents |
| --- | --- |
| `~/.config/brio/config.env` | Your API key + URL. Mode `0600`. |
| `~/.brio.log` | Full loguru transcript: every tool call, every result, every API status code. Rotates at 10 MB, 3 retained. |
| `~/.brio_history` | Plaintext history of prompts you've typed. |
| `~/.brio_last_session` | Last session's full TUI transcript, restored by `brio --continue`. |

These are local-only. We never read them.

## API keys

- Each key is per-user, minted by the web app during `brio login`. The
  cloud stores only a key prefix and a `sha256` hash — we cannot
  recover the raw key after issuance.
- Revoke a key from your account dashboard at any time. The CLI will
  start failing with `401` on the next request; run `brio login` to
  mint a new one.
- The config file has mode `0600`. Don't `cat` it into pastebins, and
  don't commit it.
- Environment variables (`BRIO_API_KEY`) override the config file —
  useful for keeping a separate staging key in your shell, or for CI.

## What `--yolo` actually skips

`--yolo` only bypasses the **client-side approval prompt**. It does
not change what's sent to the cloud, what the agent is allowed to
request, or any server-side limits. Concretely, with `--yolo` on:

- every `bash` argv the agent emits runs immediately, with stdout +
  stderr returned to the cloud,
- every `read_file` reads and uploads the full file,
- every `write_file` overwrites the target path on disk.

Use it on disposable workspaces, never on machines holding secrets you
haven't audited.

## Telemetry & training

- We do **not** train models on your prompts, tool outputs, or file
  contents.
- We log enough metadata to bill (token counts, request counts) and to
  debug (request IDs, error types). That metadata is keyed to your
  user id, never to the contents of your prompts.

## Practical advice for closed-source work

If you're working on proprietary robotics code, the same discipline you
should apply to any cloud AI tool applies here:

- **Don't let the agent read secrets.** Keep `.env`, private keys,
  customer credentials, and API tokens outside the directories the
  agent will explore. If you see an approval prompt for `read_file:
  '.env'`, hit `n` (or `d` to ban `read_file` for the session). Once a
  secret is in a request, it's in our logs even though it's never used
  for training.
- **Use the approval prompt as your trust boundary.** Every `bash`,
  `read_file`, and `write_file` is a deliberate gate — not a
  formality. Reading the argv and the path before pressing `y` is the
  single most effective control you have.
- **Pre-deny aggressively.** At the first `bash` prompt, hit `d` to
  deny all `bash` for the session; the agent will fall back to
  read-only reasoning over `read_file`. Same for `write_file` if
  you're treating the workspace as read-only.
- **Scope keys per project.** Set `BRIO_API_KEY` in a project shell so
  a given key is bound to a given workspace, and revoke it from the
  dashboard when the engagement ends — no scrubbing required.
- **Don't use `--yolo` on machines with secrets you haven't audited.**
  It's fine on a disposable workspace; it's a mistake on your daily
  driver.
- **For air-gapped or VPC-resident requirements**, point `--url` at a
  private deployment. Contact us if that's a hard requirement for
  your engagement.
