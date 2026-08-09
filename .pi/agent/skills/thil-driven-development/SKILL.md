---
name: thil-driven-development
description: "Use when implementing any feature or bugfix from a light plan. Replaces subagent-driven-development and executing-plans. Enforces tight human-in-the-loop: propose every change for approval before editing, verify after each task."
---

# THIL-Driven Development (Tight Human-In-the-Loop)

## Overview

Execute a light implementation plan one task at a time. Every code change goes through proposal→approval→execute. Every task ends with verification.

**Core principle:** The agent types, but the human decides. No code changes happen without explicit approval.

**This replaces:** subagent-driven-development and executing-plans. No subagents. No parallel work. Serial, approval-gated micro-steps only.

## When to Use

- You have a light implementation plan (from writing-plans)
- You want to review every diff before it lands
- You want to review every new function/file before it's written
- You want verification gated per task

**Do NOT use:**
- For autonomous batch execution (use subagent-driven-development)
- When you don't have a plan at all (use brainstorming first)

<HARD-GATE>
You MUST ask at least one clarifying question per task before proposing any implementation. Never assume you understand the task — confirm your interpretation with the user first. Even if the plan seems clear, state your understanding of what you're about to do and ask if that's correct. This applies to EVERY task regardless of perceived simplicity.
</HARD-GATE>

## The Hard Gates (Enforced by Extension)

While THIL is active, `edit` and `write` are **completely disabled**. Instead:

| Instead of... | Use... |
|---------------|--------|
| `edit` | `thil_propose_diff` — shows a diff, and **applies the edit on approval** |
| `write` | `thil_propose_new` — shows the code, and **creates the file on approval** |
| `bash` (test commands) | `bash` — test commands (npm test, cargo test, etc.) pass through freely |

General bash commands (ls, grep, git, etc.) are NOT gated.

**The agent never calls edit/write directly.** The proposal tools perform the actual file changes after approval.

**Approval options per proposal:**
- **Approve** — change goes through immediately
- **Reject** — change is blocked, agent must rethink
- **Reject with feedback** — opens a text editor, type why you reject, Enter to send feedback + reject. Agent sees your feedback and can re-propose.

## The Process

### Setup

1. Call `thil_enable` to activate edit/write/test gates for this session
2. Read the light plan file
3. Create todos for each task
4. Announce: "I'm using THIL-driven development."

### Per Task

**BEFORE ANY PROPOSAL, YOU MUST:**
1. State your understanding of what this task requires
2. List the files you expect to touch (discovered from codebase exploration)
3. Ask: "Is this correct?" and wait for the user's response

Only after the user confirms should you proceed.

```
1. CLARIFY (MANDATORY) — state your understanding, ask if correct.
   Do NOT skip this. Every task, every time.

2. TEST FIRST (RED) — write a failing test for the first unit of change.
   - Use thil_propose_new for new test files
   - Use thil_propose_diff for modifications to existing test files

3. PROPOSE & APPLY CHANGE:
   - Modifying existing code → thil_propose_diff(path, oldText, newText, reason?)
   - New function/file → thil_propose_new(path, code, reason?)
   - Reason only if not obvious from context
   - The tool shows a preview, asks for approval, and applies the change on approval.

4. WAIT FOR APPROVAL:
   - Accept → change is applied automatically
   - Reject → rethink, propose again
   - Reject with feedback → type feedback, Enter. Agent sees feedback and re-proposes.

5. REPEAT steps 2-4 for each unit of change in the task6. REFACTOR if needed (each refactor diff goes through propose→approve→execute)

7. REPEAT steps 2-6 for each unit of change in the task

8. VERIFY — run the test command via bash
   - Test commands (npm test, cargo test, etc.) pass through THIL's gate freely
   - Watch tests pass (GREEN)
```

### Model Selection

This workflow uses a SINGLE agent session. No subagents. Choose a model appropriate for the task complexity — no need to budget for subagent overhead since there are none.

## The Light Plan Format

Light plans describe WHAT to build, not HOW or WHERE. The agent discovers affected files at execution time.

```markdown
# Feature Name Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:thil-driven-development.

**Goal:** Add Pong variant to the Message enum.

**Architecture:** Follow existing enum/match patterns in the codebase.

## Global Constraints

- Follow existing code patterns
- All match statements must be exhaustive
- Tests required for all new variants

---

### Task 1: Add Pong variant to Message enum

Add the new `Pong` arm to the Message enum and handle it in all match statements.

### Task 2: Implement Pong handler

Create the handler for incoming Pong messages following the same pattern as Ping.
```

**Differences from SDD plans:**
- No file paths, line numbers, or before/after code blocks
- No exact function signatures in "Produces/Consumes"
- No step-by-step instructions — the agent figures out details
- Task descriptions are 1-3 sentences

## Unit of Change Guidelines

**One proposal = one logical change:**
- A single function
- A type/enum variant addition
- A match arm addition
- A small refactor in one location

**Not:**
- Multiple functions at once
- Changes spanning multiple files in one proposal
- "Add all the things" mega-diffs

If a change touches multiple files, split into one proposal per file.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "This diff is too small to need approval" | The gate is the rule. Every diff, every time. |
| "I'll just batch these three changes" | One logical change per proposal. Split them. |
| "The reason is obvious" | Then omit the reason field — it's optional. |
| "I can run the test without thil_verify" | Test commands pass through freely. Just use bash. |
| "I understand this task, no need to ask" | The HARD-GATE requires it. State your understanding and ask. |

## Verify Per Task, Not Per Diff

Verification happens once per task, after all its changes are approved and implemented. Do NOT run verification after every individual diff — only at the task level.

Before marking a task complete:
- [ ] All changes for this task are implemented
- [ ] Verification was run (test commands pass through THIL freely)
- [ ] Tests pass (green)
- [ ] Output is clean (no warnings, errors)
