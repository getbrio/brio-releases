---
sidebar_position: 3
---

# Configuration

After [installing the CLI](./installation), you need to (1) have an
active BRIO subscription and (2) approve the CLI as a device on your
account.

## 1. Account + subscription

Create an account and pick a plan at
[getbrio.org](https://getbrio.org). The CLI **cannot** sign in or issue
API keys until your account is on the **Pro** or **Max** plan — the
device-approval flow will refuse the request and prompt you to
subscribe.

## 2. Sign in (`brio login`)

From your terminal:

```bash
brio login
```

This kicks off a device-authorization flow:

1. The CLI displays an 8-character user code (e.g. `ABCD-1234`) and a
   URL: `https://getbrio.org/cli`.
2. Open that URL in a browser, sign in with Google, and paste the code.
3. The web app mints a per-user API key, registers it against your
   account, and pushes it back to the CLI.
4. The CLI writes `~/.config/brio/config.env` with mode `0600`.

That config file holds your API URL and API key — treat it like an SSH
key. Never commit it.

To sign out and remove the file:

```bash
brio logout
```

## 3. Run it

```bash
brio                              # uses saved config
brio --robot-id lab-bot-1         # override robot id for this session
brio --yolo                       # auto-approve all agent tool calls
```

Inside the TUI:

- `you>` prompt at the bottom is always your input
- spinner / approval prompt appears just above it
- scrollable log buffer at top — `PgUp` / `PgDn` or mouse wheel to
  scroll, `Ctrl-End` to re-tail
- `/usage` shows current plan usage, `/reset` clears the session
- `Ctrl-D` or `exit` quits

## Environment overrides

These environment variables, if set in your shell, take precedence over
`~/.config/brio/config.env`:

| Variable | Purpose |
| --- | --- |
| `BRIO_API_URL` | Override the cloud API endpoint (defaults to `https://api.getbrio.org`). |
| `BRIO_API_KEY` | Use a different API key for this shell session. |
| `BRIO_ROBOT_ID` | Default robot identifier when `--robot-id` is not passed. |

Useful for switching between staging and prod without re-running
`brio login`, or for scoping a single shell to a different robot.

## Configuration files

| Path | Contents |
| --- | --- |
| `~/.config/brio/config.env` | API URL + API key, written by `brio login` (mode `0600`). |
| `.env.local` (cwd) | Dev override — read when running BRIO from a workspace checkout. Ignored by release binaries unless explicitly loaded. |

## Optional: ROS 2 state collector

If you want the agent to reason over live robot state, run the
companion ROS 2 node on your Jetson (or any machine on the robot's ROS
graph). It collects TF, `/diagnostics`, and the node list and POSTs
`RobotState` to the same cloud API your CLI session is attached to.

Set these on the Jetson before launching the node:

| Variable | Purpose |
| --- | --- |
| `BRIO_API_URL` | Cloud API endpoint. |
| `BRIO_API_KEY` | API key — same one minted by `brio login`. |
| `BRIO_ROBOT_ID` | Robot identifier; must match the `--robot-id` your CLI session uses. |

Installation of the ROS 2 node is out of scope for the CLI installer —
it ships separately as an `ament_python` package.

## Troubleshooting

**"Subscription required" when approving the CLI.** Your account has
no active Pro/Max plan. Visit the dashboard and subscribe, then retry
`brio login`.

**`brio: command not found`** after install. `~/.local/bin` is not on
your `PATH`. Add this to your shell profile:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

**macOS "cannot be opened because the developer cannot be verified".**
Strip quarantine: `xattr -d com.apple.quarantine ~/.local/bin/brio`.

**Stale or wrong API key.** `brio logout`, then `brio login` again to
mint a fresh key. Old keys can be revoked from your account dashboard.
