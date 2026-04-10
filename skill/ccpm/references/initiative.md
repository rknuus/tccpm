# Initiative — Multi-Epic Coordination

This phase covers decomposing an initiative into multiple epics, executing them in dependency order, merging everything back to main, cancelling initiatives, and adding epics to running initiatives.

---

## Initiative Decompose

**Trigger**: User wants to break an initiative into multiple epics (1-10).

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Verify `.ccpm/initiatives/<name>/<name>.md` exists with valid frontmatter (name, description, status, created). If missing: "❌ Initiative not found: `<name>`. Create it first."
- If epic subdirectories already exist under `.ccpm/initiatives/<name>/`, list them and confirm overwrite before proceeding.
- Feature name must be kebab-case.

### Process

**Step 1 — Read the initiative.** Analyze all requirements, constraints, user stories, and success criteria.

**Step 2 — Identify epic boundaries** based on:
- Functional boundaries (distinct features or capabilities)
- Technical boundaries (different subsystems or layers)
- Delivery boundaries (independent shippable increments)

Identify dependencies between epics. Ensure each epic is independently valuable when possible.

**Hard limit: maximum 10 epics per initiative.** If analysis suggests more, consolidate related work into fewer, broader epics.

**Step 3 — Create the initiative branch:**
```bash
git checkout main
git pull origin main 2>/dev/null || true
git checkout -b initiative/<name>
git push -u origin initiative/<name> 2>/dev/null || echo "No remote — continuing locally"
```

If the branch already exists, check it out instead of creating.

**Step 3b — Create worktree (if enabled).** Read the initiative's `worktree:` frontmatter field. If `true`:

```bash
REPO_BASENAME=$(basename "$(git rev-parse --show-toplevel)")
WORKTREE_PATH="../${REPO_BASENAME}-<name>"
git worktree add "$WORKTREE_PATH" initiative/<name>
```

If the worktree already exists at that path, skip with a warning: "Worktree already exists at `<path>` — skipping creation."

Report the worktree path in the post-completion output when created.

**Step 4 — Create epic outlines.** For each epic, create the directory and file:

Directory: `.ccpm/initiatives/<name>/<epic-name>/`
File: `.ccpm/initiatives/<name>/<epic-name>/epic.md`

```markdown
---
name: <epic-name>
status: backlog
created: <run: date -u +"%Y-%m-%dT%H:%M:%SZ">
progress: 0%
initiative: .ccpm/initiatives/<name>/<name>.md
depends_on: []
---

# Epic: <epic-name>

## Overview
Brief summary of what this epic covers and its role within the initiative.

## Scope
- Key deliverables and boundaries
- What is included
- What is explicitly excluded

## Dependencies
- Other epics in this initiative that must complete first (match depends_on field)
- External dependencies outside this initiative
```

Epic outlines are intentionally rough-scoped — overview, scope, and dependencies only. Detailed technical breakdown happens via epic decomposition.

**Step 5 — Quality validation:**
- All initiative requirements are covered across the epics
- No duplicate epic names
- Dependencies are consistent (if A depends on B, B exists)
- Each epic has a clear, distinct scope
- Total epic count is between 1 and 10

### Post-completion

Confirm "✅ Created N epic outlines for initiative: <name>" and list all created epic files as bare relative paths, one per line:

```
✅ Created N epic outlines for initiative: <name>

.ccpm/initiatives/<name>/<epic-1>/epic.md
.ccpm/initiatives/<name>/<epic-2>/epic.md
```

Show the dependency relationships and suggested execution order after the file listing.

**Next steps to suggest:**
- "Decompose an epic into tasks: decompose the `<epic-name>` epic"
- "Start all epics sequentially: start all epics for `<name>`"

### Error handling
- If epic creation partially completes, list which epics were created and which failed.
- Never leave the initiative in an inconsistent state — clean up partial files on failure.
- If the initiative document is incomplete, list the specific missing sections.

---

## Initiative Go

**Trigger**: User wants to go from initiative to running agents in one step, for small features (1-3 epics).

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Verify `.ccpm/initiatives/<name>/<name>.md` exists. If missing: "❌ Initiative not found. Create it first."
- If an epic already exists under `.ccpm/initiatives/<name>/<name>/epic.md`, confirm overwrite.

### Process

This is a convenience wrapper that runs decompose, epic-decompose, and epic-start sequentially without GitHub sync.

**Phase 1 — Decompose the initiative** into epics following the Initiative Decompose workflow above. Creates the `initiative/<name>` branch from main.

**Phase 2 — Decompose each epic** into tasks following the process in `references/structure.md`. For each epic created in Phase 1:
- Read the epic, analyze for parallelism
- Create numbered task files using IDs from `.ccpm/next-id`
- Update the epic with a task summary section

**Phase 3 — Execute all tasks** on the initiative branch following the Starting an Initiative workflow in `references/execute.md`. Collect tasks from all epics, resolve dependencies across epics, and launch agents for ready tasks. Wait for all tasks to complete.

If any phase fails, stop and report what completed successfully. Earlier phases' artifacts (epic files, task files) remain intact for manual retry.

**Do NOT merge to main.** The initiative branch is the final output of initiative-go. The user reviews the result and decides when to merge via `@ccpm merge initiative <name>`.

### Post-completion

```
Initiative Go Complete: <name>

Phase 1: Decompose ✓
  - Branch: initiative/<name>
  - Epics created: N

Phase 2: Epic Decompose ✓
  - Total tasks: N (parallel: N | sequential: N)

Phase 3: Execute All ✓
  - Tasks completed: N
  - Agents launched: N

Ready to merge: merge the <name> initiative
```

### Error handling
- Phase 1 failure: stop immediately — "❌ Decompose failed. Check `.ccpm/initiatives/<name>/<name>.md`"
- Phase 2 failure: stop — "❌ Epic decompose failed for `<epic-name>`. Task files may be partial."
- Phase 3 failure: stop — "❌ Task execution failed. Check task status in `.ccpm/initiatives/<name>/`."

---

## Epic Start All

**Trigger**: User wants to start all epics in an initiative, running autonomously until all complete.

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Verify `.ccpm/initiatives/<name>/<name>.md` exists.
- Verify initiative branch exists: `git branch --list "initiative/<name>"`
- Find all epics: glob for `.ccpm/initiatives/<name>/*/epic.md`. If none: "❌ No epics found. Decompose the initiative first."
- Check for uncommitted changes: `git status --porcelain` — block if dirty.

### Process

**Step 1 — Build execution order.** Read each epic's `depends_on` frontmatter field. Sort topologically:
- Epics with no dependencies first
- Epics depending on others come after their dependencies
- If circular dependencies detected: "❌ Circular epic dependency: `<details>`"

Report the planned order before starting. This determines task priority — tasks from earlier epics are preferred when choosing what to launch next.

**Step 2 — Prepare and execute tasks** on the `initiative/<name>` branch.

**(a) Decompose if needed.** For each epic, if no task files (`[0-9]*.md`) exist in the epic directory, decompose the epic into tasks first (see `references/structure.md`).

**(b) Collect all task files** from all epics: `.ccpm/initiatives/<name>/*/[0-9]*.md`

**(c) Build unified dependency graph** across all epics. Resolve cross-epic dependencies using task IDs.

**(d) Launch agents for ready tasks** on the `initiative/<name>` branch following the Starting an Initiative workflow in `references/execute.md`. Identify ready tasks from frontmatter (`status`, `depends_on`, `parallel`).

**(e) As tasks complete, launch newly unblocked tasks.** When all tasks for an epic finish, update that epic's status to "completed" in its frontmatter. Report progress:
```
✅ Epic complete: <epic-name> (N tasks)
   Remaining: M epics
```

**Step 3 — Run tests.** After all tasks complete on the initiative branch, run the project test suite.

### Post-completion

```
✅ All epics complete for initiative: <name>

Epics completed:
  ✅ <epic-1>: N tasks
  ✅ <epic-2>: N tasks

Total tasks: N
Ready to merge to main: merge the <name> initiative
```

### Error handling
- If a task fails (agent errors, test failures), stop immediately.
- Report which epics completed, which failed, and which were not started.
- All completed work remains on `initiative/<name>`.
- Suggest fixing the issue and retrying the failed task, or merging what is done.

---

## Initiative Merge

**Trigger**: User wants to merge a completed initiative back to main.

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Verify `.ccpm/initiatives/<name>/<name>.md` exists.
- Verify `initiative/<name>` branch exists. If not: "❌ No branch for initiative: `<name>`"
- Check for uncommitted changes — block if dirty.

### Process

**Step 1 — Check out the initiative branch** and pull latest:
```bash
git checkout initiative/<name>
git pull origin initiative/<name> 2>/dev/null || true
```

**Step 2 — Validate epic completion.** Read each `epic.md` under `.ccpm/initiatives/<name>/*/epic.md`. If any epic has status != "completed", warn the user and confirm before continuing.

**Step 3 — Run tests** on the initiative branch. Report results. If tests fail, confirm before continuing.

**Step 4 — Update initiative status.** Set `status` to "complete" and add `updated` and `completed` fields with current datetime.

**Step 5 — Merge to main:**
```bash
git checkout main
git pull origin main
git merge initiative/<name> --no-ff -m "Merge initiative: <name>

Completed epics:
- <epic-1>
- <epic-2>"
```

**Step 5b — Remove worktree (if present).** Read the initiative's `worktree:` field. If `true`:
```bash
REPO_BASENAME=$(basename "$(git rev-parse --show-toplevel)")
git worktree remove "../${REPO_BASENAME}-<name>" 2>/dev/null || true
```

**Step 6 — Post-merge cleanup:**
```bash
git branch -d initiative/<name>
git push origin --delete initiative/<name> 2>/dev/null || true
```

**Step 7 — Archive the initiative:**
```bash
mkdir -p .ccpm/archive
mv .ccpm/initiatives/<name> .ccpm/archive/<name>
```

This moves the entire initiative directory tree (initiative MD, epic dirs, task files, updates) to the archive. The archive preserves the original structure for historical reference.

### Post-completion

```
✅ Initiative merged: <name>

  Branch: initiative/<name> → main
  Epics completed: N
    - <epic-1>
    - <epic-2>

Cleanup:
  ✓ Initiative archived to .ccpm/archive/<name>
  ✓ Initiative branch deleted
```

### Error handling
- Merge conflicts: abort the merge, report conflicted files, and suggest manual resolution.
- Incomplete epics: warn but allow the user to proceed with confirmation.
- Test failures: warn but allow the user to proceed with confirmation.

---

## Initiative Cancel

**Trigger**: User wants to abandon an initiative, or says "cancel initiative <name>", "abandon the <name> initiative", "drop initiative <name>".

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Verify `.ccpm/initiatives/<name>/<name>.md` exists. If missing: "No initiative found: `<name>`"
- Check for uncommitted changes on `initiative/<name>`. If found, warn the user with details and stop — the user must resolve (commit, stash, or discard) before cancelling.

### Process

**Step 1 — Confirm and choose disposition.** Ask the user:
- "Cancel initiative `<name>`? This will delete the initiative branch. Remove files (default) or archive them?"
- If the user provides a reason, record it.

**Step 2 — Switch to main.** If currently on the initiative branch:
```bash
git checkout main
```

**Step 2b — Remove worktree (if present).** Read the initiative's `worktree:` field. If `true`:
```bash
REPO_BASENAME=$(basename "$(git rev-parse --show-toplevel)")
git worktree remove "../${REPO_BASENAME}-<name>" 2>/dev/null || true
```

**Step 3 — Delete the initiative branch:**
```bash
git branch -D initiative/<name>
git push origin --delete initiative/<name> 2>/dev/null || true
```

**Step 4 — Remove or archive the initiative directory:**
- **Remove** (default): delete `.ccpm/initiatives/<name>/`
- **Archive**: update the initiative frontmatter with `status: cancelled`, `cancelled: <datetime>`, and optionally `cancel_reason: <reason>`. Then move:
  ```bash
  mkdir -p .ccpm/archive
  mv .ccpm/initiatives/<name> .ccpm/archive/<name>
  ```

### Post-completion

```
Initiative cancelled: <name>

  Branch deleted: initiative/<name>
  Files: removed | archived to .ccpm/archive/<name>
```

### Error handling
- Uncommitted changes: stop and list which branches have dirty state. Do not proceed.
- Branch doesn't exist: skip deletion for that branch, continue with the rest.

---

## Add Epic

**Trigger**: User wants to add a new epic to a running initiative, or says "add epic <epic-name> to <initiative-name>", "new epic <epic-name> for <initiative-name>".

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Verify `.ccpm/initiatives/<name>/<name>.md` exists. If missing: "No initiative found: `<name>`"
- Verify `initiative/<name>` branch exists. If not: "No branch for initiative: `<name>`"
- Verify `.ccpm/initiatives/<name>/<epic-name>/` does not already exist. If it does: "Epic `<epic-name>` already exists in initiative `<name>`"
- Check for uncommitted changes — block if dirty.

### Process

**Step 1 — Checkout the initiative branch:**
```bash
git checkout initiative/<name>
```

**Step 2 — Create the epic outline.** Create the directory and file:

Directory: `.ccpm/initiatives/<name>/<epic-name>/`
File: `.ccpm/initiatives/<name>/<epic-name>/epic.md`

Use the same format as Initiative Decompose Step 4:

```markdown
---
name: <epic-name>
status: backlog
created: <run: date -u +"%Y-%m-%dT%H:%M:%SZ">
progress: 0%
initiative: .ccpm/initiatives/<name>/<name>.md
depends_on: [<list of completed epic names>]
---

# Epic: <epic-name>

## Overview
Brief summary of what this epic covers and why it was added.

## Scope
- Key deliverables and boundaries

## Dependencies
- All previously completed epics in this initiative
```

Set `depends_on` to all epics with status `completed` — the new epic builds on their merged work.

**Step 3 — Commit the new epic file** on the initiative branch.

### Post-completion

```
Epic added to initiative: <name>

.ccpm/initiatives/<name>/<epic-name>/epic.md

  Ready to decompose: decompose the <epic-name> epic
```

### Error handling
- If the initiative has already been merged to main, refuse: "Initiative `<name>` is already merged. Create a new initiative instead."
- If epic creation fails, clean up the partial directory.

---

## Worktree Enable

**Trigger**: User wants to enable a worktree for an existing initiative, or says "@ccpm worktree enable <name>".

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Verify `.ccpm/initiatives/<name>/<name>.md` exists. If missing: "No initiative found: `<name>`"
- Verify `initiative/<name>` branch exists. If not: "No branch for initiative: `<name>`"
- Read initiative frontmatter: if `worktree:` is already `true`, check if worktree exists at expected path. If it does: "Worktree already active at `<path>`."
- Check that no worktree already exists at the target path.

### Process

**Step 1 — Create worktree:**
```bash
REPO_BASENAME=$(basename "$(git rev-parse --show-toplevel)")
WORKTREE_PATH="../${REPO_BASENAME}-<name>"
git worktree add "$WORKTREE_PATH" initiative/<name>
```

**Step 2 — Update initiative frontmatter.** Set `worktree: true` in `.ccpm/initiatives/<name>/<name>.md`.

**Step 3 — Update existing epic files.** For each epic under `.ccpm/initiatives/<name>/*/epic.md`, set `worktree_path: ../<repo-basename>-<name>` in frontmatter.

**Step 4 — Commit the frontmatter updates** on the initiative branch.

### Post-completion

```
Worktree enabled for initiative: <name>

  Path: ../<repo-basename>-<name>
  Branch: initiative/<name>

  Updated files:
    .ccpm/initiatives/<name>/<name>.md (worktree: true)
    .ccpm/initiatives/<name>/<epic>/epic.md (worktree_path set)
```

---

## Branching Model

Initiatives use a single-branch model:

```
main
 └── initiative/<name>           ← all work happens here
```

All tasks from all epics execute directly on the initiative branch. Epic directories organize tasks for planning; the initiative branch is the single execution context. When all tasks are complete, `initiative/<name>` merges into `main`.

See `references/conventions.md` for frontmatter schemas and path conventions.
