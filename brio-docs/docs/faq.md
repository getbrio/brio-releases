---
sidebar_position: 7
---

# FAQ

Common questions about getting started, usage limits, testing, and how
BRIO is put together.

## How do I get started?

Three steps:

1. Install: `curl -fsSL https://getbrio.dev/install.sh | bash`
2. Subscribe to the **Pro** or **Max** plan at
   [getbrio.org](https://getbrio.org).
3. Run `brio login`, approve the device code in your browser, then
   `cd` into a ROS 2 workspace and run `brio`.

See [Quickstart](./quickstart) for a five-minute walkthrough.

## How were the usage limits determined?

BRIO bills against a **5-hour rolling window** of token usage, scoped
per user. The caps are:

| Plan | Fresh input tokens / 5h | Output tokens / 5h |
| --- | --- | --- |
| Pro | 1,000,000 | 100,000 |
| Max | 4,000,000 | 400,000 |

These numbers are derived from Anthropic's published Claude usage
limits for the equivalent subscription tiers — the same 5-hour window
Claude Code uses, scaled to the input/output mix of a typical ROS 2
debugging session (heavier on tool-call output, lighter on free-form
generation). "Fresh input" means cache-miss input only; cached prefix
tokens (the system prompt, tool schema, prior turns) don't count
against the cap. That's why a long session usually fits comfortably
inside the window.

If you hit the cap you'll get a `429` with a `Retry-After` header
indicating when the oldest event in your window ages out.

## How do I see my current usage?

Inside the CLI, type `/usage` for process-local counters since
startup. For the rolling-window view across all sessions, the web app
at [getbrio.org](https://getbrio.org) shows a live snapshot of the
same data the rate limiter uses.

## How is BRIO tested?

Three layers:

- **Unit tests** in `libs/aiagent/tests/` (supervisor, tool guards,
  patch application, batching, context assembly) and
  `libs/ingest/tests/` (chunkers, local source loader). Pure-Python,
  no network.
- **API tests** in `apps/brio-fastapi/test/` covering the FastAPI
  routes, rate limiting, and device-auth flow against a fake Supabase.
- **CLI tests** in `apps/brio/test/` covering the TUI's external-tool
  handling and upgrade-check logic.

There's also an evals harness under `libs/evals/` for end-to-end agent
behavior, run on demand rather than per-commit.

## Does the agent have shell access to my machine?

No. The agent can only request three tool types — `bash`, `read_file`,
`write_file` — and each is a structured argv list, not a shell
string. The CLI rejects anything else client-side. Each call goes
through the approval prompt unless you've pre-approved that type with
`a` / `A` / `--yolo`. See [Usage & Commands](./usage#tool-calls-the-agent-can-request).

## What gets sent to the cloud?

Your prompt, the output of any tool call you approve, and (if you run
the optional ROS 2 collector) a `RobotState` snapshot — TF, the node
list, and `/diagnostics`. Files the agent never asks to read, and
output from denied tool calls, never leave your machine. Full list at
[Privacy & Data Handling](./privacy).

## Where do I file bugs or ask for features?

Open an issue at
[github.com/getbrio/brio-releases](https://github.com/getbrio/brio-releases/issues).
Include the output of `brio --help` (which prints the version) and
the relevant tail of `~/.brio.log` if it's a runtime issue.
