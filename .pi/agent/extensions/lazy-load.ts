/**
 * Lazy-Load Skills & Extensions
 *
 * Controls which skills and extensions are active. Skills are stripped from
 * the system prompt and injected as user messages instead — preserving prompt
 * cache. Extensions are controlled at session-start only (requires /reload).
 *
 * Commands:
 *   /skills              - TUI picker to toggle skills for this session
 *   /extensions          - TUI picker to toggle extensions (requires /reload)
 *   /enable-skill <name> - Enable a skill for this session
 *   /disable-skill <name> - Disable a skill for this session
 *
 * Settings (in ~/.pi/agent/settings.json):
 *   "lazyLoad": {
 *     "skills": { "enabled": ["brainstorming", "systematic-debugging"] },
 *     "extensions": { "enabled": ["superpowers"] }
 *   }
 */

import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { basename, join, resolve } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// ── Constants ───────────────────────────────────────────────────────────────

const PI_AGENT_DIR = resolve(homedir(), ".pi/agent");
const SETTINGS_PATH = join(PI_AGENT_DIR, "settings.json");
const SKILL_INJECTION_MARKER = "lazy-load:skill:";

// ── Types ────────────────────────────────────────────────────────────────────

interface LazyLoadSettings {
  skills?: { enabled?: string[] };
  extensions?: { enabled?: string[] };
}

interface SkillInfo {
  name: string;
  content: string;
}

interface SessionState {
  enabledSkills: Set<string>;
  /** Tracks injected skill messages so we can filter them out on disable */
  injectedSkillMessageIds: Set<string>;
  skillMap: Map<string, string>; // name -> path
  initialized: boolean;
}

// ── Settings I/O ─────────────────────────────────────────────────────────────

function readSettingsRaw(): Record<string, unknown> {
  try {
    if (!existsSync(SETTINGS_PATH)) return {};
    return JSON.parse(readFileSync(SETTINGS_PATH, "utf8")) as Record<string, unknown>;
  } catch {
    return {};
  }
}

function writeSettingsRaw(data: Record<string, unknown>): void {
  writeFileSync(SETTINGS_PATH, JSON.stringify(data, null, 2) + "\n");
}

function getLazyLoadSettings(): LazyLoadSettings {
  const raw = readSettingsRaw();
  return (raw.lazyLoad ?? {}) as LazyLoadSettings;
}

function saveLazyLoadSettings(settings: LazyLoadSettings): void {
  const raw = readSettingsRaw();
  raw.lazyLoad = settings;
  writeSettingsRaw(raw);
}

// ── Skill Discovery ──────────────────────────────────────────────────────────

function extractSkillName(skillPath: string): string | null {
  try {
    const st = statSync(skillPath);
    let mdPath: string;

    if (st.isDirectory()) {
      mdPath = join(skillPath, "SKILL.md");
      if (!existsSync(mdPath)) return null;
    } else {
      mdPath = skillPath;
    }

    const content = readFileSync(mdPath, "utf8");
    const nameMatch = content.match(/^---\n[\s\S]*?name:\s*(\S+)[\s\S]*?\n---/);
    if (nameMatch) return nameMatch[1].trim();

    // Fallback: directory name or filename without extension
    if (st.isDirectory()) return basename(skillPath);
    return basename(skillPath, ".md");
  } catch {
    return null;
  }
}

function readSkillContent(skillPath: string): SkillInfo | null {
  try {
    const st = statSync(skillPath);
    let mdPath: string;

    if (st.isDirectory()) {
      mdPath = join(skillPath, "SKILL.md");
      if (!existsSync(mdPath)) return null;
    } else {
      mdPath = skillPath;
    }

    const raw = readFileSync(mdPath, "utf8");
    const body = raw.replace(/^---\n[\s\S]*?\n---\n?/, "").trim();
    const nameMatch = raw.match(/^---\n[\s\S]*?name:\s*(\S+)[\s\S]*?\n---/);
    const name = nameMatch?.[1]?.trim() ?? basename(skillPath, ".md");

    return { name, content: body };
  } catch {
    return null;
  }
}

/** Recursively find all skill directories/files under a root. */
function discoverSkillDirs(root: string): string[] {
  const results: string[] = [];
  if (!existsSync(root)) return results;

  try {
    for (const entry of readdirSync(root)) {
      if (entry.startsWith(".")) continue;
      const full = join(root, entry);
      try {
        const st = statSync(full);
        if (st.isDirectory()) {
          if (existsSync(join(full, "SKILL.md"))) {
            results.push(full);
          } else {
            // Recurse for nested package skills
            results.push(...discoverSkillDirs(full));
          }
        }
      } catch {
        /* skip permission errors etc */
      }
    }
  } catch {
    /* skip */
  }

  return results;
}

function discoverAllSkillPaths(): string[] {
  const paths: string[] = [];

  // User global skills
  paths.push(...discoverSkillDirs(join(PI_AGENT_DIR, "skills")));
  paths.push(...discoverSkillDirs(resolve(homedir(), ".agents/skills")));

  // Package skills (git) — structure: git/<host>/<org>/<repo>/skills/
  const gitDir = join(PI_AGENT_DIR, "git");
  if (existsSync(gitDir)) {
    for (const host of readdirSync(gitDir)) {
      const hostDir = join(gitDir, host);
      if (!statSync(hostDir).isDirectory()) continue;
      for (const org of readdirSync(hostDir)) {
        const orgDir = join(hostDir, org);
        if (!statSync(orgDir).isDirectory()) continue;
        for (const repo of readdirSync(orgDir)) {
          const repoDir = join(orgDir, repo);
          if (!statSync(repoDir).isDirectory()) continue;
          paths.push(...discoverSkillDirs(join(repoDir, "skills")));
        }
      }
    }
  }

  // Package skills (npm) — structure: npm/<pkg-name>/skills/
  const npmDir = join(PI_AGENT_DIR, "npm");
  if (existsSync(npmDir)) {
    for (const pkg of readdirSync(npmDir)) {
      const pkgDir = join(npmDir, pkg);
      if (!statSync(pkgDir).isDirectory()) continue;
      // npm packages may also have scoped structure: npm/@scope/pkg/
      if (pkg.startsWith("@")) {
        for (const scopedPkg of readdirSync(pkgDir)) {
          const scopedDir = join(pkgDir, scopedPkg);
          if (!statSync(scopedDir).isDirectory()) continue;
          paths.push(...discoverSkillDirs(join(scopedDir, "skills")));
        }
      } else {
        paths.push(...discoverSkillDirs(join(pkgDir, "skills")));
      }
    }
  }

  return paths;
}

function buildSkillMap(paths: string[]): Map<string, string> {
  const map = new Map<string, string>();
  for (const p of paths) {
    const name = extractSkillName(p);
    if (name && !map.has(name)) {
      map.set(name, p);
    }
  }
  return map;
}

// ── Extension Discovery ──────────────────────────────────────────────────────

function discoverExtensions(): string[] {
  const available: string[] = [];
  const extDir = join(PI_AGENT_DIR, "extensions");

  if (!existsSync(extDir)) return available;

  for (const entry of readdirSync(extDir)) {
    if (entry.startsWith(".")) continue;
    const full = join(extDir, entry);
    try {
      const st = statSync(full);
      if (st.isFile() && /\.(ts|js)$/.test(entry) && !entry.endsWith(".d.ts")) {
        available.push(entry.replace(/\.(ts|js)$/, ""));
      } else if (st.isDirectory()) {
        if (
          existsSync(join(full, "index.ts")) ||
          existsSync(join(full, "index.js"))
        ) {
          available.push(entry);
        }
      }
    } catch {
      /* skip */
    }
  }

  return available.sort();
}

// ── System Prompt Stripping ──────────────────────────────────────────────────

function stripSkillsFromSystemPrompt(prompt: string): string {
  // Try XML format first: <available_skills>...</available_skills>
  let result = prompt.replace(
    /<available_skills>[\s\S]*?<\/available_skills>/g,
    "<available_skills>\nSkills are loaded on-demand. Use /skill:&lt;name&gt; to load one.\n</available_skills>",
  );

  // If no change, try the markdown section format
  if (result === prompt) {
    result = result.replace(
      /## Available Skills[\s\S]*?(?=\n## |\n---|$)/g,
      "## Available Skills\n\nSkills are loaded on-demand. Use `/skill:<name>` to load a skill at any time.",
    );
  }

  return result;
}

// ── Message Helpers ──────────────────────────────────────────────────────────

function getMessageText(msg: unknown): string {
  if (!msg || typeof msg !== "object") return "";
  const m = msg as Record<string, unknown>;
  const content = m.content;
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    return content
      .filter(
        (c): c is { type: "text"; text: string } =>
          typeof c === "object" && c !== null && (c as Record<string, unknown>).type === "text",
      )
      .map((c) => c.text)
      .join("\n");
  }
  return "";
}

function hasInjectionMarker(msg: unknown, skillName: string): boolean {
  return getMessageText(msg).includes(`${SKILL_INJECTION_MARKER}${skillName}`);
}

function buildSkillInjection(skill: SkillInfo): string {
  return `${SKILL_INJECTION_MARKER}${skill.name}\n\n[Skill loaded: ${skill.name}]\n\n${skill.content}`;
}

// ── Extension Entry Point ────────────────────────────────────────────────────

export default function lazyLoadExtension(pi: ExtensionAPI) {
  const state: SessionState = {
    enabledSkills: new Set(),
    injectedSkillMessageIds: new Set(),
    skillMap: new Map(),
    initialized: false,
  };

  // ── session_start: discover skills, load defaults ──────────────────────

  pi.on("session_start", async (_event, _ctx) => {
    // Reset session state
    state.enabledSkills.clear();
    state.injectedSkillMessageIds.clear();
    state.skillMap.clear();
    state.initialized = false;

    // Discover all skills
    const paths = discoverAllSkillPaths();
    state.skillMap = buildSkillMap(paths);

    // Load defaults from settings
    const settings = getLazyLoadSettings();
    const defaults = settings.skills?.enabled ?? [];
    for (const name of defaults) {
      if (state.skillMap.has(name)) {
        state.enabledSkills.add(name);
      }
    }

    state.initialized = true;

    // Self-bootstrap: always keep lazy-load in its own enabled list
    ensureSelfBootstrapped();
  });

  // ── before_agent_start: strip system prompt, inject defaults ───────────

  pi.on("before_agent_start", async (event, _ctx) => {
    if (!state.initialized) return;

    const strippedPrompt = stripSkillsFromSystemPrompt(event.systemPrompt);

    // Build injection for default skills not yet injected
    const toInject: SkillInfo[] = [];
    for (const skillName of state.enabledSkills) {
      if (state.injectedSkillMessageIds.has(skillName)) continue;

      const skillPath = state.skillMap.get(skillName);
      if (!skillPath) continue;

      const skill = readSkillContent(skillPath);
      if (!skill) continue;

      toInject.push(skill);
      state.injectedSkillMessageIds.add(skillName);
    }

    if (toInject.length > 0) {
      const text = toInject.map((s) => buildSkillInjection(s)).join("\n\n---\n\n");
      return {
        systemPrompt: strippedPrompt,
        message: {
          customType: "lazy-load-init",
          content: text,
          display: false,
        },
      };
    }

    return { systemPrompt: strippedPrompt };
  });

  // ── input: intercept /skill:name for on-demand loading ─────────────────

  pi.on("input", async (event) => {
    // Check for /skill:name patterns
    let skillName: string | null = null;
    let restText = event.text;

    // Prefix: /skill:name at the start
    const prefixMatch = event.text.match(/^\/skill:(\S+)(?:\s+(.*))?$/s);
    if (prefixMatch) {
      skillName = prefixMatch[1];
      restText = (prefixMatch[2] ?? "").trim();
    } else {
      // Inline: /skill:name anywhere
      const inlineMatch = event.text.match(/\/skill:(\S+)/);
      if (inlineMatch) {
        skillName = inlineMatch[1];
        restText = event.text.replace(/\/skill:\S+\s*/g, "").trim();
      }
    }

    if (!skillName) return { action: "continue" as const };

    const skillPath = state.skillMap.get(skillName);
    if (!skillPath) {
      // Let pi handle this (will show "skill not found")
      return { action: "continue" as const };
    }

    const skill = readSkillContent(skillPath);
    if (!skill) return { action: "continue" as const };

    // Enable for this session
    state.enabledSkills.add(skillName);

    // Inject skill content
    pi.sendMessage(
      {
        customType: `lazy-load-skill:${skillName}`,
        content: buildSkillInjection(skill),
        display: true,
      },
      { triggerTurn: false, deliverAs: "nextTurn" },
    );
    state.injectedSkillMessageIds.add(skillName);

    if (restText) {
      return { action: "transform" as const, text: restText, images: event.images };
    }

    return {
      action: "transform" as const,
      text: `I've loaded the ${skillName} skill. Please follow its instructions.`,
    };
  });

  // ── context: filter out disabled skill injections ──────────────────────

  pi.on("context", async (event) => {
    if (!state.initialized) return;

    const filtered = event.messages.filter((msg) => {
      if (msg.role !== "user") return true;

      // Check if this message is a skill injection
      const text = getMessageText(msg);
      if (!text.includes(SKILL_INJECTION_MARKER)) return true;

      // Find which skill this is and filter out if disabled
      for (const skillName of state.skillMap.keys()) {
        if (!state.enabledSkills.has(skillName) && hasInjectionMarker(msg, skillName)) {
          return false; // Filter it out - skill was disabled
        }
      }

      return true;
    });

    if (filtered.length !== event.messages.length) {
      return { messages: filtered };
    }
  });

  // ── Self-Bootstrapping ──────────────────────────────────────────────────

  /** Ensure this extension is in its own lazyLoad.extensions.enabled list. */
  function ensureSelfBootstrapped(): void {
    const settings = getLazyLoadSettings();
    const enabled = settings.extensions?.enabled ?? [];
    if (!enabled.includes("lazy-load")) {
      settings.extensions = { ...settings.extensions, enabled: [...enabled, "lazy-load"] };
      saveLazyLoadSettings(settings);
    }
  }

  // ── Commands ────────────────────────────────────────────────────────────

  pi.registerCommand("enable-skill", {
    description: "Enable a skill for this session",
    handler: async (args, ctx) => {
      const skillName = args.trim();
      if (!skillName) {
        ctx.ui.notify("Usage: /enable-skill <name>", "warning");
        return;
      }

      const skillPath = state.skillMap.get(skillName);
      if (!skillPath) {
        ctx.ui.notify(`Skill not found: ${skillName}`, "error");
        return;
      }

      if (state.enabledSkills.has(skillName)) {
        ctx.ui.notify(`Skill already enabled: ${skillName}`, "info");
        return;
      }

      state.enabledSkills.add(skillName);

      const skill = readSkillContent(skillPath);
      if (skill) {
        pi.sendMessage(
          {
            customType: `lazy-load-skill:${skillName}`,
            content: buildSkillInjection(skill),
            display: true,
          },
          { triggerTurn: false, deliverAs: "nextTurn" },
        );
        state.injectedSkillMessageIds.add(skillName);
      }

      ctx.ui.notify(`Skill enabled: ${skillName}`, "info");
    },
  });

  pi.registerCommand("disable-skill", {
    description: "Disable a skill for this session",
    handler: async (args, ctx) => {
      const skillName = args.trim();
      if (!skillName) {
        ctx.ui.notify("Usage: /disable-skill <name>", "warning");
        return;
      }

      if (!state.enabledSkills.has(skillName)) {
        ctx.ui.notify(`Skill not enabled: ${skillName}`, "warning");
        return;
      }

      state.enabledSkills.delete(skillName);
      state.injectedSkillMessageIds.delete(skillName);

      ctx.ui.notify(`Skill disabled: ${skillName}`, "info");
    },
  });

  pi.registerCommand("skills", {
    description: "Toggle skills for this session (Ctrl+S to save as defaults)",
    handler: async (_args, ctx) => {
      const settings = getLazyLoadSettings();
      const defaults = new Set(settings.skills?.enabled ?? []);

      const skills = [...state.skillMap.keys()].sort();
      if (skills.length === 0) {
        ctx.ui.notify("No skills found", "warning");
        return;
      }

      // Build initial labels
      const buildLabels = () =>
        skills.map((name) => {
          const isEnabled = state.enabledSkills.has(name);
          const isDefault = defaults.has(name);
          const marker = isEnabled ? "☑" : "☐";
          const defMark = isDefault ? " [default]" : "";
          return `${marker} ${name}${defMark}`;
        });

      const labels = buildLabels();

      // Toggle loop
      while (true) {
        const choice = await ctx.ui.select(
          "Toggle skills - Enter: toggle | Esc: exit (will ask to save)",
          labels,
        );

        if (!choice) break;

        const nameMatch = choice.match(/[☑☐]\s+(\S+)/);
        if (!nameMatch) continue;

        const skillName = nameMatch[1];

        if (state.enabledSkills.has(skillName)) {
          state.enabledSkills.delete(skillName);
          state.injectedSkillMessageIds.delete(skillName);
        } else {
          state.enabledSkills.add(skillName);

          // Inject immediately
          const skillPath = state.skillMap.get(skillName);
          if (skillPath) {
            const skill = readSkillContent(skillPath);
            if (skill) {
              pi.sendMessage(
                {
                  customType: `lazy-load-skill:${skillName}`,
                  content: buildSkillInjection(skill),
                  display: true,
                },
                { triggerTurn: false, deliverAs: "nextTurn" },
              );
              state.injectedSkillMessageIds.add(skillName);
            }
          }
        }

        // Update labels in place
        for (let i = 0; i < skills.length; i++) {
          const isEnabled = state.enabledSkills.has(skills[i]);
          const isDefault = defaults.has(skills[i]);
          const marker = isEnabled ? "☑" : "☐";
          const defMark = isDefault ? " [default]" : "";
          labels[i] = `${marker} ${skills[i]}${defMark}`;
        }
      }

      // Offer to save as global defaults
      const changed =
        [...state.enabledSkills].sort().join(",") !== [...defaults].sort().join(",");

      if (changed && state.enabledSkills.size > 0) {
        const saveGlobal = await ctx.ui.confirm(
          "Save as defaults?",
          `Save current selection (${state.enabledSkills.size} skills) as global defaults?`,
        );

        if (saveGlobal) {
          const currentSettings = getLazyLoadSettings();
          currentSettings.skills = {
            ...currentSettings.skills,
            enabled: [...state.enabledSkills].sort(),
          };
          saveLazyLoadSettings(currentSettings);
          ctx.ui.notify(
            `Saved ${state.enabledSkills.size} skills as global defaults`,
            "info",
          );
        }
      } else if (state.enabledSkills.size === 0 && defaults.size > 0) {
        const clearDefaults = await ctx.ui.confirm(
          "Clear defaults?",
          "No skills enabled. Clear global defaults too?",
        );
        if (clearDefaults) {
          const currentSettings = getLazyLoadSettings();
          currentSettings.skills = { enabled: [] };
          saveLazyLoadSettings(currentSettings);
          ctx.ui.notify("Global defaults cleared", "info");
        }
      }
    },
  });

  pi.registerCommand("extensions", {
    description: "Show extension status and management options",
    handler: async (_args, ctx) => {
      const available = discoverExtensions();
      const settings = getLazyLoadSettings();
      const enabledList = settings.extensions?.enabled ?? [];

      if (available.length === 0) {
        ctx.ui.notify("No extensions found in ~/.pi/agent/extensions/", "warning");
        return;
      }

      // Show loaded extensions
      const lines = available.map((name) => {
        const isEnabled = enabledList.includes(name);
        return `${isEnabled ? "☑" : "☐"} ${name}`;
      });

      ctx.ui.notify(
        `Extensions in ~/.pi/agent/extensions/:\n${lines.join("\n")}\n\n` +
          `Use 'pi config' to manage package extensions.\n` +
          `For local extensions, rename to .disabled to hide them.\n` +
          `The lazyLoad.extensions.enabled setting tracks preferences.`,
        "info",
      );
    },
  });
}
