/**
 * THIL (Tight Human-In-the-Loop) Extension
 *
 * Enforces a strict propose→approve→execute workflow:
 * - thil_propose_diff: show a diff to existing code, get user approval
 * - thil_propose_new: show new function/file code, get user approval
 *
 * Hard enforcement: edit/write are always blocked. Bash commands that are
 * destructive, expensive, cheating, or sensitive require explicit approval.
 * All other bash commands pass through freely.
 */

import { type ExtensionAPI, type AgentToolResult, Theme } from "@earendil-works/pi-coding-agent";
import {
	Editor,
	type EditorTheme,
	Key,
	matchesKey,
	Text,
} from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { readFileSync } from "node:fs";
import { readFile, writeFile } from "node:fs/promises";
import dangerousPatterns from "./dangerous-commands.json" with { type: "json" };

// ---------------------------------------------------------------------------
// Shared types
// ---------------------------------------------------------------------------

interface ToolResult {
	content: AgentToolResult<unknown>["content"];
	details: Record<string, unknown>;
	terminate: boolean;
}

/** Outcome of the approval UI — added by executeProposal to any input */
interface ApprovalOutcome {
	approved: boolean;
	feedback?: string;
}

// Per-tool proposal types

interface DiffProposalInput {
	path: string;
	reason?: string;
}

interface DiffProposalResult extends DiffProposalInput, ApprovalOutcome {
	applied?: boolean;
}

interface NewProposalInput {
	path: string;
	reason?: string;
	code: string;
}

interface NewProposalResult extends NewProposalInput, ApprovalOutcome {
	applied?: boolean;
}

type Action = "approve" | "reject" | "feedback" | "cancel";

// Helper to extract ExtensionContext type from the API
type ExtCtx = Parameters<
	Parameters<ExtensionAPI["on"]>[1]
>[1];

// ---------------------------------------------------------------------------
// Approval UI (scrollable diff + three-option select)
// ---------------------------------------------------------------------------

async function showApprovalUI(
	ctx: ExtCtx,
): Promise<Action> {
	if (!ctx.hasUI) return "cancel";

	// Use ctx.ui.select for simplicity and reliability
	const choice = await ctx.ui.select(
		"THIL — Review proposal",
		["▶ Accept", "✗ Reject", "↩ Reject + feedback"],
	);

	if (choice === "▶ Accept") return "approve";
	if (choice === "✗ Reject") return "reject";
	if (choice === "↩ Reject + feedback") return "feedback";
	return "cancel";
}

// ---------------------------------------------------------------------------
// Feedback UI (simple text input → returns feedback string)
// ---------------------------------------------------------------------------

type FeedbackResult =
	| { outcome: "submitted"; feedback: string }
	| { outcome: "back" }
	| { outcome: "unavailable" };

async function showFeedbackUI(ctx: ExtCtx): Promise<FeedbackResult> {
	if (ctx.mode !== "tui") return { outcome: "unavailable" };

	return ctx.ui.custom<FeedbackResult>((tui, theme, _kb, done) => {
		const editorTheme: EditorTheme = {
			borderColor: (s) => theme.fg("accent", s),
			selectList: {
				selectedPrefix: (t) => theme.fg("accent", t),
				selectedText: (t) => theme.fg("accent", t),
				description: (t) => theme.fg("muted", t),
				scrollInfo: (t) => theme.fg("dim", t),
				noMatch: (t) => theme.fg("warning", t),
			},
		};
		const editor = new Editor(tui, editorTheme);
		editor.onSubmit = (value) => done({ outcome: "submitted", feedback: value.trim() });

		const title = new Text(theme.fg("accent", theme.bold("THIL — Rejected with feedback")), 1, 0);
		const hint = new Text(theme.fg("dim", "Type feedback, Enter to reject."), 1, 0);
		const bottomHint = new Text(theme.fg("dim", "Enter to reject with feedback • Esc to go back"), 1, 0);
		const spacer = new Text("", 1, 0);

		return {
			render(w: number): string[] {
				const lines: string[] = [];
				lines.push(...title.render(w));
				lines.push(...hint.render(w));
				lines.push(...spacer.render(w));
				for (const line of editor.render(Math.max(1, w - 2))) {
					lines.push(" " + line);
				}
				lines.push(...spacer.render(w));
				lines.push(...bottomHint.render(w));
				return lines;
			},
			invalidate: () => editor.invalidate(),
			handleInput: (data: string) => {
				if (matchesKey(data, Key.escape)) {
					done({ outcome: "back" });
					return;
				}
				editor.handleInput(data);
				tui.requestRender();
			},
		};
	});
}

// ---------------------------------------------------------------------------
// Common proposal execution logic
// ---------------------------------------------------------------------------

async function executeProposal<T extends Record<string, unknown>>(
	ctx: ExtCtx,
	input: T,
): Promise<ToolResult> {
	while (true) {
		const action = await showApprovalUI(ctx);

		if (action === "cancel") {
			return {
				content: [{ type: "text", text: "User cancelled." }],
				details: { ...input, approved: false } as T & ApprovalOutcome,
				terminate: false,
			};
		}

		if (action === "reject") {
			return {
				content: [{ type: "text", text: "Rejected." }],
				details: { ...input, approved: false } as T & ApprovalOutcome,
				terminate: true,
			};
		}

		if (action === "feedback") {
			const fb = await showFeedbackUI(ctx);
			if (fb.outcome === "unavailable") {
				return {
					content: [{ type: "text", text: "User cancelled." }],
					details: { ...input, approved: false } as T & ApprovalOutcome,
					terminate: false,
				};
			}
			if (fb.outcome === "back") {
				continue;
			}
			return {
				content: [
					{
						type: "text",
						text: `Rejected with feedback: ${fb.feedback || "(none)"}`,
					},
				],
				details: {
					...input,
					approved: false,
					feedback: fb.feedback,
				} as T & ApprovalOutcome,
				terminate: false,
			};
		}

		// Plain approve
		return {
			content: [{ type: "text", text: "Approved." }],
			details: { ...input, approved: true } as T & ApprovalOutcome,
			terminate: false,
		};
	}
}

function renderProposalResult(
	result: ToolResult,
	theme: Theme,
) {
	const d = result.details as ApprovalOutcome & { path?: string };
	if (!d.path) return new Text(theme.fg("warning", "?"), 0, 0);
	const path = theme.fg("accent", d.path);
	const fb = d.feedback ? theme.fg("dim", d.approved ? ` (${d.feedback})` : ` — ${d.feedback}`) : "";
	const status = d.approved
		? theme.fg("success", "▶ approved ")
		: theme.fg("warning", "✘ rejected ");
	return new Text(`\n${status}${path}${fb}`, 0, 0);
}

// ---------------------------------------------------------------------------
// Diff preview builder
// ---------------------------------------------------------------------------

function findLineOffset(filePath: string, text: string): number {
	try {
		const content = readFileSync(filePath, "utf-8");
		const idx = content.indexOf(text);
		if (idx === -1) return 1; // not found, default to 1
		// Count newlines before the match
		let lines = 1;
		for (let i = 0; i < idx; i++) {
			if (content[i] === "\n") lines++;
		}
		return lines;
	} catch {
		return 1; // file not readable, default to 1
	}
}

function lineNumberFormatter(totalLines: number, startLine: number = 1): (n: number) => string {
	const maxLineNum = startLine - 1 + totalLines;
	const width = String(maxLineNum).length;
	return (n: number) => String(n).padStart(width, " ");
}

function buildDiffPreview(oldText: string, newText: string, fileStartLine: number): string {
	const oldLines = oldText.split("\n");
	const newLines = newText.split("\n");
	const padLine = lineNumberFormatter(Math.max(oldLines.length, newLines.length), fileStartLine);

	// Compute LCS-based edit script
	const m = oldLines.length, n = newLines.length;
	const dp: number[][] = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0));
	for (let i = 1; i <= m; i++)
		for (let j = 1; j <= n; j++)
			dp[i][j] = oldLines[i - 1] === newLines[j - 1] ? dp[i - 1][j - 1] + 1 : Math.max(dp[i - 1][j], dp[i][j - 1]);

	// Backtrack to produce edit ops (walk from (0,0) to (m,n))
	type Op = { type: "eq"; line: string } | { type: "del"; line: string } | { type: "add"; line: string };
	const ops: Op[] = [];
	{
		const stack: Op[] = [];
		let i = m, j = n;
		while (i > 0 || j > 0) {
			if (i > 0 && j > 0 && oldLines[i - 1] === newLines[j - 1]) {
				stack.push({ type: "eq", line: oldLines[i - 1] });
				i--; j--;
			} else if (j > 0 && (i === 0 || dp[i][j - 1] >= dp[i - 1][j])) {
				stack.push({ type: "add", line: newLines[j - 1] });
				j--;
			} else {
				stack.push({ type: "del", line: oldLines[i - 1] });
				i--;
			}
		}
		for (let k = stack.length - 1; k >= 0; k--) ops.push(stack[k]);
	}

	// Render with context hunks
	const contextLines = 3;
	const output: string[] = [];
	let oldNum = fileStartLine, newNum = fileStartLine;
	let idx = 0;

	while (idx < ops.length) {
		// Find next change
		while (idx < ops.length && ops[idx].type === "eq") {
			oldNum++; newNum++; idx++;
		}
		if (idx >= ops.length) break;

		// Determine hunk boundaries
		const hunkStart = Math.max(0, idx - contextLines);
		let hunkEnd = idx;
		while (hunkEnd < ops.length && ops[hunkEnd].type !== "eq") hunkEnd++;
		hunkEnd = Math.min(ops.length, hunkEnd + contextLines);

		// Compute line numbers at hunkStart
		let oNum = fileStartLine, nNum = fileStartLine;
		for (let k = 0; k < hunkStart; k++) {
			if (ops[k].type !== "add") oNum++;
			if (ops[k].type !== "del") nNum++;
		}

		for (let k = hunkStart; k < hunkEnd; k++) {
			const op = ops[k];
			if (op.type === "eq") {
				output.push(` ${padLine(oNum)} ${op.line}`);
				oNum++; nNum++;
			} else if (op.type === "del") {
				output.push(`-${padLine(oNum)} ${op.line}`);
				oNum++;
			} else {
				output.push(`+${padLine(nNum)} ${op.line}`);
				nNum++;
			}
		}

		oldNum = oNum;
		newNum = nNum;
		idx = hunkEnd;
	}

	return output.join("\n");
}


// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

let thilEnabled = false;

function resetAllState() {
	// reserved for future state
}

// ---------------------------------------------------------------------------
// Dangerous command classifier (static blacklist)
// ---------------------------------------------------------------------------

type DangerCategory = "destructive" | "expensive" | "cheating" | "sensitive";

const compiledPatterns: Record<DangerCategory, RegExp[]> = {
	destructive: [],
	expensive: [],
	cheating: [],
	sensitive: [],
};

for (const cat of Object.keys(dangerousPatterns) as DangerCategory[]) {
	compiledPatterns[cat] = (dangerousPatterns[cat] as string[]).map((p) => new RegExp(p, "i"));
}

interface CommandVerdict {
	dangerous: boolean;
	category?: DangerCategory;
}

function classifyCommand(cmd: string): CommandVerdict {
	for (const cat of Object.keys(compiledPatterns) as DangerCategory[]) {
		for (const re of compiledPatterns[cat]) {
			if (re.test(cmd)) {
				return { dangerous: true, category: cat };
			}
		}
	}
	return { dangerous: false };
}

// ---------------------------------------------------------------------------
// Extension entry point
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
	// ── Hard enforcement: block edit/write, gate dangerous bash ────────
	// Returning undefined from this handler means "allow the tool call to proceed".
	// Returning { block: true } means "stop the tool call with this reason".
	//
	// edit/write: always blocked, agent must use thil_propose_* tools instead.
	// bash: only blocked if the command matches destructive/expensive/cheating/sensitive
	//       patterns AND the user rejects the approval dialog.
	pi.on("tool_call", async (event, ctx) => {
		if (!thilEnabled) return; // THIL off → allow everything

		if (event.toolName === "edit") {
			return {
				block: true,
				reason: "THIL: edit is disabled. Use thil_propose_diff — it will apply the edit on approval.",
			};
		}

		if (event.toolName === "write") {
			return {
				block: true,
				reason: "THIL: write is disabled. Use thil_propose_new — it will create the file on approval.",
			};
		}

		if (event.toolName === "bash") {
			const cmd = (event.input as { command?: string }).command ?? "";
			const verdict = classifyCommand(cmd);

			if (!verdict.dangerous) return; // safe command → allow

			// Dangerous command → ask user for approval
			const action = await showApprovalUI(ctx);

			if (action === "approve") return; // user approved → allow

			// User rejected — block the command and stop the agent turn
			if (action === "feedback") {
				const fb = await showFeedbackUI(ctx);
				if (fb.outcome === "submitted") {
					return {
						block: true,
						reason: `THIL: ${verdict.category} bash command rejected with feedback: ${fb.feedback || "(none)"}`,
						terminate: true,
					};
				}
				// back or unavailable → treat as plain reject
			}

			return {
				block: true,
				reason: `THIL: ${verdict.category} bash command blocked by user.`,
				terminate: true,
			};
		}

		return; // allow any other tool
	});

	// ── Tool: thil_propose_diff ─────────────────────────────────────────
	pi.registerTool({
		name: "thil_propose_diff",
		label: "THIL Propose Diff",
		description:
			"Propose an edit to an existing file. Shows a diff preview, and if approved, applies the edit. The edit tool is disabled — use this instead.",
		parameters: Type.Object({
			path: Type.String({ description: "File path being modified" }),
			oldText: Type.String({ description: "Exact text to replace" }),
			newText: Type.String({ description: "Replacement text" }),
			reason: Type.Optional(
				Type.String({ description: "Why this change is needed. Omit if obvious." }),
			),
		}),
		executionMode: "sequential",

		async execute(_id, params, _signal, _onUpdate, ctx) {
			const filePath = (params.path as string) || "";
			const oldText = (params.oldText as string) || "";
			const newText = (params.newText as string) || "";

			const result = await executeProposal<DiffProposalInput>(ctx, {
				path: filePath,
				reason: params.reason as string | undefined,
			});

			if (result.details.approved) {
				try {
					const content = await readFile(filePath, "utf-8");
					if (!content.includes(oldText)) {
						return {
							content: [{ type: "text", text: `Edit failed: oldText not found in ${filePath}. File may have changed.` }],
							details: { ...result.details, applied: false },
						};
					}
					const newContent = content.replace(oldText, newText);
					await writeFile(filePath, newContent, "utf-8");
					return {
						content: [{ type: "text", text: `Applied to ${filePath}.` }],
						details: { ...result.details, applied: true },
					};
				} catch (err) {
					return {
						content: [{ type: "text", text: `Edit failed: ${err instanceof Error ? err.message : String(err)}` }],
						details: { ...result.details, applied: false },
					};
				}
			}
			return result;
		},

		renderCall(args, theme, context) {
			const path = theme.fg("accent", args.path as string);
			const reason = args.reason ? theme.fg("dim", ` (${args.reason})`) : "";
			let text = theme.fg("toolTitle", theme.bold("thil_propose_diff ")) + path + reason + "\n";
			const fileStartLine = findLineOffset(
				(args.path as string) || "",
				(args.oldText as string) || "",
			);
			const preview = buildDiffPreview(
				(args.oldText as string) || "",
				(args.newText as string) || "",
				fileStartLine,
			);
			const colored = preview.split("\n").map((line) => {
				if (line.startsWith("+")) return theme.fg("toolDiffAdded", line);
				if (line.startsWith("-")) return theme.fg("toolDiffRemoved", line);
				if (line.startsWith(" ")) return theme.fg("toolDiffContext", line);
				return theme.fg("toolOutput", line);
			});
			text += colored.join("\n");
			const component = (context.lastComponent as Text | undefined) ?? new Text("", 0, 0);
			component.setText(text);
			return component;
		},

		renderResult(result, _options, theme, context) {
			const d = result.details as DiffProposalResult;
			if (d.applied) {
				const text = `\n${theme.fg("success", "▶ applied ")}${theme.fg("accent", d.path)}`;
				const component = (context.lastComponent as unknown as Text | undefined) ?? new Text("", 0, 0);
				component.setText(text);
				return component;
			}
			return renderProposalResult(result, theme);
		},
	});

	// ── Tool: thil_propose_new ──────────────────────────────────────────
	pi.registerTool({
		name: "thil_propose_new",
		label: "THIL Propose New",
		description:
			"Propose new code for user approval. If approved, creates/writes the file. The write tool is disabled — use this instead.",
		parameters: Type.Object({
			path: Type.String({ description: "File path being created or receiving new code" }),
			code: Type.String({ description: "The full new code to write" }),
			reason: Type.Optional(
				Type.String({ description: "Why this new code is needed. Omit if obvious." }),
			),
		}),
		executionMode: "sequential",

		async execute(_id, params, _signal, _onUpdate, ctx) {
			const result = await executeProposal<NewProposalInput>(ctx, {
				path: params.path,
				reason: params.reason,
				code: params.code,
			});

			if (result.details.approved) {
				try {
					await writeFile(params.path, params.code, "utf-8");
					return {
						content: [{ type: "text", text: `Written to ${params.path}.` }],
						details: { ...result.details, applied: true },
					};
				} catch (err) {
					return {
						content: [{ type: "text", text: `Write failed: ${err instanceof Error ? err.message : String(err)}` }],
						details: { ...result.details, applied: false },
					};
				}
			}
			return result;
		},

		renderCall(args, theme, context) {
			const path = theme.fg("accent", args.path as string);
			const reason = args.reason ? theme.fg("dim", ` (${args.reason})`) : "";
			let text = theme.fg("toolTitle", theme.bold("thil_propose_new ")) + path + reason + "\n";
			const code = (args.code as string) || "";
			const lines = code.split("\n");
			const padLine = lineNumberFormatter(lines.length, 1);
			const colored = lines.map((line, i) => theme.fg("toolDiffAdded", `+${padLine(i + 1)} ${line}`));
			text += colored.join("\n");
			const component = (context.lastComponent as Text | undefined) ?? new Text("", 0, 0);
			component.setText(text);
			return component;
		},

		renderResult(result, _options, theme, context) {
			const d = result.details as NewProposalResult;
			if (d.applied) {
				const text = `\n${theme.fg("success", "▶ written ")}${theme.fg("accent", d.path)}`;
				const component = (context.lastComponent as unknown as Text | undefined) ?? new Text("", 0, 0);
				component.setText(text);
				return component;
			}
			return renderProposalResult(result, theme);
		},
	});

	// ── THIL on/off toggle ─────────────────────────────────────────────
	pi.registerCommand("thil:on", {
		description: "Enable THIL enforcement (edit/write gates, dangerous bash approval)",
		async handler(_args, ctx) {
			thilEnabled = true;
			ctx.ui.notify("THIL: gates enabled", "info");
		},
	});

	pi.registerCommand("thil:off", {
		description: "Disable THIL enforcement",
		async handler(_args, ctx) {
			thilEnabled = false;
			resetAllState();
			ctx.ui.notify("THIL: gates disabled", "info");
		},
	});

	// Tool so the skill/agent can toggle THIL on
	pi.registerTool({
		name: "thil_enable",
		label: "THIL Enable",
		description:
			"Enable THIL enforcement gates for this session. Call when entering THIL-driven development.",
		parameters: Type.Object({}),
		executionMode: "sequential",
		async execute() {
			thilEnabled = true;
			return {
				content: [{ type: "text", text: "THIL gates enabled. edit/write are blocked. Dangerous bash commands require approval." }],
				details: { enabled: true },
			};
		},
	});

	// Tool so the skill/agent can toggle THIL off
	pi.registerTool({
		name: "thil_disable",
		label: "THIL Disable",
		description: "Disable THIL enforcement gates. Call when done with THIL-driven development.",
		parameters: Type.Object({}),
		executionMode: "sequential",
		async execute() {
			thilEnabled = false;
			resetAllState();
			return {
				content: [{ type: "text", text: "THIL gates disabled. All tools are free again." }],
				details: { enabled: false },
			};
		},
	});
}
