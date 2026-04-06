# Getting Started

This project produces two flavors of customized CCPM (Claude Code Project Manager). Pick the one that fits your needs:

| Flavor | What you get | TheAgent required? |
|--------|-------------|-------------------|
| **Vanilla** | Customized CCPM with Initiative terminology, `.ccpm/` data directory, local-only mode, root-anchored scripts | No |
| **Agentified** | Everything in Vanilla + IDesign Method architect integration (reviews initiatives, validates epic boundaries, contributes tasks, runs validation gates) | Yes |

Both flavors use `@ccpm` in Claude Code. The agentified flavor adds automatic architect reviews at each delivery phase.

---

## Vanilla CCPM

### Prerequisites

- [Claude Code](https://claude.ai/code)
- A git repository for your project

### Install

Copy the skill into your project's `.claude/skills/` directory:

```bash
# From your project root:
mkdir -p .claude/skills
cp -R /path/to/this-repo/build/tccpm/skill/ccpm .claude/skills/ccpm
```

Or symlink it (useful during development):

```bash
mkdir -p .claude/skills
ln -s /absolute/path/to/this-repo/build/tccpm/skill/ccpm .claude/skills/ccpm
```

### Initialize

Open Claude Code in your project and run:

```
@ccpm init
```

This creates the `.ccpm/` directory structure and optionally sets up GitHub integration.

### First usage

```
@ccpm new initiative for user authentication
```

Claude will brainstorm requirements with you, then guide you through the delivery lifecycle: initiative, epic, tasks, execution, tracking.

### What to expect

- All project data lives in `.ccpm/initiatives/`
- GitHub integration is optional — install and authenticate `gh` CLI to enable it
- Use `@ccpm status` for a project dashboard, `@ccpm standup` for daily reports

---

## Agentified CCPM

Everything in Vanilla, plus automatic IDesign Method architect integration at each phase.

### Prerequisites

- [Claude Code](https://claude.ai/code)
- A git repository for your project
- [TheAgent CLI](https://github.com/rknuus/theagent) — installed and linked globally
- A `.method` directory in your project (create one with `theagent init`)

### Install

1. **Set up TheAgent** in your project (see [TheAgent docs](https://github.com/rknuus/theagent)):

   ```bash
   theagent init          # creates .method directory
   theagent setup --claude       # first time: registers MCP server with Claude Code
   theagent setup --claude --force # subsequent runs: overwrites existing config
   ```

   > **Migrating from an older TheAgent version?** If you have a single `.method` file (not a directory), migrate it to the new directory format. Do **not** re-initialize — that would discard your existing architecture. Run from your project directory:
   > ```bash
   > node --input-type=module -e "
   > import { convertLegacy } from '$(npm root -g)/@theagent/mcp-server/dist/tools/convert-legacy.js';
   > console.log(JSON.stringify(convertLegacy({ file_path: '$(ls *.method)' }), null, 2));
   > "
   > ```

2. **Copy the agentified skill** into your project:

   ```bash
   mkdir -p .claude/skills
   cp -R /path/to/this-repo/build/accpm/skill/ccpm .claude/skills/ccpm
   ```

   Or symlink:

   ```bash
   mkdir -p .claude/skills
   ln -s /absolute/path/to/this-repo/build/accpm/skill/ccpm .claude/skills/ccpm
   ```

### Edition selection

TheAgent ships two knowledge editions:

| Edition | Environment variable | Knowledge source |
|---------|---------------------|-----------------|
| **Default** (community) | *(none — this is the default)* | Community-sourced, publicly available IDesign materials |
| **Unchained** (proprietary) | `THEAGENT_EDITION=unchained` | Proprietary IDesign knowledge from books, clinics, and alumni community |

The edition affects the depth of architect reviews — the same MCP tools are available in both, but unchained provides richer design knowledge, soft rules, and dialectic questions.

To use the unchained edition, set the environment variable before starting Claude Code:

```bash
THEAGENT_EDITION=unchained claude
```

Or configure it permanently in your shell profile:

```bash
export THEAGENT_EDITION=unchained
```

> **Note**: The unchained edition requires access to the private TheAgent repository. The default (community) edition is available from the [public repository](https://github.com/rknuus/theagent).

### Initialize

Open Claude Code in your project and run:

```
@ccpm init
```

### First usage

```
@ccpm new initiative for user authentication
```

After brainstorming the initiative, the architect automatically reviews it against your `.method` architecture — checking alignment with volatilities, components, and use cases. This happens at each phase:

| Phase | Architect integration |
|-------|----------------------|
| **Plan** | Reviews initiative against `.method` volatilities, components, use cases |
| **Decompose** | Validates epic boundaries against component topology |
| **Structure** | Contributes architecture-derived tasks, merged with delivery tasks |
| **Execute** | Runs validation gates before and after agent execution |
| **Sync / Track** | No architect involvement |

### What to expect

- Everything from Vanilla, plus `## Architect Review` sections appended to initiative, epic, and task files
- Validation findings (errors, warnings) surfaced during execution
- Architecture diagrams generated at initiative completion
- If TheAgent MCP tools are unavailable (e.g., no `.method` file), architect integration is skipped gracefully — CCPM continues to work as vanilla

---

## Permissions

CCPM uses various shell commands during its workflow. Without proper permissions, Claude Code will prompt for approval on each invocation. Configure permissions once to avoid repeated prompts.

> **Alternative**: If you prefer, use YOLO mode (`--dangerously-skip-permissions`) to skip all prompts. The settings below are for users who want fine-grained control.

### Global settings (all projects)

Add these to `~/.claude/settings.json` under `permissions.allow`. These commands are safe in any project:

```json
{
  "permissions": {
    "allow": [
      "Bash(date:*)",
      "Bash(echo *)",
      "Bash(grep:*)",
      "Bash(find *)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(wc:*)",
      "Bash(cat *)",
      "Bash(ls *)",
      "Bash(mkdir:*)",
      "Bash(diff:*)",
      "Bash(sort:*)",
      "Bash(git branch:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git rev-parse:*)",
      "Bash(git remote:*)",
      "Bash(git show:*)",
      "Bash(git status:*)",
      "Bash(git worktree:*)",
      "Bash(basename:*)",
      "Edit(.ccpm/**)",
      "Read(.ccpm/**)",
      "Write(.ccpm/**)"
    ],
    "deny": [
      "Bash(find * -exec *)",
      "Bash(find * -execdir *)"
    ]
  }
}
```

### Project settings (per CCPM project)

Add these to `.claude/settings.local.json` in your project root. These commands modify project state and are specific to CCPM workflows:

```json
{
  "permissions": {
    "allow": [
      "Bash(git add:*)",
      "Bash(git checkout:*)",
      "Bash(git commit:*)",
      "Bash(git merge:*)",
      "Bash(git pull:*)",
      "Bash(git push:*)",
      "Bash(git stash:*)",
      "Bash(make:*)",
      "Bash(sed:*)",
      "Bash(mv:*)",
      "Bash(gh:*)",
      "Bash(bash .claude/skills/ccpm/references/scripts/*.sh:*)"
    ]
  }
}
```

### What each tier covers

| Tier | Where | What |
|------|-------|------|
| **Global** | `~/.claude/settings.json` | Read-only utilities, `mkdir`, git read-only, `git worktree`, `basename`, `.ccpm/**` file ops |
| **Project** | `.claude/settings.local.json` | Git write ops, `make`, `sed` for frontmatter, `mv` for task renames, `gh` for GitHub, CCPM helper scripts |
| **Prompt** | Not pre-approved | Destructive operations (`rm -rf`, `git push --force`, `git reset --hard`) |
