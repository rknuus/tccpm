# Plan — Capture Requirements

This phase turns an idea into a structured Initiative, then converts the Initiative into a technical epic ready for decomposition.

---

## Writing an Initiative

**Trigger**: User wants to plan a new feature, product requirement, or area of work.

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Check if `.ccpm/initiatives/<name>/<name>.md` already exists — if so, confirm overwrite before proceeding.
- Ensure `.ccpm/initiatives/<name>/` directory exists; create it if not.
- Feature name must be kebab-case (lowercase, letters/numbers/hyphens, starts with a letter). If not: "❌ Feature name must be kebab-case. Example: user-auth, payment-v2"

### Process

Conduct a genuine brainstorming session before writing anything. Ask the user:
- What problem does this solve?
- Who are the users affected?
- What does success look like?
- What's explicitly out of scope?
- What are the constraints (tech, time, resources)?

Probe for domain concepts and their correctness properties:
- **Identifiers**: Key entities, uniqueness scope, reuse rules
- **State**: Valid states, allowed transitions, source of truth
- **Ordering**: Ordered collections, invariants after mutations
- **Consistency**: Multiple representations, disagreement handling
- **Concurrency**: Concurrent modifications, conflict resolution
- **Idempotency**: Which operations must be safe to retry

Then write `.ccpm/initiatives/<name>/<name>.md` with this frontmatter and structure:

```markdown
---
name: <feature-name>
description: <one-line summary>
status: backlog
created: <run: date -u +"%Y-%m-%dT%H:%M:%SZ">
---

# Initiative: <feature-name>

## Executive Summary
## Problem Statement
## User Stories
## Functional Requirements
## Non-Functional Requirements
## Success Criteria
## Constraints & Assumptions
## Out of Scope
## Dependencies
```

**Quality gates before saving:**
- No placeholder text in any section
- User stories include acceptance criteria
- Success criteria are measurable
- Out of scope is explicitly listed

**After creation**: Confirm "✅ Initiative created" and list the file as a bare relative path on its own line (no backticks or formatting — terminals make bare paths Cmd+Clickable):

```
✅ Initiative created

.ccpm/initiatives/<name>/<name>.md
```

**Recommend next step**: Assess the initiative you just wrote and recommend one of three paths. Use these proxy measures:
- **User story count**: how many distinct user stories
- **Functional requirement count**: how many requirements
- **Scope boundary complexity**: how large/detailed is "Out of Scope"
- **Cross-subsystem spread**: does the work span multiple distinct technical areas
- **External dependencies**: how many external systems or teams involved
- **Deliverable count**: do success criteria imply one deliverable or several distinct ones

Based on the assessment, recommend one tier:

| Tier | When to recommend | Command |
|------|-------------------|---------|
| **initiative-go** | Very small, super-clear scope. 1-2 user stories, single deliverable, no cross-subsystem complexity. May produce as few as 1 task. | `@ccpm initiative-go <name>` |
| **Single-epic parse** | Medium scope. Cohesive single deliverable but needs task-level planning and review. 3-5 user stories, moderate complexity. | `parse the <name> initiative` |
| **Multi-epic decompose** | Large scope. Multiple distinct deliverables or subsystems, many user stories, complex dependencies between areas. | `decompose the <name> initiative into epics` |

Present the recommendation concisely — one line of assessment, then the options:

```
**Recommendation**: <one-line assessment, e.g., "Small, focused initiative — single deliverable with clear scope">

  ➤ @ccpm initiative-go <name>                       ← recommended
    parse the <name> initiative
    decompose the <name> initiative into epics
    let's revise the <name> initiative
```

Always list all four options (the three tiers plus "revise"). Mark the recommended one with "← recommended". The user decides which to use.

---

## Parsing an Initiative into a Technical Epic

**Trigger**: User wants to convert an existing Initiative into a technical implementation plan.

### Preflight
- **Root check**: Run `git rev-parse --show-toplevel` and confirm the working directory is the project root. If not, `cd` to the root before proceeding.
- Verify `.ccpm/initiatives/<name>/<name>.md` exists with valid frontmatter (name, description, status, created).
- Check if `.ccpm/initiatives/<name>/<epic-name>/epic.md` already exists — confirm overwrite if so.

### Process

Read the Initiative fully, then produce `.ccpm/initiatives/<name>/<epic-name>/epic.md`:

```markdown
---
name: <feature-name>
status: backlog
created: <run: date -u +"%Y-%m-%dT%H:%M:%SZ">
progress: 0%
initiative: .ccpm/initiatives/<name>/<name>.md
github: (will be set on sync)
---

# Epic: <feature-name>

## Overview
## Architecture Decisions
## Technical Approach
### Frontend Components
### Backend Services
### Infrastructure
## Implementation Strategy
## Task Breakdown Preview
## Dependencies
## Success Criteria (Technical)
## Estimated Effort
```

**Key constraints:**
- Aim for ≤10 tasks total — prefer simplicity over completeness.
- Look for ways to leverage existing functionality before creating new code.
- Identify parallelization opportunities in the task breakdown preview.

**After creation**: Confirm "✅ Epic created" and list the file as a bare relative path on its own line:

```
✅ Epic created

.ccpm/initiatives/<name>/<epic-name>/epic.md

Ready to decompose into tasks? Say: decompose the <epic-name> epic
```

**Next steps to suggest:**
- "Decompose into tasks: decompose the <epic-name> epic"
- "Review or revise: let's refine the <epic-name> epic"

---

## Editing an Initiative or Epic

Read the file first, make targeted edits preserving all frontmatter. Update the `updated` frontmatter field with current datetime.
