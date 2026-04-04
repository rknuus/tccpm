#!/bin/bash
# ccpm-git-commit.sh — Stage files and commit with a message from a file.
#
# Usage: bash skill/ccpm/references/scripts/ccpm-git-commit.sh [-C <dir>] <message-file> [files...]
#
# If -C <dir> is given, changes to that directory first (useful for worktrees).
# If files are specified, only those are staged. If omitted, stages all changes.
# The commit message is read from <message-file>.
#
# This avoids the $(cat <<'EOF'...) heredoc pattern that triggers extra
# Claude Code approval prompts.

set -euo pipefail

# Parse optional -C <dir> flag
if [ "${1:-}" = "-C" ]; then
  if [ $# -lt 2 ]; then
    echo "Error: -C requires a directory argument" >&2
    exit 1
  fi
  WORK_DIR="$2"
  shift 2
  if [ ! -d "$WORK_DIR" ]; then
    echo "Error: Directory not found: $WORK_DIR" >&2
    exit 1
  fi
  cd "$WORK_DIR"
fi

if [ $# -lt 1 ]; then
  echo "Usage: ccpm-git-commit.sh [-C <dir>] <message-file> [files...]" >&2
  exit 1
fi

MSG_FILE="$1"
shift

if [ ! -f "$MSG_FILE" ]; then
  echo "Error: Message file not found: $MSG_FILE" >&2
  exit 1
fi

if [ $# -gt 0 ]; then
  git add "$@"
else
  git add -A
fi

git commit -F "$MSG_FILE"
