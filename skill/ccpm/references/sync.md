# Sync — Push to GitHub & Track Progress

This phase covers pushing local epics/tasks to GitHub as issues, syncing progress as comments, and closing issues when work is done.

---

## GitHub Availability

Before any sync operation, check GitHub availability:

```bash
GH_AVAILABLE=false
if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  GH_AVAILABLE=true
fi
```

If `GH_AVAILABLE` is false, skip all GitHub operations and work in local-only mode. Local task files in `.ccpm/` remain the source of truth.

---

## Repository Safety Check

**Always run this before any GitHub write operation.**

Run and read the output:
```bash
git remote get-url origin 2>/dev/null || echo ""
```

If the URL contains `automazeio/ccpm`, stop: "Cannot sync to the CCPM template repository." Otherwise, extract the `OWNER/REPO` slug from the URL (strip `github.com[:/]` prefix and `.git` suffix) and use it as `REPO` in subsequent `gh` commands.

---

## Epic Sync — Push Epic + Tasks to GitHub

> **Local-only mode**: Skip this section entirely in local-only mode. Epic and task files in `.ccpm/` serve as the local record.

**Trigger**: User wants to push a local epic and its tasks to GitHub as issues.

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Verify `.ccpm/initiatives/<initiative>/<name>/epic.md` exists.
- Verify task files exist — if none: "❌ No tasks to sync. Decompose the epic first."

### Process

**Step 1 — Create epic issue:**

Strip frontmatter from epic.md:
```bash
sed '1,/^---$/d; 1,/^---$/d' .ccpm/initiatives/<initiative>/<name>/epic.md > /tmp/epic-body.md
```

Then create the issue and read the output to get the issue number:
```bash
gh issue create \
  --repo "<REPO>" \
  --title "Epic: <name>" \
  --body-file /tmp/epic-body.md \
  --label "epic,epic:<name>,feature" \
  --json number -q .number
```

**Step 2 — Create task sub-issues:**

Check if `gh-sub-issue` extension is available:
```bash
if gh extension list | grep -q "yahsan2/gh-sub-issue"; then
  use_subissues=true
fi
```

For <5 tasks: create sequentially.
For ≥5 tasks: use parallel Task agents (3-4 tasks per batch).

Per task — strip frontmatter:
```bash
sed '1,/^---$/d; 1,/^---$/d' <task_file> > /tmp/task-body.md
```

Then create the issue and read the output to get the issue number:
```bash
gh issue create \
  --repo "<REPO>" \
  --title "<task_name>" \
  --body-file /tmp/task-body.md \
  --label "task,epic:<name>" \
  --json number -q .number
```
If using sub-issues: `gh sub-issue create --parent <epic_number> ...`

**Step 3 — Rename task files and update references:**

After all issues are created, rename `<id>.md` → `<issue_number>.md` and update all `depends_on`/`conflicts_with` arrays to use real issue numbers (not local IDs).

```bash
# Build old→new mapping, then for each task file:
sed -i.bak "s/\b<old_id>\b/<new_num>/g" <file>  # repeat for each mapping
mv <old_id>.md <new_num>.md
```

**Step 4 — Update frontmatter:**

Get the current timestamp:
```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

Then use the Edit tool to update `github:` and `updated:` fields in epic.md and each task file:
- `github: https://github.com/<REPO>/issues/<number>`
- `updated: <timestamp>`

**Step 5 — Create worktree for the epic:**

Determine the parent branch using the same detection as execute.md. Run and read the output:
```bash
bash "${SKILL_ROOT:-.claude/skills/ccpm}/references/scripts/ccpm-find.sh" .ccpm/initiatives -path "*/<name>/epic.md" | head -1
```

If a result is found, extract the initiative name (first path segment after `.ccpm/initiatives/`). Then check if `initiative/<initiative_name>` branch exists:
```bash
git branch -a | grep -q "initiative/<initiative_name>"
```

Use the initiative branch as `PARENT_BRANCH` if it exists, otherwise use `main`. Then:
```bash
git checkout <PARENT_BRANCH> && git pull origin <PARENT_BRANCH> 2>/dev/null || true
git worktree add ../epic-<name> -b epic/<name>
```

**Step 6 — Create github-mapping.md:**
```markdown
# GitHub Issue Mapping
Epic: #<N> - https://github.com/<repo>/issues/<N>
Tasks:
- #<N>: <title> - https://github.com/<repo>/issues/<N>
Synced: <datetime>
```

**Output:**
```
✅ Synced epic <name> to GitHub
  Epic: #<N>
  Tasks: N sub-issues
  Worktree: ../epic-<name>
  Next: "start working on issue <N>" or "start the <name> epic"
```

---

## Issue Sync — Post Progress to GitHub

> **Local-only mode**: In local-only mode, update the local task file status and progress directly. Skip GitHub comment posting.

**Trigger**: User wants to sync local development progress to a GitHub issue as a comment.

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- If `GH_AVAILABLE`: Verify issue exists: `gh issue view <N> --json state`
- Check `.ccpm/initiatives/<initiative>/<epic>/updates/<N>/` exists with a `progress.md` file.
- Check `last_sync` in progress.md — if synced <5 minutes ago, confirm before proceeding.

### Process

Gather updates from `.ccpm/initiatives/<initiative>/<epic>/updates/<N>/` (progress.md, notes.md, commits.md).

Format and post a comment (skip if `GH_AVAILABLE` is false):
```bash
gh issue comment <N> --body-file /tmp/update-comment.md
```

Comment format:
```markdown
## 🔄 Progress Update - <date>

### ✅ Completed Work
### 🔄 In Progress
### 📝 Technical Notes
### 📊 Acceptance Criteria Status
### 🚀 Next Steps
### ⚠️ Blockers

---
*Progress: N% | Synced at <timestamp>*
```

After posting: update `last_sync` in progress.md frontmatter, update `updated` in the task file.

Add sync marker to local files to prevent duplicate comments:
```markdown
<!-- SYNCED: <datetime> -->
```

---

## Closing an Issue

> **Local-only mode**: In local-only mode, update local frontmatter `status: closed` only. Skip GitHub comment posting, issue closing, and epic issue body updates.

**Trigger**: User marks a task complete.

### Process

1. Find the local task file (`.ccpm/initiatives/<initiative>/<epic>/<N>.md`).
2. Update frontmatter: `status: closed`, `updated: <now>`.
3. Post completion comment (skip if `GH_AVAILABLE` is false):
```bash
echo "✅ Task completed — all acceptance criteria met." | gh issue comment <N> --body-file -
gh issue close <N>
```
4. Check off the task in the epic issue body (skip if `GH_AVAILABLE` is false):
```bash
gh issue view <epic_N> --json body -q .body > /tmp/epic-body.md
sed -i "s/- \[ \] #<N>/- [x] #<N>/" /tmp/epic-body.md
gh issue edit <epic_N> --body-file /tmp/epic-body.md
```
5. Recalculate and update epic progress: `progress = closed_tasks / total_tasks * 100`

---

## Merging an Epic

> **Local-only mode**: In local-only mode, skip GitHub updates; local status is updated by the merge process. `git push/pull` operations fail silently.

**Trigger**: User wants to merge a completed epic back to main.

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Verify worktree `../epic-<name>` exists.
- Check for uncommitted changes in the worktree — block if dirty.
- Warn if any task issues are still open.

### Epic Merge — Target Branch

When merging a completed epic, determine the target branch:

1. Use the same parent-branch detection as execute.md
2. If target is `initiative/{name}`: merge epic branch into initiative branch
3. If target is `main`: merge epic branch directly into main (single-epic mode)

After merging, clean up the epic branch but do NOT delete the initiative branch (other epics may still need it).

### Process

**Run tests** from the worktree (detect and run: npm test / pytest / cargo test / go test / etc.):
```bash
bash "${SKILL_ROOT:-.claude/skills/ccpm}/references/scripts/ccpm-worktree-git.sh" ../epic-<name> status
```

**Determine merge target** — find the epic's initiative:
```bash
bash "${SKILL_ROOT:-.claude/skills/ccpm}/references/scripts/ccpm-find.sh" .ccpm/initiatives -path "*/<name>/epic.md" | head -1
```

If found, extract the initiative name (first segment after `.ccpm/initiatives/`) and check for its branch:
```bash
git branch -a | grep -q "initiative/<initiative_name>"
```

Use the initiative branch as `MERGE_TARGET` if it exists, otherwise use `main`.

**Merge and push:**
```bash
git checkout <MERGE_TARGET> && git pull origin <MERGE_TARGET> 2>/dev/null || true
git merge epic/<name> --no-ff -m "Merge epic: <name>"
git push origin <MERGE_TARGET> 2>/dev/null || true
```

**Cleanup epic branch** (do NOT delete the initiative branch):
```bash
git worktree remove ../epic-<name>
git branch -d epic/<name>
git push origin --delete epic/<name> 2>/dev/null || true
```

**Archive:**
```bash
mkdir -p .ccpm/archived/
mv .ccpm/initiatives/<initiative>/<name> .ccpm/archived/<initiative>/
```

**Close GitHub issues** (skip in local-only mode). Read the epic file to get the issue number from the `github:` field, then:
```bash
gh issue close <epic_issue_number> -c "Epic completed and merged to <MERGE_TARGET>"
```

Update epic.md frontmatter: `status: completed`.

> **Note**: Merging the initiative branch itself back to `main` is handled separately — see initiative.md.

---

## Reporting a Bug Against a Completed Issue

> **Local-only mode**: In local-only mode, create a bug task file directly in the epic directory (Step 2). Skip Steps 1, 3, and 4 (GitHub operations). Use the next local ID from `.ccpm/next-id` for the filename.

**Trigger**: User finds a bug while testing a completed or in-progress issue — e.g. "found a bug in issue 42", "email validation is broken, came up while testing issue 42".

The workflow should stay automated: create a linked bug task without losing context from the original issue.

### Process

**Step 1 — Read the original issue for context** (skip if `GH_AVAILABLE` is false):
```bash
gh issue view <original_N> --json title,body,labels
```
Also read the local task file if it exists: `.ccpm/initiatives/<initiative>/<epic>/<original_N>.md`

**Step 2 — Create a local bug task file:**

```markdown
---
name: Bug: <short description>
status: open
created: <run: date -u +"%Y-%m-%dT%H:%M:%SZ">
updated: <same>
github: (will be set on sync)
depends_on: []
parallel: false
conflicts_with: []
bug_for: <original_N>
---

# Bug: <short description>

## Context
Found while working on / testing issue #<original_N>: <original title>

## Description
<what's broken>

## Steps to Reproduce
<steps>

## Expected vs Actual
- Expected:
- Actual:

## Acceptance Criteria
- [ ] Bug is fixed
- [ ] Original issue #<original_N> behaviour is unaffected

## Effort Estimate
- Size: XS/S
```

Save to `.ccpm/initiatives/<initiative>/<epic>/bug-<original_N>-<slug>.md`

**Step 3 — Create a linked GitHub issue** (skip if `GH_AVAILABLE` is false):
```bash
gh issue create \
  --repo "<REPO>" \
  --title "Bug: <short description>" \
  --body-file /tmp/bug-body.md \
  --label "bug,epic:<epic_name>" \
  --json number -q .number
```

The issue body should open with `Fixes / follow-up to #<original_N>` so GitHub auto-links them.

**Step 4 — Update the local file** with the GitHub issue number and rename to `<new_N>.md`. In local-only mode, keep the local ID from `.ccpm/next-id` as the filename.

**Output:**
```
✅ Bug issue created: #<new_N> — "Bug: <short description>"
  Linked to: #<original_N>
  Epic: <epic_name>

Start fixing it: "start working on issue <new_N>"
```
