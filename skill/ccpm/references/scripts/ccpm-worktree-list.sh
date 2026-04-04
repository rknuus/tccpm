#!/bin/bash
# ccpm-worktree-list.sh — List active git worktree directories.
#
# Outputs worktree directory paths (one per line), excluding the main
# working tree. Useful as a staging guard to detect whether worktrees
# exist before destructive operations.
#
# Usage:
#   bash ccpm-worktree-list.sh
#
# Examples:
#   bash ccpm-worktree-list.sh
#   bash ccpm-worktree-list.sh | grep -q "../epic-foo"

set -euo pipefail

main_worktree="$(git rev-parse --show-toplevel 2>/dev/null)"

# git worktree list --porcelain outputs blocks separated by blank lines.
# Each block starts with "worktree <path>". We extract the path from each
# block and skip the main working tree.
git worktree list --porcelain 2>/dev/null | while IFS= read -r line; do
  case "$line" in
    worktree\ *)
      wt="${line#worktree }"
      if [ "$wt" != "$main_worktree" ]; then
        printf '%s\n' "$wt"
      fi
      ;;
  esac
done

exit 0
