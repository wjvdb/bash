#!/bin/bash
# Auto-pull latest changes when opening a new terminal
# Add this to your ~/.bashrc: source /path/to/.git-auto-pull.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to auto-pull in the background
_auto_pull_bash_helpers() {
  (
    cd "$SCRIPT_DIR" 2>/dev/null || return
    
    # Show heads-up that we're checking for updates
    echo "🔄 Checking for bash helper updates..."
    
    # Fetch silently
    git fetch origin --quiet 2>/dev/null || {
      echo "⚠️  Could not check for updates (no network connection?)"
      return
    }
    
    # Check if we're behind
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u} 2>/dev/null) || {
      echo "✓ No remote tracking branch configured"
      return
    }
    
    if [ "$LOCAL" != "$REMOTE" ]; then
      echo ""
      echo "📥 Updates found! Syncing bash helper scripts..."
      echo "────────────────────────────────────────────────"
      
      # Check for local changes
      if [[ -n $(git status --porcelain) ]]; then
        echo "💾 Stashing local changes..."
        git stash push -q -m "Auto-stash before pull $(date '+%Y-%m-%d %H:%M:%S')"
        STASHED=1
      fi
      
      # Pull changes
      if git pull origin HEAD --quiet; then
        echo "✓ Successfully updated bash helpers"
        
        # Restore stashed changes if any
        if [[ $STASHED -eq 1 ]]; then
          echo "♻️  Restoring local changes..."
          git stash pop -q
        fi
        
        # Show what changed
        echo ""
        echo "Recent changes:"
        git log --oneline -3
        echo "────────────────────────────────────────────────"
        
        # Reload bash configuration
        echo "🔃 Reloading shell configuration..."
        source ~/.bashrc
        echo "✓ Shell reloaded with latest changes"
        echo ""
      else
        echo "✗ Failed to pull changes"
        if [[ $STASHED -eq 1 ]]; then
          echo "♻️  Restoring stashed changes..."
          git stash pop -q
        fi
      fi
    else
      echo "✓ Bash helpers are up to date"
    fi
  ) &
}

# Run auto-pull on shell startup (only if interactive shell)
if [[ $- == *i* ]]; then
  _auto_pull_bash_helpers
fi
