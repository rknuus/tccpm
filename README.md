# TCCPM — Tailored CCPM

[![Fork of automazeio/ccpm](https://img.shields.io/badge/fork_of-automazeio%2Fccpm-4b3baf)](https://github.com/automazeio/ccpm)
&nbsp;
[![Agent Skills](https://img.shields.io/badge/Agent_Skills-compatible-4b3baf)](https://agentskills.io)
&nbsp;
[![MIT License](https://img.shields.io/badge/License-MIT-28a745)](LICENSE)

### Spec-driven development for AI agents — ship better using Initiatives and multiple agents running in parallel.

Stop losing context. Stop blocking on tasks. Stop shipping bugs. TCCPM turns Initiatives into epics, epics into tasks, and tasks into production code — with full traceability at every step.

> **This is a tailored variant** of [automazeio/ccpm](https://github.com/automazeio/ccpm) v2 with additional features: multi-epic initiatives, local-only mode (GitHub optional), context management, `.ccpm/` data separation, globally unique task IDs, and `@ccpm` explicit invocation.

## Table of Contents

- [Background](#background)
- [The Workflow](#the-workflow)
- [What Makes This Different?](#what-makes-this-different)
- [Core Principle: No Vibe Coding](#core-principle-no-vibe-coding)
- [System Architecture](#system-architecture)
- [Workflow Phases](#workflow-phases)
- [Usage](#usage)
- [The Parallel Execution System](#the-parallel-execution-system)
- [Key Features & Benefits](#key-features--benefits)
- [Get Started Now](#get-started-now)
- [Permissions](#permissions)
- [Tailoring-Specific Features](#tailoring-specific-features)
- [License](#license)

## Background

Every team struggles with the same problems:
- **Context evaporates** between sessions, forcing constant re-discovery
- **Parallel work creates conflicts** when multiple developers touch the same code
- **Requirements drift** as verbal decisions override written specs
- **Progress becomes invisible** until the very end

This system solves all of that.

## The Workflow

```mermaid
graph LR
    A[Initiative] --> B[Epic Planning]
    B --> C[Task Decomposition]
    C --> D[Parallel Execution]
    D --> E[Merge to Main]
```

### Simple — Small Features

Go from idea to running agents in one step:

```
@ccpm create an initiative for memory-system     # Brainstorm and write the initiative
@ccpm initiative-go memory-system                # Parse -> decompose -> start agents
@ccpm merge the memory-system initiative         # Merge everything to main
```

### Step-by-Step — Single Epic, Full Control

Pause between phases to review and refine:

```
@ccpm create an initiative for memory-system     # Brainstorm
@ccpm decompose memory-system into epics         # Convert to technical epic(s)
@ccpm break down the memory-system epic          # Break into tasks
@ccpm start the memory-system epic               # Launch parallel agents
@ccpm merge the memory-system initiative         # Merge everything to main
```

### Multi-Epic — Large Initiatives (up to 10 epics)

For features that need multiple coordinated epics:

```
@ccpm create an initiative for auth-system       # Brainstorm
@ccpm decompose auth-system into epics           # Break into multiple epics

# Decompose each epic (review and refine between steps):
@ccpm break down the login-flow epic             # Break first epic into tasks
@ccpm break down the oauth-providers epic        # Break second epic into tasks

# Start all epics sequentially — no interaction until done:
@ccpm start all epics for auth-system

@ccpm merge the auth-system initiative           # Merge everything to main
```

> **Tip:** Prefix any message with `@ccpm` to ensure CCPM handles it (bypasses Claude's built-in planning mode). You can also use natural language — CCPM activates when you mention initiatives, epics, or tasks.

## What Makes This Different?

| Traditional Development | CCPM |
|------------------------|------|
| Context lost between sessions | **Persistent context** across all work |
| Serial task execution | **Parallel agents** on independent tasks |
| "Vibe coding" from memory | **Spec-driven** with full traceability |
| Progress hidden in branches | **Transparent audit trail** in local files |
| Manual task coordination | **Intelligent prioritization** via `@ccpm what's next` |

## Core Principle: No Vibe Coding

> **Every line of code must trace back to a specification.**

We follow a strict 5-phase discipline:

1. **Brainstorm** - Think deeper than comfortable
2. **Document** - Write specs that leave nothing to interpretation
3. **Plan** - Architect with explicit technical decisions
4. **Execute** - Build exactly what was specified
5. **Track** - Maintain transparent progress at every step

No shortcuts. No assumptions. No regrets.

## System Architecture

TCCPM is an **Agent Skill** installed as a symlink or copy in `.claude/skills/ccpm/`. The skill definition lives in `skill/ccpm/` and PM data lives in `.ccpm/` (separate from project configuration in `.claude/`).

```
<your-project>/
├── .claude/
│   ├── skills/
│   │   └── ccpm -> /path/to/tccpm/skill/ccpm   # Symlink to skill
│   ├── rules/                    # CCPM rules (loaded by harness)
│   └── context/                  # Project context files
└── .ccpm/                        # PM workspace
    ├── initiatives/
    │   ├── [name].md             # Initiative document
    │   └── [name]/               # Epics for this initiative
    │       └── [epic-name]/      # Epic directory
    │           ├── epic.md       # Epic document
    │           ├── [N].md        # Task files (globally unique IDs)
    │           └── updates/      # Work-in-progress updates
    ├── archive/                  # Completed initiatives
    └── next-id                   # Global task ID counter
```

The skill itself (SKILL.md, reference docs, scripts) lives in `skill/ccpm/` within the TCCPM repository. PM data in `.ccpm/` can be gitignored in consumer projects.

## Workflow Phases

### 1. Plan — Capture requirements

```
@ccpm create an initiative for feature-name
```
Launches comprehensive brainstorming to create an Initiative capturing vision, user stories, success criteria, and constraints.

**Output:** `.ccpm/initiatives/feature-name.md`

### 2. Initiative — Multi-epic decomposition

```
@ccpm decompose feature-name into epics
```
Breaks the initiative into 1-10 epics with dependency ordering.

**Output:** `.ccpm/initiatives/feature-name/[epic-name]/epic.md`

### 3. Structure — Break it down

```
@ccpm break down the epic-name epic into tasks
```
Breaks each epic into concrete, actionable tasks (up to 10 per epic) with acceptance criteria, effort estimates, and parallelization flags.

**Output:** `.ccpm/initiatives/feature-name/[epic-name]/[N].md`

### 4. Execute — Start building

```
@ccpm start the epic-name epic
@ccpm what's next
```
Specialized agents implement tasks while maintaining progress updates. All tasks execute on the initiative branch.

### 5. Track and Merge

```
@ccpm what's our status
@ccpm merge the feature-name initiative
```
Merges the initiative branch into main. Validates task completion and runs tests before merging.

## Usage

TCCPM is an Agent Skill activated via natural language. Prefix with `@ccpm` for explicit invocation, or use CCPM vocabulary (initiative, epic, task) for intent-based activation.

### Quick Reference

```
Create initiative:   @ccpm create an initiative for X
Decompose:           @ccpm decompose X into epics
Break into tasks:    @ccpm break down the X epic
Start epic:          @ccpm start the X epic
Start all epics:     @ccpm start all epics for X
Check status:        @ccpm what's our status / @ccpm standup
What's next:         @ccpm what should I work on next
What's blocked:      @ccpm what's blocked
Merge initiative:    @ccpm merge the X initiative
Create context:      @ccpm create context
Load context:        @ccpm prime context
Search:              @ccpm search for X
Validate:            @ccpm validate project state
```

> GitHub integration is optional. TCCPM works in local-only mode without `gh` CLI.

## The Parallel Execution System

### Issues Aren't Atomic

Traditional thinking: One issue = One developer = One task

**Reality: One issue = Multiple parallel work streams**

A single "Implement user authentication" issue isn't one task. It's...

- **Agent 1**: Database tables and migrations
- **Agent 2**: Service layer and business logic
- **Agent 3**: API endpoints and middleware
- **Agent 4**: UI components and forms
- **Agent 5**: Test suites and documentation

All running **simultaneously** on the initiative branch.

### The Math of Velocity

**Traditional Approach:**
- Epic with 3 issues
- Sequential execution

**This System:**
- Same epic with 3 issues
- Each issue splits into ~4 parallel streams
- **12 agents working simultaneously**

We're not assigning agents to issues. We're **leveraging multiple agents** to ship faster.

### Context Optimization

**Traditional single-thread approach:**
- Main conversation carries ALL the implementation details
- Context window fills with database schemas, API code, UI components
- Eventually hits context limits and loses coherence

**Parallel agent approach:**
- Main thread stays clean and strategic
- Each agent handles its own context in isolation
- Implementation details never pollute the main conversation
- Main thread maintains oversight without drowning in code

Your main conversation becomes the conductor, not the orchestra.

### The Workflow

```
# Analyze what can be parallelized
@ccpm start the memory-system epic

# Watch the magic
# 12 agents working across 3 issues
# All on: initiative/memory-system branch

# One clean merge when done
@ccpm merge the memory-system initiative
```

## Key Features & Benefits

### Context Preservation
Never lose project state again. Each epic maintains its own context, agents read from `.ccpm/context/`, and updates are tracked locally in `.ccpm/`.

### Parallel Execution
Ship faster with multiple agents working simultaneously. Tasks marked `parallel: true` enable conflict-free concurrent development.

### Agent Specialization
Right tool for every job. Different agents for UI, API, and database work. Each reads requirements and posts updates automatically.

### Full Traceability
Every decision is documented. Initiative -> Epic -> Task -> Code -> Commit. Complete audit trail from idea to production.

### Developer Productivity
Focus on building, not managing. Intelligent prioritization and automatic context loading.

## Get Started Now

### Prerequisites

- [Claude Code](https://claude.ai/code)
- `git` (required)
- `gh` CLI (optional — for GitHub integration)

### Install

1. **Clone the TCCPM repository**:

   ```bash
   git clone https://github.com/rknuus/tccpm.git /path/to/tccpm
   ```

2. **Symlink the skill into your project**:

   ```bash
   # From your project root:
   mkdir -p .claude/skills
   ln -s /path/to/tccpm/skill/ccpm .claude/skills/ccpm
   ```

   Or copy it instead of symlinking:

   ```bash
   mkdir -p .claude/skills
   cp -R /path/to/tccpm/skill/ccpm .claude/skills/ccpm
   ```

3. **Initialize TCCPM** in Claude Code:

   ```
   @ccpm init
   ```

4. **Start your first feature**:

   ```
   @ccpm create an initiative for your-feature-name
   ```

> GitHub is optional. TCCPM works in local-only mode without `gh` CLI. To enable GitHub integration, install and authenticate `gh`.

## Permissions

TCCPM uses various shell commands during its workflow. Without proper permissions, Claude Code will prompt for approval on each invocation. Configure permissions once to avoid repeated prompts.

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

### Project settings (per TCCPM project)

Add these to `.claude/settings.local.json` in your project root. These commands modify project state and are specific to TCCPM workflows:

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
| **Global** | `~/.claude/settings.json` | Read-only utilities, `mkdir`, git read-only, `basename`, `.ccpm/**` file ops |
| **Project** | `.claude/settings.local.json` | Git write ops, `make`, `sed` for frontmatter, `mv` for task renames, `gh` for GitHub, TCCPM helper scripts |
| **Prompt** | Not pre-approved | Destructive operations (`rm -rf`, `git push --force`, `git reset --hard`) |

## Tailoring-Specific Features

This tailored variant adds the following on top of [upstream CCPM v2](https://github.com/automazeio/ccpm):

| Feature | Description |
|---------|-------------|
| **Initiative terminology** | Requirements documents are called "Initiatives" (renamed from upstream) |
| **`.ccpm/` data directory** | PM data in `.ccpm/` (nested under initiatives), skill in `skill/ccpm/`, project config in `.claude/` |
| **Globally unique task IDs** | `.ccpm/next-id` counter prevents ID collisions across epics |
| **Local-only mode** | GitHub is optional — all `gh` calls are guarded |
| **Root anchoring** | All scripts `cd` to git root, ensuring consistent `.ccpm/` resolution |
| **Multi-epic initiatives** | Decompose initiatives into 1-10 epics with dependency ordering |
| **Context management** | Create, update, and load project context across sessions |
| **`@ccpm` explicit invocation** | Prefix with `@ccpm` to bypass Claude's built-in planning mode |

## License

MIT — see [LICENSE](LICENSE).

Based on [CCPM](https://github.com/automazeio/ccpm) by [Automaze](https://automaze.io).
