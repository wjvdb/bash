#!/bin/bash
# Install git hooks for automatic push on file changes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$SCRIPT_DIR/.git/hooks"

# Create post-commit hook
cat > "$HOOKS_DIR/post-commit" << 'EOF'
#!/bin/bash
# Automatically push after each commit

echo "Auto-pushing to remote..."
git push origin HEAD || {
  echo "Warning: Auto-push failed. You may need to push manually."
}
EOF

chmod +x "$HOOKS_DIR/post-commit"
echo "✓ Installed post-commit hook (auto-push after commits)"

# Create post-merge hook
cat > "$HOOKS_DIR/post-merge" << 'EOF'
#!/bin/bash
# Reload bashrc after pulling changes

echo "Changes pulled. Consider running: source ~/.bashrc"
EOF

chmod +x "$HOOKS_DIR/post-merge"
echo "✓ Installed post-merge hook (reminder to reload shell)"

echo ""
echo "Git hooks installed successfully!"
echo ""
echo "Automatic behaviors:"
echo "  • After commits: automatically push to remote"
echo "  • After pulls: reminder to reload your shell"
echo ""
echo "To enable auto-pull on terminal startup, add this to your ~/.bashrc:"
echo "  source \"$SCRIPT_DIR/.git-auto-pull.sh\""
