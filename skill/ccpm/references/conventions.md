# Conventions — File Formats, Paths & Rules

Read this before doing any file operations across all phases.

---

## Directory Structure

```
.ccpm/
├── settings.yml                     # Project-level CCPM settings (optional)
├── initiatives/
│   ├── <name>.md                    # Initiative document
│   └── <name>/                      # Epics for this initiative
│       └── <epic-name>/             # Epic directory
│           ├── epic.md              # Epic document
│           ├── <N>.md               # Task files (N = global ID)
│           └── updates/             # Work-in-progress updates
│               └── <issue_N>/
│                   └── stream-A.md  # Per-agent progress
├── archive/                         # Completed initiatives (moved on merge)
│   └── <name>/                      # Archived initiative (same structure as initiatives/)
│       ├── <name>.md                # Initiative document
│       └── <epic-name>/             # Epic directory (preserved)
│           ├── epic.md
│           └── <N>.md
└── next-id                          # Global task ID counter
```

---

## Root Anchoring

All `.ccpm/` paths are relative to the git project root (`git rev-parse --show-toplevel`). To prevent `.ccpm/` from being created in a subdirectory:

**In bash scripts**: Every script that accesses `.ccpm/` must `cd` to the git root as its first executable statement:

```bash
cd "$(git rev-parse --show-toplevel)" || exit 1
```

**In sourced libraries** (e.g., `paths-lib.sh`): Do not `cd` — the caller is responsible for being at the root before sourcing.

**In phase Preflight sections** (mandatory first step): Before any `.ccpm/` access, run `git rev-parse --show-toplevel` and confirm the output matches the current working directory. If it does not, `cd` to the project root before proceeding. Do not use `$()` — run the command directly and read the output.

---

## Command Authorization

An explicit `@ccpm` command is authorization to proceed. Do not ask "shall I proceed?" or "approve this plan?" when the user has already given a command.

- **Proceed by default**: `@ccpm decompose` means create the task files. `@ccpm initiative-go` means run all phases. Show the result, not a preview.
- **Report, don't ask**: After completing work, report what was done (e.g., "Created 5 tasks for epic: auth"). Do not present a plan and wait for approval.
- **Prompt only when destructive or ambiguous**: Overwriting existing files, merging with incomplete epics, or failing tests warrant a confirmation. Routine creation does not.

---

## Command Safety

Keep Bash tool calls simple and single-purpose so each one matches a permission pattern (e.g., `Bash(go test:*)`) and can be approved once. The permission monitor flags shell metacharacters — avoid them.

| Rule | Do | Don't |
|---|---|---|
| **Prefer native tools over Bash** | Edit tool for file changes, Read tool for reading, Grep tool for searching content, Glob tool for finding files | `sed`, `cat`/`head`/`tail`, `grep` in Bash, `find`/`ls` in Bash |
| **One command per Bash call** | Separate Bash tool calls for each command | `git checkout main && git pull origin main` |
| **No stderr redirection** | Run the command plain; handle errors in the next step. For optional operations, note "skip on failure" in surrounding instruction text | `git remote get-url origin 2>/dev/null` |
| **No command substitution in Bash calls** | Run the command in one Bash call, reference the output in the next | `` `cmd` `` or `$(cmd)` inside a Bash tool call |
| **Simple, single-purpose commands** | `go test ./...` | `cd dir && go test 2>&1 \| head` |

**Scripts are exempt**: The monitor only sees the top-level Bash tool call (e.g., `bash references/scripts/status.sh`), not commands executed within the script.

---

## Task ID Counter

The file `.ccpm/next-id` contains the next available globally unique task ID as a plain integer. Before creating any task files, read this value. After creating all tasks, update it to the next unused value.

Read `.ccpm/next-id` (via the Read tool) to get the next available ID. After creating all tasks, write the next unused value:

```bash
echo "<new_next_id>" > .ccpm/next-id
```

---

## Frontmatter Schemas

### Initiative (.ccpm/initiatives/<name>.md)
```yaml
---
name: <feature-name>        # kebab-case, matches filename
description: <one-liner>    # used in lists and summaries
status: backlog | in-progress | complete | cancelled
created: <ISO 8601>         # date -u +"%Y-%m-%dT%H:%M:%SZ"
worktree: false              # optional; true = use git worktree for this initiative
cancelled: <ISO 8601>       # set on cancel (optional)
cancel_reason: <text>        # why it was cancelled (optional)
---
```

### Epic (.ccpm/initiatives/<initiative>/<name>/epic.md)
```yaml
---
name: <feature-name>
status: backlog | in-progress | completed
created: <ISO 8601>
updated: <ISO 8601>
progress: 0%                # recalculated when tasks close
initiative: .ccpm/initiatives/<initiative>/<name>.md
depends_on: []              # list of epic names that must complete first
github: https://github.com/<owner>/<repo>/issues/<N>  # set on sync
worktree_path:               # optional; path to initiative worktree (derived)
---
```

### Task (.ccpm/initiatives/<initiative>/<name>/<N>.md)
```yaml
---
name: <Task Title>
status: open | in-progress | closed
created: <ISO 8601>
updated: <ISO 8601>
github: https://github.com/<owner>/<repo>/issues/<N>  # set on sync
depends_on: []              # issue numbers this must wait for
parallel: true              # can run concurrently with non-conflicting tasks
conflicts_with: []          # issue numbers that touch the same files
worktree_path:               # optional; inherited from epic
---
```

### Progress (.ccpm/initiatives/<initiative>/<name>/updates/<N>/progress.md)
```yaml
---
issue: <N>
started: <ISO 8601>
last_sync: <ISO 8601>
completion: 0%
---
```

---

## Datetime Rule

Always get real current datetime from the system — never use placeholder text:
```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

---

## Frontmatter Update Pattern

When updating a single frontmatter field in an existing file:

Use the Edit tool to replace the frontmatter line. Match the full line (e.g., `status: backlog`) and replace with the new value (e.g., `status: in-progress`).

When stripping frontmatter to get body content for GitHub:

Use the Read tool with `offset` to skip frontmatter lines, then use the body content directly.

---

## GitHub Operations

### Repository Safety Check (run before any write operation)

Run `git remote get-url origin` as a plain command. If no remote exists, the command will fail — check the output and proceed accordingly.

If the URL contains `automazeio/ccpm`, stop: "Cannot write to the CCPM template repository." Otherwise, extract the `OWNER/REPO` slug from the URL (strip `github.com[:/]` prefix and `.git` suffix) and use it as `REPO` in subsequent `gh` commands.

### Authentication
Don't pre-check authentication. Run the `gh` command and handle failure:
```bash
gh <command> || echo "❌ GitHub CLI failed. Run: gh auth login"
```

### Getting Issue Numbers

Use the Grep tool to search for the `github:` field in the task file, then extract the issue number from the matched line.

---

## Git / Branch Conventions

- One branch per initiative: `initiative/<name>`
- Always start branches from an up-to-date main:
  ```bash
  git checkout main
  ```
  ```bash
  git pull origin main
  ```
  ```bash
  git checkout -b initiative/<name>
  ```
- Commit format: `Issue #<N>: <description>`
- Never use `--force` in any git operation

## Worktree Conventions

When `worktree: true` is set on an initiative, a git worktree is created as a sibling directory:

- **Path**: `../<repo-basename>-<initiative-name>/` (sibling to project root)
- **Created**: during initiative decompose or via `@ccpm worktree enable <name>`
- **Scope**: one worktree per initiative — all epics share it
- **Cleanup**: removed via `git worktree remove` during initiative merge or cancel
- **Creation**: `git worktree add ../<repo-basename>-<name> initiative/<name>`

Worktrees are optional. Initiatives without `worktree: true` use plain branches (existing behavior).

---

## Naming Conventions

- Feature names: kebab-case, lowercase, letters/numbers/hyphens, starts with a letter
- Task files before sync: use globally unique IDs from `.ccpm/next-id` (e.g., `42.md`, `43.md`)
- Task files after sync: renamed to GitHub issue number (e.g., `1234.md`)
- Labels applied on sync: `epic`, `epic:<name>`, `feature` (for epics); `task`, `epic:<name>` (for tasks)

---

## Epic Progress Calculation

Use the Glob tool to find task files matching `.ccpm/initiatives/<initiative>/<name>/[0-9]*.md`, then use the Grep tool to find which of those contain `status: closed`. Calculate progress as `closed * 100 / total`.

Update epic frontmatter when any task closes.

---

## Local-Only Mode

CCPM works without GitHub. If `gh` CLI is not installed or not authenticated:
- All GitHub sync operations are skipped
- Task files in `.ccpm/` are the source of truth
- Git branches still provide epic isolation
- `git push/pull` operations fail silently (local branches only)

To enable GitHub integration later, install `gh` and run `bash references/scripts/init.sh`.
