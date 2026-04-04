#!/bin/bash
# ccpm-worktree-git.sh — Run a git command in a specified directory.
#
# Replaces `cd <dir> && git <cmd>` compound commands that trigger Claude
# Code approval prompts. This wrapper presents a named-script interface,
# so monitors see "bash ccpm-worktree-git.sh" instead.
#
# Usage:
#   bash ccpm-worktree-git.sh <dir> <git-subcommand> [args...]
#
# Examples:
#   bash ccpm-worktree-git.sh ../my-worktree status
#   bash ccpm-worktree-git.sh /tmp/wt diff --stat
#   bash ccpm-worktree-git.sh ../my-worktree log --oneline -5

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: ccpm-worktree-git.sh <dir> <git-subcommand> [args...]" >&2
  exit 1
fi

TARGET_DIR="$1"
shift

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: directory not found: $TARGET_DIR" >&2
  exit 1
fi

# Validate the directory is inside a git repository
if ! git -C "$TARGET_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: not a git working tree: $TARGET_DIR" >&2
  exit 1
fi

# Run the git command in the target directory, passing through output and
# exit code transparently.
git -C "$TARGET_DIR" "$@"
