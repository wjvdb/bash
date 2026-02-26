#!/bin/bash
# Auto-push modified files when they change
# This script should be run in the background or as a git hook

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Check if there are any changes
if [[ -n $(git status --porcelain) ]]; then
  echo "[Auto-Push] Changes detected in bash helper scripts"
  
  # Add all changes
  git add -A
  
  # Create commit with timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  git commit -m "Auto-update: $timestamp" || {
    echo "[Auto-Push] Nothing to commit"
    exit 0
  }
  
  # Push to remote
  git push origin HEAD && {
    echo "[Auto-Push] Successfully pushed changes"
  } || {
    echo "[Auto-Push] Failed to push changes"
    exit 1
  }
else
  echo "[Auto-Push] No changes to push"
fi
