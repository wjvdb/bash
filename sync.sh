#!/bin/bash
# Quick sync command: pull, commit, and push changes

sync() {
  local SCRIPT_DIR="C:/com/bash"
  local current_dir="$(pwd)"
  
  # Change to script directory
  cd "$SCRIPT_DIR" || {
    echo "Error: Cannot access $SCRIPT_DIR"
    return 1
  }
  
  echo "=== Syncing bash helper scripts ==="
  echo ""
  
  # Pull latest changes first
  echo "[1/3] Pulling latest changes..."
  git fetch origin
  
  if [[ -n $(git status --porcelain) ]]; then
    # Stash local changes if any
    git stash push -q -m "Auto-stash during sync $(date '+%Y-%m-%d %H:%M:%S')"
    STASHED=1
  fi
  
  git pull origin HEAD || {
    echo "Error: Failed to pull changes"
    [[ $STASHED -eq 1 ]] && git stash pop -q
    cd "$current_dir"
    return 1
  }
  
  # Restore stashed changes
  if [[ $STASHED -eq 1 ]]; then
    git stash pop -q
  fi
  
  # Check for changes to commit
  if [[ -n $(git status --porcelain) ]]; then
    echo ""
    echo "[2/3] Local changes detected:"
    git status --short
    echo ""
    
    # Prompt for commit message
    read -p "Commit message (or press Enter to skip commit): " message
    
    if [[ -n "$message" ]]; then
      git add -A
      git commit -m "$message"
      
      # Push changes
      echo ""
      echo "[3/3] Pushing changes to remote..."
      git push origin HEAD && {
        echo ""
        echo "✓ Sync complete!"
      } || {
        echo "Error: Failed to push changes"
        cd "$current_dir"
        return 1
      }
    else
      echo "Skipped commit"
    fi
  else
    echo ""
    echo "✓ Already up to date, no changes to commit"
  fi
  
  # Return to original directory
  cd "$current_dir"
  
  # Reload bashrc
  read -p "Reload shell configuration? (y/n): " reload
  if [[ "$reload" =~ ^[Yy]$ ]]; then
    source ~/.bashrc
    echo "✓ Shell configuration reloaded"
  fi
}

# Alias for quick access
alias synch='sync'
