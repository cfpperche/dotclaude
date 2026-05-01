---
name: projects-status
description: Survey state of the user's projects across home directory. Reports recent activity, dirty git state, open work. Profession-agnostic — works for code repos, writing folders, research notes, design files. Invoke with /projects-status.
---

# /projects-status

Survey what's happening across the user's projects without opening each one.

## When to use

- User asks "what's going on?" / "what am I working on?" / "qual o status?"
- User wants a quick map of recent activity across folders
- Triage at start of a day or after time away

## What this skill does

1. **Detect project root.** Default scope:
   - `~/projects/`, `~/work/`, `~/code/`, `~/dev/` (if any exist)
   - Plus any folder the user mentioned in this session
   - User can override with an argument: `/projects-status ~/clients`

2. **Per project, gather (read-only):**
   - **Type:** code repo, writing folder, research, design, generic
     (detected by file mix and manifest presence)
   - **Last activity:** most recent file mtime
   - **Status:**
     - Code: `git status --porcelain` summary, branch, ahead/behind
     - Non-code: count of files modified in last 7 days
   - **Pending work signals:** TODO/FIXME/WIP markers in files modified
     recently (across any text format)

3. **Dispatch to `cross-project-explorer` agent** for the actual scan when
   the project list is large (>5) or spans non-standard locations. For a
   simple home-folder scan, do it inline.

4. **Output a tight table.** No file dumps. One line per project.

## Output format

```
## Projects (<N>)

| Project | Type | Last activity | Status | Notes |
|---------|------|---------------|--------|-------|
| name1   | code | 2h ago        | dirty (3 files) | branch: feat/x, ahead 2 |
| name2   | writing | 1d ago     | clean  | 4 files touched this week |
| name3   | research | 3d ago   | —      | 12 notes, 2 TODO markers |

Open work signals:
- name1: TODO in app/auth.ts:42 (added today)
- name3: WIP in notes/2026-04-research.md
```

## Conventions

- **Don't open files unless necessary.** Read manifests, git status,
  mtimes — that's enough for status.
- **Skip credentials.** `.env*`, `*.key`, `.credentials.json`, `secrets/`
  — never read.
- **Profession-agnostic phrasing.** Don't assume "branch" / "commit"
  apply. Use "version", "draft", "iteration" when more accurate.
- **Don't editorialize.** "Looks abandoned", "behind schedule" — no.
  Describe what's there.

## Examples

- Code-heavy user: shows git state, branch, ahead/behind, dirty files
- Lawyer reviewing matters: shows folder per matter, last edit, count of
  drafts modified this week
- Researcher: shows notebook folders, last note added, open TODO markers
- Writer: shows manuscript folders, word-count delta if obtainable, last
  edit time
