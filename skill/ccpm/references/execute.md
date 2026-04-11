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
4. **Resolve working directory**: Read the initiative file's `worktree:` field.
   - If `worktree: true`: verify worktree exists at `../<repo-basename>-<initiative-name>/`. Use that directory as the working directory for agents. If missing: "❌ Worktree not found. Run: `@ccpm worktree enable <initiative-name>`"
   - If `worktree: false` or absent: verify initiative branch is checked out via `git branch --show-current`. If not, check it out. Agents work in the project root.

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
    You are working on Issue #<N>.
    Working directory: <worktree_path if worktree, otherwise project root>
    Branch: initiative/<initiative-name>

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
    8. Follow command safety rules: use Read/Grep/Glob/Edit tools for file operations. Keep Bash commands simple — no &&, no 2>/dev/null, one operation per call.

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

## Starting an Initiative

**Trigger**: User wants to launch parallel agents across all ready tasks in an initiative.

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Verify `.ccpm/initiatives/<name>/<name>.md` exists.
- Check for uncommitted changes: `git status --porcelain` — block if dirty.
- Verify initiative branch exists and is checked out: `git branch --show-current` should match `initiative/<name>`.

### Process

**Step 1 — Collect all task files** across all epics in the initiative. Glob for `.ccpm/initiatives/<name>/*/[0-9]*.md` to gather tasks from every epic directory. Parse each task's frontmatter for `status`, `depends_on`, `parallel`, and `conflicts_with`.

**Worktree resolution**: Read the initiative's `worktree:` field. If `true`, resolve the worktree path (`../<repo-basename>-<initiative-name>/`) and pass it to all agent launches as the working directory. If `false` or absent, agents work in the project root on the initiative branch.

**Step 2 — Build unified dependency graph.** Treat all tasks as one pool regardless of which epic they belong to. Task IDs in `depends_on` and `conflicts_with` can reference tasks from any epic within the initiative. Detect circular dependencies across the full graph — if found: "❌ Circular dependency detected: `<details>`"

**Step 3 — Categorize tasks:**
- Ready: status=open, no unmet depends_on, no unresolved conflicts_with
- Blocked: has unmet depends_on or unresolved conflicts_with
- In Progress: already has an execution file
- Complete: status=closed

**Step 4 — Analyze any ready tasks** that don't have an analysis file yet (run issue analysis inline).

**Step 5 — Launch agents** for all ready tasks following the same per-issue agent launch pattern above.

**Step 6 — Create/update** `.ccpm/initiatives/<name>/execution-status.md` with all active agents and queued tasks, organized by epic for readability.

**Step 7 — As agents complete**, check if blocked tasks are now unblocked and launch those agents.

---

## Agent Command Construction

Agents must follow the Command Safety rules from `references/conventions.md`. In addition, these rules govern how agents construct commands during task execution:

**Use native tools for file operations:**
- Read files with the Read tool, not `cat`, `head`, or `tail` in Bash
- Search file content with the Grep tool, not `grep` or `rg` in Bash
- Find files with the Glob tool, not `find` or `ls` in Bash
- Edit files with the Edit tool, not `sed` or `awk` in Bash

**Keep Bash commands simple and single-purpose:**
- One operation per Bash call. Don't chain with `&&` or `;`.
- Don't redirect stderr: no `2>&1`, no `2>/dev/null`. If a command might fail, run it and check the result in the next step.
- Don't use command substitution (`$()` or backticks) in Bash tool calls.
- Don't write inline scripts (Python, jq, Ruby) in Bash tool calls. If parsing is needed, create a script file first or use a native tool.

**Match project permission patterns:** Simple commands like `go test ./...`, `npm test`, `cargo build` match project-level permission patterns (e.g., `Bash(go test:*)`). The user approves the pattern once and all subsequent calls pass. Complex commands like `cd dir && go test 2>&1 | head -50` don't match any pattern and require individual approval every time.

**Examples:**

| Don't | Do |
|-------|-----|
| `cd frontend && npm test` | `npm test --prefix frontend` (or run from the correct directory) |
| `go list -u -m all 2>&1 \| grep '\['` | Run `go list -u -m all`, then use the Grep tool on the output |
| `cat config.json \| python3 -c "import json..."` | Use the Read tool to read config.json, then process the content directly |
| `git status && git diff && git log` | Three separate Bash tool calls |

---

## Agent Coordination Rules

When multiple agents work on the initiative branch simultaneously:

- Each agent works only on files in its assigned stream scope.
- Agents commit frequently with `Issue #<N>: <description>` format.
- Before modifying a shared file, check `git status <file>` — if another agent has it modified, wait and pull first.
- Agents sync via commits before starting new file work. When working in a worktree: `git -C <worktree_path> pull --rebase origin initiative/<name>`. Otherwise: `git pull --rebase origin initiative/<name>`. If no remote is configured, skip the pull and continue.
- Conflicts are never auto-resolved — agents report them and pause.
- No `--force` flags ever.

Shared files that commonly need coordination (types, config, package.json) should be handled by one designated stream; others pull after that commit.
