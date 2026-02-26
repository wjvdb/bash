#!/bin/bash
# Quick sync command: pull, commit, and push changes

sync() {
  # @desc Interactive sync for bash helper scripts (pull, commit, push)
  local SCRIPT_DIR="C:/com/bash"
  local current_dir="$(pwd)"
  
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
  git fetch origin
  
  if [[ -n $(git status --porcelain) ]]; then
    # Stash local changes if any
    echo "💾 Stashing local changes temporarily..."
    git stash push -q -m "Auto-stash during sync $(date '+%Y-%m-%d %H:%M:%S')"
    STASHED=1
  fi
  
  git pull origin HEAD || {
    echo "✗ Failed to pull changes"
    [[ $STASHED -eq 1 ]] && git stash pop -q
    cd "$current_dir"
    return 1
  }
  
  # Restore stashed changes
  if [[ $STASHED -eq 1 ]]; then
    echo "♻️  Restoring stashed changes..."
    git stash pop -q
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
      git add -A
      git commit -m "$message"
      
      # Push changes
      echo ""
      echo "📤 [3/3] Pushing changes to remote..."
      echo "────────────────────────────────────────────────"
      if git push origin HEAD; then
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

# Alias for quick access
alias synch='sync'
