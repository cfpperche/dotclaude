#!/usr/bin/env node
// StatusLine — model, project, branch, cost, context progress bar, rate limits.
// Adapted from anthill statusline (cfpperche/anthill) — domain-agnostic version.
//
// Cache lives at ~/.cache/dotclaude/statusline/ (per-machine, gitignored).
// Each session writes its tokens snapshot and current context marker, used by
// skills/agents to know how much context is left without re-parsing stdin.

import { execSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";

const input = readFileSync(0, "utf8");

let data;
try {
	data = JSON.parse(input);
} catch {
	process.stdout.write("ctx: ---%");
	process.exit(0);
}

const remaining = data.context_window?.remaining_percentage;
const usedRaw = data.context_window?.used_percentage ?? 0;
const used = Math.round(usedRaw);
const modelRaw = data.model?.display_name ?? data.model?.id ?? "?";
const modelId = data.model?.id ?? "";

// Compact "Family Version Context" — e.g. "Opus 4.7 1M", "Sonnet 4.6 200K"
const model = (() => {
	const m = modelRaw.match(/(Opus|Sonnet|Haiku)\s*(\d+(?:\.\d+)?)/i);
	if (!m) return modelRaw;
	const family = m[1][0].toUpperCase() + m[1].slice(1).toLowerCase();
	const ver = m[2];
	const ctx = /\[1m\]|1M/i.test(modelId) || /1M/i.test(modelRaw) ? "1M" : "200K";
	return `${family} ${ver} ${ctx}`;
})();

// Thinking / effort config from env or settings.json
let userSettings = {};
try {
	userSettings = JSON.parse(readFileSync(`${homedir()}/.claude/settings.json`, "utf8"));
} catch {}
const thinkDisabled =
	process.env.CLAUDE_CODE_DISABLE_THINKING === "1" ||
	process.env.CLAUDE_CODE_DISABLE_THINKING === "true" ||
	userSettings.disableThinking === true;
const thinkTokensRaw = process.env.MAX_THINKING_TOKENS ?? userSettings.maxThinkingTokens;
const thinkTokens = thinkTokensRaw ? Number(thinkTokensRaw) : null;
const fmtThinkBudget = (n) => (n >= 1000 ? `${Math.round(n / 1000)}k` : `${n}`);
const effortLevel = process.env.CLAUDE_CODE_EFFORT_LEVEL ?? userSettings.effortLevel;
const thinkBadge = thinkDisabled
	? "think:off"
	: thinkTokens
		? `think:${fmtThinkBudget(thinkTokens)}`
		: null;
const effortBadge = effortLevel ? effortLevel : null;

const cost = data.cost?.total_cost_usd;
const projectDir = data.workspace?.project_dir ?? data.cwd ?? "";
const project = projectDir.split("/").pop() || "?";
const sessionId = data.session_id ?? "unknown";
const linesAdded = data.cost?.total_lines_added;
const linesRemoved = data.cost?.total_lines_removed;
const durationMs = data.cost?.total_duration_ms;
const worktree = data.worktree?.name;
const agent = data.agent?.name;
const fiveHourUsed = data.rate_limits?.five_hour?.used_percentage;
const fiveHourResets = data.rate_limits?.five_hour?.resets_at;
const sevenDayUsed = data.rate_limits?.seven_day?.used_percentage;
const sevenDayResets = data.rate_limits?.seven_day?.resets_at;

// --- Cache directory (per-machine, gitignored at ~/.claude level via runtime exclusion) ---
const CACHE_ROOT = `${homedir()}/.cache/dotclaude/statusline`;
try {
	if (!existsSync(CACHE_ROOT)) mkdirSync(CACHE_ROOT, { recursive: true });
} catch {}

// --- Git branch (cached 5s to avoid spawning git every render) ---
const BRANCH_CACHE = `${CACHE_ROOT}/branch.json`;
const BRANCH_TTL = 5000;
let branch = "?";
try {
	let useCache = false;
	if (existsSync(BRANCH_CACHE)) {
		const cached = JSON.parse(readFileSync(BRANCH_CACHE, "utf8"));
		if (cached.dir === projectDir && Date.now() - cached.ts < BRANCH_TTL) {
			branch = cached.branch;
			useCache = true;
		}
	}
	if (!useCache && projectDir) {
		branch = execSync("git rev-parse --abbrev-ref HEAD", {
			cwd: projectDir,
			encoding: "utf8",
			timeout: 1000,
			stdio: ["pipe", "pipe", "pipe"],
		}).trim();
		writeFileSync(BRANCH_CACHE, JSON.stringify({ dir: projectDir, branch, ts: Date.now() }));
	}
} catch {}

// --- Helpers ---
const formatDuration = (ms) => {
	if (ms == null) return null;
	const s = Math.floor(ms / 1000);
	if (s < 60) return `${s}s`;
	const m = Math.floor(s / 60);
	if (m < 60) return `${m}m${s % 60}s`;
	const h = Math.floor(m / 60);
	return `${h}h${m % 60}m`;
};

const formatResetIn = (epochSec) => {
	if (epochSec == null) return null;
	const ms = epochSec * 1000 - Date.now();
	if (ms <= 0) return "now";
	return formatDuration(ms);
};

// --- Derived metrics ---
const durationMin = durationMs != null && durationMs > 0 ? durationMs / 60000 : null;
const costPerMin =
	cost != null && durationMin != null && durationMin > 0.5 ? cost / durationMin : null;
const totalLines = (linesAdded ?? 0) + (linesRemoved ?? 0);
const linesPerDollar = cost > 0 && totalLines > 0 ? totalLines / cost : null;
const inputTokens = data.context_window?.total_input_tokens ?? 0;
const outputTokens = data.context_window?.total_output_tokens ?? 0;

// Per-turn token delta
const TOK_DIR = `${CACHE_ROOT}/tokens`;
let turnIn = 0;
let turnOut = 0;
try {
	if (!existsSync(TOK_DIR)) mkdirSync(TOK_DIR, { recursive: true });
	const tokFile = `${TOK_DIR}/${sessionId}.json`;
	let prev = { in: 0, out: 0 };
	if (existsSync(tokFile)) {
		try {
			prev = JSON.parse(readFileSync(tokFile, "utf8"));
		} catch {}
	}
	turnIn = Math.max(0, inputTokens - (prev.in ?? 0));
	turnOut = Math.max(0, outputTokens - (prev.out ?? 0));
	writeFileSync(tokFile, JSON.stringify({ in: inputTokens, out: outputTokens }));
} catch {}
const fmtTok = (n) => (n >= 1000 ? `${(n / 1000).toFixed(1)}k` : `${n}`);

// Cache hit ratio
const cacheRead = data.context_window?.current_usage?.cache_read_input_tokens ?? 0;
const cacheCreation = data.context_window?.current_usage?.cache_creation_input_tokens ?? 0;
const cacheTotal = cacheRead + cacheCreation;
const cacheHitRatio = cacheTotal > 0 ? cacheRead / cacheTotal : null;

// Context ETA
const burnRate = used > 0 && durationMin != null && durationMin > 0.5 ? used / durationMin : null;
const ctxEta =
	burnRate != null && remaining > 0
		? remaining / (used > 50 ? burnRate * 1.5 : burnRate)
		: null;

// --- Progress bar ---
const barWidth = 20;
const filled = Math.round((usedRaw / 100) * barWidth);
const empty = barWidth - filled;
const ctxColor = remaining > 50 ? "\x1b[32m" : remaining > 25 ? "\x1b[33m" : "\x1b[31m";
const green = "\x1b[32m";
const red = "\x1b[31m";
const cyan = "\x1b[36m";
const magenta = "\x1b[35m";
const yellow = "\x1b[33m";
const dim = "\x1b[2m";
const bold = "\x1b[1m";
const reset = "\x1b[0m";
const bar = `${ctxColor}${"█".repeat(filled)}${dim}${"░".repeat(empty)}${reset}`;
const sep = `${dim} │ ${reset}`;

// Line 1: identity + context bar + rate limits
const line1 = [
	`${bold}${model}${reset}`,
	thinkBadge ? `${cyan}${thinkBadge}${reset}` : null,
	effortBadge ? `${cyan}${effortBadge}${reset}` : null,
	agent ? `${magenta}${agent}${reset}` : null,
	worktree ? `${cyan}wt:${worktree}${reset}` : null,
	`${dim}${project}${reset}`,
	`${dim}${branch}${reset}`,
	`${bar} ${ctxColor}${used}%${reset}`,
	ctxEta != null ? `${ctxColor}~${formatDuration(ctxEta * 60000)} left${reset}` : null,
	fiveHourUsed != null
		? (() => {
				const c = fiveHourUsed >= 80 ? red : fiveHourUsed >= 50 ? yellow : green;
				const r = fiveHourUsed > 70 ? ` ~${formatResetIn(fiveHourResets)}` : "";
				return `${c}5h:${Math.round(fiveHourUsed)}%${r}${reset}`;
			})()
		: null,
	sevenDayUsed != null
		? (() => {
				const c = sevenDayUsed >= 80 ? red : sevenDayUsed >= 50 ? yellow : green;
				const r = sevenDayUsed > 70 ? ` ~${formatResetIn(sevenDayResets)}` : "";
				return `${c}7d:${Math.round(sevenDayUsed)}%${r}${reset}`;
			})()
		: null,
	remaining != null && remaining <= 25 ? `${red}${bold} COMPACT SOON${reset}` : null,
	remaining != null && remaining <= 10 ? `${red}${bold} CRITICAL${reset}` : null,
].filter(Boolean);

// Line 2: economics + productivity
const line2 = [
	cost != null ? `${dim}$${cost.toFixed(2)}${reset}` : null,
	`${cyan}↑${fmtTok(turnIn)} ↓${fmtTok(turnOut)}${reset}`,
	costPerMin != null ? `${yellow}$${costPerMin.toFixed(2)}/min${reset}` : null,
	durationMs != null ? `${dim}${formatDuration(durationMs)}${reset}` : null,
	linesAdded != null || linesRemoved != null
		? `${green}+${linesAdded ?? 0}${reset} ${red}-${linesRemoved ?? 0}${reset}`
		: null,
	linesPerDollar != null ? `${cyan}${Math.round(linesPerDollar)} lines/$${reset}` : null,
	cacheHitRatio != null
		? `${cacheHitRatio > 0.5 ? green : yellow}cache ${Math.round(cacheHitRatio * 100)}%${reset}`
		: null,
].filter(Boolean);

process.stdout.write(line1.join(sep));
if (line2.length > 0) process.stdout.write("\n" + line2.join(sep));

// --- Write current context usage to a marker file readable by skills/agents ---
const markerDir = `${CACHE_ROOT}/context-markers`;
try {
	if (!existsSync(markerDir)) mkdirSync(markerDir, { recursive: true });
	writeFileSync(
		`${markerDir}/${sessionId}-current`,
		JSON.stringify({ used, remaining, ts: Date.now() }),
	);
} catch {}
