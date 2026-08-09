# AGENTS.md — Instructions for AI coding agents working on `thil-extension`

## Overview

THIL (Tight Human-In-the-Loop) is a Pi extension that enforces a strict propose→approve→execute workflow. Every code change must be proposed with a diff preview, approved by the user, then applied. `edit` and `write` are completely blocked while THIL is active.

**Single file:** `index.ts` (~640 lines). No build step, no dependencies beyond what Pi bundles.

## Architecture

```
executeProposal()         — shared engine: show approval UI → return ToolResult
  ├─ showApprovalUI()     — ctx.ui.select with three options
  └─ showFeedbackUI()     — ctx.ui.custom with Editor for text feedback

Tool: thil_propose_diff   — proposes edits to existing files
Tool: thil_propose_new    — proposes creating new files
Tool: thil_propose_enable / thil_disable  — toggles

tool_call event handler   — blocks edit/write, gates dangerous bash when THIL is on
```

**State:** One module-level variable — `thilEnabled` (boolean). No session persistence. Dangerous command patterns live in `dangerous-commands.json`.

## Key Patterns

### ToolResult

All tools return through `executeProposal`, which produces a `ToolResult`:

```typescript
interface ToolResult {
  content: AgentToolResult<unknown>["content"];
  details: Record<string, unknown>;  // ProposalDetails
  terminate: boolean;                 // true = stop agent turn
}
```

### terminate semantics

- `terminate: true` only on plain **Reject** — agent stops, user must prompt again
- `terminate: false` on Approve, Cancel, and Reject+feedback — agent continues normally
- On feedback, the agent sees the feedback message in context and can re-propose

### Diff rendering

`renderCall` is synchronous. Use `readFileSync` (not async `readFile`) for finding line offsets. The actual edit in `execute` uses async `readFile`/`writeFile`. These are separate opens and cannot be unified.

`buildDiffPreview(oldText, newText, fileStartLine)` takes a pre-computed line offset. `findLineOffset(filePath, text)` computes it from the file. Call `findLineOffset` once in `renderCall`, pass the result to `buildDiffPreview`.

### Tool execution flow

1. `renderCall` — shows diff in chat (sync, uses `readFileSync`)
2. `execute` — shows approval UI, applies edit on approval (async, uses `readFile`/`writeFile`)
3. `renderResult` — shows approved/rejected status

## Design Rules

- **Minimize file opens.** `renderCall` opens once for line offset. `execute` opens once for the edit. No redundant reads.
- **One logical change per proposal.** Don't batch multiple edits into one `thil_propose_diff` call.
- **Sync in render, async in execute.** `renderCall` and `renderResult` are synchronous. Use `readFileSync`, never `await readFile`.
- **Guard UI calls.** Check `ctx.hasUI` before calling select/confirm/input. Check `ctx.mode === "tui"` before `ctx.ui.custom`.
- **No dynamic imports.** Standard top-level imports only.
- **No `any`.** Use proper types like `ExtCtx`, `ProposalDetails`, `ToolResult`.

## UI

The approval dialog uses `ctx.ui.select` with three options:

```
▶ Accept
✗ Reject
↩ Reject + feedback
```

Feedback uses `ctx.ui.custom` with an `Editor` component. Escape in the feedback editor loops back to the approval menu (not cancel).

## tool_call Blocker

The `tool_call` event handler runs first in the pipeline. When THIL is on:

| Tool | Behavior |
|------|----------|
| `edit` | Blocked. Use `thil_propose_diff`. |
| `write` | Blocked. Use `thil_propose_new`. |
| `bash` (dangerous) | Trigger approval dialog. If rejected, blocked with `terminate: true`. |
| `bash` (safe) | Allowed freely. |

Dangerous commands are detected via static blacklist in `dangerous-commands.json` across four categories: destructive, expensive, cheating, sensitive. Each category has regex patterns matched case-insensitively against the command string.

The proposal tools (`thil_propose_diff`, `thil_propose_new`) perform the actual file writes themselves after approval — they don't delegate to `edit`/`write`.

## Committing

This repo is tracked in the user's dotfiles repo. **Never run `git init`.**

**Never auto-commit.** Only commit when the user explicitly asks.

When committing, use:

```bash
cd /home/an && git --git-dir=$HOME/dev/dotfiles --work-tree=$HOME add .pi/agent/extensions/thil-extension/<file>
cd /home/an && git --git-dir=$HOME/dev/dotfiles --work-tree=$HOME commit -m "[pi] <message>"
```

Commit messages follow the `[scope] description` convention. Use `[pi]` as the scope.
