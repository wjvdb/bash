#!/bin/bash
# Quick Setup Script for Auto-Sync

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Bash Helper Functions - Auto-Sync Setup                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="${HOME}/.bashrc"

# Step 1: Install git hooks
echo "Step 1: Installing git hooks..."
if bash "$SCRIPT_DIR/.git-hooks-install.sh"; then
  echo "✓ Git hooks installed"
else
  echo "✗ Failed to install git hooks"
  exit 1
fi

echo ""

# Step 2: Add auto-pull to bashrc
echo "Step 2: Setting up auto-pull on terminal startup..."

# Check if already added
if grep -q ".git-auto-pull.sh" "$BASHRC" 2>/dev/null; then
  echo "⚠ Auto-pull already configured in ~/.bashrc"
else
  echo "" >> "$BASHRC"
  echo "# Auto-pull bash helper updates (added by quick-setup.sh)" >> "$BASHRC"
  echo "source \"$SCRIPT_DIR/.git-auto-pull.sh\"" >> "$BASHRC"
  echo "✓ Added auto-pull to ~/.bashrc"
fi

echo ""

# Step 3: Source sync.sh if not already done
echo "Step 3: Adding sync command..."

if grep -q "sync.sh" "$BASHRC" 2>/dev/null; then
  echo "⚠ sync.sh already sourced in ~/.bashrc"
else
  echo "source \"$SCRIPT_DIR/sync.sh\"" >> "$BASHRC"
  echo "✓ Added sync command"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Setup Complete! 🎉                                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "What's been configured:"
echo "  ✓ Auto-push after git commits (via post-commit hook)"
echo "  ✓ Auto-pull when opening new terminals"
echo "  ✓ Manual 'sync' command available"
echo ""
echo "To activate changes, run:"
echo "  source ~/.bashrc"
echo ""
echo "Or simply open a new terminal window."
echo ""
echo "Quick commands:"
echo "  sync       - Manual sync (pull, commit, push)"
echo "  synch      - Same as sync"
echo "  refrsh     - Reload shell configuration"
echo ""
