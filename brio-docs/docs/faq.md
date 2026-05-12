---
sidebar_position: 7
---

# FAQ

Common questions about getting started, usage limits, testing, and how
BRIO is put together.

## How do I get started?

Three steps:

1. Install: `curl -fsSL https://getbrio.dev/install.sh | bash`
2. Subscribe to the **Starter**, **Pro**, or **Max** plan at
   [getbrio.org](https://getbrio.org).
3. Run `brio login`, approve the device code in your browser, then
   `cd` into a ROS 2 workspace and run `brio`.

See [Quickstart](./quickstart) for a five-minute walkthrough.

## How were the usage limits determined?

BRIO bills against a **5-hour rolling window** of token usage, scoped
per user. The caps are:

| Plan | Fresh input tokens / 5h | Output tokens / 5h |
| --- | --- | --- |
| Starter | 1,000,000 | 100,000 |
| Pro | 4,000,000 | 400,000 |
| Max | 12,000,000 | 1,200,000 |

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

Four layers:

- **Agent unit tests** — supervisor loop, tool guards, patch
  application, batching, context assembly, compaction. Pure-Python,
  no network.
- **Ingest unit tests** — chunkers and source loaders for the
  knowledge base.
- **API tests** — FastAPI routes, rate limiting, and the device-auth
  flow against a faked backend.
- **CLI tests** — TUI, tool dispatch, upgrade check, login flow.

On top of those, an **evals harness** exercises end-to-end agent
behavior across categories like RAG retrieval, ROS 2 message
handling, motion planning, perception, hardware timing,
units/conventions, PID control, feature additions, state machines
and lifecycle, and TF coordinate frames. Evals run on demand with
parallel jobs and a baseline-comparison mode.

## Where does the agent run?

In the CLI on your workstation. `brio-fastapi` is a thin service
(auth, KB search, sessions, usage, admin, canonical system prompt) —
it does not run the agent loop or proxy tool calls. The CLI fetches
the system prompt at startup from `GET /v1/agent/system-prompt` and
falls back to a bundled copy if the server is unreachable (the TUI
shows `⚠ using local system prompt` when that happens).

## Does the agent have shell access to my machine?

No. The agent emits structured tool events — `bash`, `ros2`, `colcon`,
`read_file`, `write_file`, `apply_patch`, `list_dir`, `which`,
`mkdir`, `rm`, `cp`, `mv`, `batch` — and the CLI rejects anything
else. `bash` is the only shell escape and runs with a 25 s timeout.
Every call goes through the per-type approval prompt **and** the
directory-sandbox gate unless you've pre-approved with `a` / `A` /
`--yolo`. See [Usage & Commands](./usage#tool-calls-the-agent-can-request).

## What gets sent to the cloud?

Your prompt and the output of any tool call you approve. Files the
agent never asks to read, and output from denied tool calls, never
leave your machine.

## The agent stopped mid-turn asking about a directory — why?

The directory-sandbox gate fires when a tool tries to touch a path
outside the CLI's startup `cwd`. Approve with `y` (one-shot) or `a`
(recursive — `/a/b` grants `/a/b/**` for the session). The agent
needs your reply before the tool can run; don't just re-send the
original prompt. See [Usage — approval prompts](./usage#approval-prompts).

## The agent refused to create `CMakeLists.txt` / `package.xml`.

By policy, BRIO scaffolds ROS 2 packages with `ros2 pkg create` rather
than hand-rolling manifest files. Rephrase the prompt to use
scaffolding language ("create a new `ament_cmake` package called
`my_pkg`") and the agent will call `ros2 pkg create`, then edit the
generated files with `apply_patch`. If you genuinely need a hand-rolled
file, tell the agent explicitly that you know the policy and why
you're overriding it.

## The agent looped on the same tool call.

Per-turn deduplication blocks identical tool calls within a turn — if
the agent re-issues the same `read_file` or `grep`, the second attempt
short-circuits. Start a fresh turn (`/reset` or `/clear`) and ask
with a more specific prompt naming the symbol, file, or pattern. The
dedup set clears at each turn boundary.

## How do `/clear`, `/compact`, and `/reset` differ?

- `/clear` — drop conversation history and per-turn state. Keeps
  `session_id` and token totals. Cheapest reset.
- `/compact [focus]` — summarize history into a single block via a
  Haiku-backed summarizer; optional `[focus]` steers what to keep.
  Useful on a long session that's getting expensive but you still
  need the context.
- `/reset` — wipe the cloud session *and* zero local usage counters.
  Heaviest hammer; use between unrelated tasks.

## Where do I file bugs or ask for features?

Open an issue at
[github.com/getbrio/brio-releases](https://github.com/getbrio/brio-releases/issues).
Include the output of `brio --help` (which prints the version) and,
for a runtime issue, run `/sendlogs` inside the TUI to upload the
current session log — or attach
`~/.local/share/brio/logs/<date>/<session_id>.log` manually.
