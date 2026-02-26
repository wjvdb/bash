#!/bin/bash
# Quick sync command: pull, commit, and push changes

synch() {
  # @desc Interactive sync for bash helper scripts (pull, commit, push)
  local SCRIPT_DIR="C:/com/bash"
  local current_dir="$(pwd)"
  
  # Wait for any background jobs to finish (like auto-pull)
  wait 2>/dev/null
  
  # Change to script directory
  cd "$SCRIPT_DIR" || {
    echo "Error: Cannot access $SCRIPT_DIR"
    return 1
  }
  
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║          Syncing Bash Helper Scripts                      ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
  
  # Pull latest changes first
  echo "📥 [1/3] Pulling latest changes from remote..."
  echo "────────────────────────────────────────────────"
  git fetch origin --quiet 2>&1 | grep -v "LF will be replaced by CRLF" || true
  
  if [[ -n $(git status --porcelain) ]]; then
    # Stash local changes if any
    echo "💾 Stashing local changes temporarily..."
    git stash push -q -m "Auto-stash during sync $(date '+%Y-%m-%d %H:%M:%S')" 2>&1 | grep -v "LF will be replaced by CRLF" || true
    STASHED=1
  fi
  
  # Pull changes - use PIPESTATUS to check git's exit code, not grep's
  git pull origin HEAD --quiet 2>&1 | grep -v "LF will be replaced by CRLF" || true
  pull_status=${PIPESTATUS[0]}
  
  if [[ $pull_status -ne 0 ]]; then
    echo "✗ Failed to pull changes"
    [[ $STASHED -eq 1 ]] && git stash pop -q 2>&1 | grep -v "LF will be replaced by CRLF" || true
    cd "$current_dir"
    return 1
  fi
  
  # Restore stashed changes
  if [[ $STASHED -eq 1 ]]; then
    echo "♻️  Restoring stashed changes..."
    git stash pop -q 2>&1 | grep -v "LF will be replaced by CRLF" || true
  fi
  
  echo "✓ Pull complete"
  
  # Check for changes to commit
  if [[ -n $(git status --porcelain) ]]; then
    echo ""
    echo "📝 [2/3] Local changes detected:"
    echo "────────────────────────────────────────────────"
    git status --short
    echo ""
    
    # Prompt for commit message
    read -p "💬 Commit message (or press Enter to skip commit): " message
    
    if [[ -n "$message" ]]; then
      echo ""
      echo "💾 Committing changes..."
      git add -A 2>&1 | grep -v "LF will be replaced by CRLF" || true
      git commit -m "$message" 2>&1 | grep -v "LF will be replaced by CRLF" | grep -E "(^\[|files? changed|insertions?|deletions?)" || true
      
      # Push changes
      echo ""
      echo "📤 [3/3] Pushing changes to remote..."
      echo "────────────────────────────────────────────────"
      
      # Push and capture status properly
      git push origin HEAD 2>&1 | grep -v "LF will be replaced by CRLF" | grep -E "(To |->|Everything up-to-date)" || true
      push_status=${PIPESTATUS[0]}
      
      if [[ $push_status -eq 0 ]]; then
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║                  ✓ Sync Complete! 🎉                      ║"
        echo "╚════════════════════════════════════════════════════════════╝"
      else
        echo "✗ Failed to push changes"
        cd "$current_dir"
        return 1
      fi
    else
      echo "⏭️  Skipped commit"
    fi
  else
    echo ""
    echo "✓ Already up to date, no changes to commit"
  fi
  
  # Return to original directory
  cd "$current_dir"
  
  # Reload bashrc
  echo ""
  read -p "🔃 Reload shell configuration? (y/n): " reload
  if [[ "$reload" =~ ^[Yy]$ ]]; then
    source ~/.bashrc
    echo "✓ Shell configuration reloaded"
  fi
}

# Aliases for quick access
alias sync='synch'
