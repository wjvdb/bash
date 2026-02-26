#!/bin/bash
# Auto-pull latest changes when opening a new terminal
# Add this to your ~/.bashrc: source /path/to/.git-auto-pull.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to auto-pull in the background
_auto_pull_bash_helpers() {
  (
    cd "$SCRIPT_DIR" 2>/dev/null || return
    
    # Fetch silently
    git fetch origin --quiet 2>/dev/null || return
    
    # Check if we're behind
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u} 2>/dev/null) || return
    
    if [ "$LOCAL" != "$REMOTE" ]; then
      echo "[Auto-Pull] Updating bash helper scripts..."
      
      # Check for local changes
      if [[ -n $(git status --porcelain) ]]; then
        echo "[Auto-Pull] Local changes detected, stashing..."
        git stash push -q -m "Auto-stash before pull $(date '+%Y-%m-%d %H:%M:%S')"
        STASHED=1
      fi
      
      # Pull changes
      git pull origin HEAD --quiet && {
        echo "[Auto-Pull] Successfully updated bash helpers"
        
        # Restore stashed changes if any
        if [[ $STASHED -eq 1 ]]; then
          echo "[Auto-Pull] Restoring local changes..."
          git stash pop -q
        fi
        
        # Reload bash configuration
        echo "[Auto-Pull] Reloading shell configuration..."
        source ~/.bashrc
      } || {
        echo "[Auto-Pull] Failed to pull changes"
      }
    fi
  ) &
}

# Run auto-pull on shell startup (only if interactive shell)
if [[ $- == *i* ]]; then
  _auto_pull_bash_helpers
fi
