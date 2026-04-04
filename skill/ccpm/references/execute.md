# Execute — Start Building with Parallel Agents

This phase covers analyzing GitHub issues for parallel work streams and launching agents to execute them.

---

## Issue Analysis

**Trigger**: User wants to understand how to parallelize work on an issue before starting.

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Find the local task file: check `.ccpm/initiatives/*/<epic>/<N>.md` first, then search for `github:.*issues/<N>` in frontmatter.
- If not found: "❌ No local task for issue #<N>. Run a sync first."

### Process

Get issue details: `gh issue view <N> --json title,body,labels`
If GitHub is unavailable, read task details from local `.ccpm/` task files instead.

Read the local task file fully. Identify independent work streams by asking:
- Which files will be created/modified?
- Which changes can happen simultaneously without conflict?
- What are the dependencies between changes?

**Common stream patterns:**
- Database Layer: schema, migrations, models
- Service Layer: business logic, data access
- API Layer: endpoints, validation, middleware
- UI Layer: components, pages, styles
- Test Layer: unit tests, integration tests

Create `.ccpm/initiatives/<initiative>/<epic_name>/<N>-analysis.md`:

```markdown
---
issue: <N>
title: <title>
analyzed: <run: date -u +"%Y-%m-%dT%H:%M:%SZ">
estimated_hours: <total>
parallelization_factor: <1.0-5.0>
---

# Parallel Work Analysis: Issue #<N>

## Overview

## Parallel Streams

### Stream A: <Name>
**Scope**:
**Files**:
**Can Start**: immediately
**Estimated Hours**:
**Dependencies**: none

### Stream B: <Name>
**Scope**:
**Files**:
**Can Start**: after Stream A
**Dependencies**: Stream A

## Coordination Points
### Shared Files
### Sequential Requirements

## Conflict Risk Assessment

## Parallelization Strategy

## Expected Timeline
- With parallel execution: <max_stream_hours>h wall time
- Without: <sum_all_hours>h
- Efficiency gain: <pct>%
```

**Output**: "✅ Analysis complete for issue #<N> — N parallel streams identified. Ready to start? Say: start issue <N>"

---

## Starting an Issue

**Trigger**: User wants to begin work on a specific GitHub issue.

### Preflight
0. **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
1. Verify issue exists and is open: `gh issue view <N> --json state,title,labels,body` — if GitHub is unavailable, read the local task file instead.
2. Find local task file (as above).
3. Check for analysis file: `.ccpm/initiatives/<initiative>/<epic>/<N>-analysis.md` — if missing, run analysis first (or do both in sequence: analyze then start).
4. Verify epic worktree exists: `git worktree list | grep "epic-<name>"` — if not: "❌ No worktree. Sync the epic first."

### Process

**Step 1 — Read the analysis**, identify which streams can start immediately vs. which have dependencies.

**Step 2 — Create progress tracking:**
```bash
mkdir -p .ccpm/initiatives/<initiative>/<epic>/updates/<N>
```

Get the current timestamp:
```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

Create `.ccpm/initiatives/<initiative>/<epic>/updates/<N>/stream-<X>.md` for each stream:
```markdown
---
issue: <N>
stream: <stream_name>
started: <datetime>
status: in_progress
---
## Scope
## Progress
- Starting implementation
```

**Step 3 — Launch parallel agents** for each stream that can start immediately:

```yaml
Task:
  description: "Issue #<N> Stream <X>"
  subagent_type: "general-purpose"
  prompt: |
    You are working on Issue #<N> in the epic worktree at: ../epic-<name>/

    Your stream: <stream_name>
    Your scope — files to modify: <file_patterns>
    Work to complete: <stream_description>

    Instructions:
    1. Read full task from: .ccpm/initiatives/<initiative>/<epic>/<N>.md
    2. Read analysis from: .ccpm/initiatives/<initiative>/<epic>/<N>-analysis.md
    3. Work ONLY in your assigned files
    4. Commit frequently: "Issue #<N>: <specific change>"
    5. Update progress in: .ccpm/initiatives/<initiative>/<epic>/updates/<N>/stream-<X>.md
    6. If you need to touch files outside your scope, note it in your progress file and wait
    7. Never use --force on git operations

    Complete your stream's work and mark status: completed when done.
```

Streams with unmet dependencies are queued — launch them as their dependencies complete.

**Step 4 — Assign on GitHub** (skip in local-only mode):
```bash
gh issue edit <N> --add-assignee @me --add-label "in-progress"
```

**Step 5 — Create execution status file** at `.ccpm/initiatives/<initiative>/<epic>/updates/<N>/execution.md`:
```markdown
## Active Streams
- Stream A: <name> — Started <time>
- Stream B: <name> — Started <time>

## Queued
- Stream C: <name> — Waiting on Stream A

## Completed
(none yet)
```

**Output:**
```
✅ Started work on issue #<N>

Launched N agents:
  Stream A: <name> ✓ Started
  Stream B: <name> ✓ Started
  Stream C: <name> ⏸ Waiting (depends on A)

Monitor: check progress in .ccpm/initiatives/<initiative>/<epic>/updates/<N>/
Sync updates: "sync issue <N>"
```

---

## Starting a Full Epic

**Trigger**: User wants to launch parallel agents across all ready issues in an epic at once.

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Verify `.ccpm/initiatives/<initiative>/<name>/epic.md` exists. If GitHub is available, verify it has a `github:` field (i.e., it's been synced). In local-only mode, proceed without it.
- Check for uncommitted changes: `git status --porcelain` — block if dirty.
- Verify epic branch exists: `git branch -a | grep "epic/<name>"`

### Parent Branch Detection

Before creating or checking out an epic branch, determine the correct parent:

1. Read the epic's initiative from the file path (`.ccpm/initiatives/<initiative>/<name>/epic.md`)
2. Check if `initiative/<initiative>` branch exists:
   - If yes: create/rebase `epic/<name>` from `initiative/<initiative>`
   - If no: create/rebase `epic/<name>` from `main` (single-epic mode, backward compatible)

Find the epic file to determine the initiative:
```bash
bash "${SKILL_ROOT:-.claude/skills/ccpm}/references/scripts/ccpm-find.sh" .ccpm/initiatives -path "*/<epic_name>/epic.md" | head -1
```

If found, extract the initiative name (first segment after `.ccpm/initiatives/`) and check for its branch:
```bash
git branch -a | grep -q "initiative/<initiative_name>"
```

Use the initiative branch as `PARENT_BRANCH` if it exists, otherwise use `main` when creating worktrees or branches for this epic.

### Process

**Step 1 — Read all task files** in `.ccpm/initiatives/<initiative>/<name>/`. Parse frontmatter for `status`, `depends_on`, `parallel`.

**Step 2 — Categorize tasks:**
- Ready: status=open, no unmet depends_on
- Blocked: has unmet depends_on
- In Progress: already has an execution file
- Complete: status=closed

**Step 3 — Analyze any ready tasks** that don't have an analysis file yet (run issue analysis inline).

**Step 4 — Launch agents** for all ready tasks following the same per-issue agent launch pattern above.

**Step 5 — Create/update** `.ccpm/initiatives/<initiative>/<name>/execution-status.md` with all active agents and queued issues.

**Step 6 — As agents complete**, check if blocked issues are now unblocked and launch those agents.

---

## Agent Coordination Rules

When multiple agents work in the same worktree simultaneously:

- Each agent works only on files in its assigned stream scope.
- Agents commit frequently with `Issue #<N>: <description>` format.
- Before modifying a shared file, check `git status <file>` — if another agent has it modified, wait and pull first.
- Agents sync via commits: `bash "${SKILL_ROOT:-.claude/skills/ccpm}/references/scripts/ccpm-worktree-git.sh" ../epic-<name> pull --rebase origin epic/<name> 2>/dev/null || true` before starting new file work.
- Conflicts are never auto-resolved — agents report them and pause.
- No `--force` flags ever.
- Before staging files, check for worktree directories with `bash "${SKILL_ROOT:-.claude/skills/ccpm}/references/scripts/ccpm-worktree-list.sh"` and exclude them from `git add` operations.

Shared files that commonly need coordination (types, config, package.json) should be handled by one designated stream; others pull after that commit.
