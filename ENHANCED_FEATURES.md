# Enhanced Features Documentation

## 🎯 New Features

### 1. Auto-Sync in `exc` Command

The `exc` (edit config) function now includes automatic git sync!

#### How It Works:

1. **Select file to edit** - Choose from your sourced bash files
2. **Edit in VSCode** - Opens with `--wait` flag (waits for you to close the file)
3. **Detects changes** - Uses SHA256 hash to detect if file was modified
4. **Shows diff** - Displays what changed
5. **Prompts for commit** - Asks if you want to commit and push
6. **Auto-reload** - Optionally reloads your shell configuration

#### Usage Example:

```bash
$ exc
Sourced files:
1: command.sh
2: git_commands.sh
3: help.sh
4: project.sh
5: sync.sh
6: todo.sh
7: web.sh

Enter the number of the file to edit: 2
Opening git_commands.sh in VSCode (waiting for editor to close)...

# ... make changes in VSCode, save, and close ...

✓ Changes detected in git_commands.sh

Commit and push changes? (Y/n): y

Changes made:
@@ -22,7 +22,7 @@ function gach() {
-  # Add only changed files
+  # @desc Add changed files and commit
... (15 more lines)

Commit message (or press Enter for default): Update gach function description

✓ Committed: Update gach function description
Pushing to remote...
✓ Successfully pushed to remote

Reload shell configuration? (Y/n): y
✓ Shell configuration reloaded
```

#### Benefits:

- ✅ Never forget to commit changes
- ✅ Automatic push to keep remote in sync
- ✅ See exactly what changed before committing
- ✅ Instant shell reload after changes
- ✅ Defaults to "Yes" for quick workflows (just press Enter)

---

### 2. Enhanced `hjelp` Function

The `hjelp` function now **automatically extracts descriptions** from function comments!

#### New Comment Format:

Use the `@desc` tag for clear documentation:

```bash
function myfunction() {
  # @desc This is what my function does
  ...
}
```

Alternative format (first line comment):

```bash
function myfunction() {
  # This is what my function does
  ...
}
```

#### New Features:

**Search functionality:**
```bash
hjelp -s git        # Search for functions/aliases containing "git"
hjelp -s search     # Search for anything related to "search"
```

**Verbose mode:**
```bash
hjelp -v           # Show file locations for each function
```

**Help:**
```bash
hjelp -h           # Show usage instructions
```

#### Output Format:

```
╔════════════════════════════════════════════════════════════╗
║                         ALIASES                            ║
╚════════════════════════════════════════════════════════════╝

  gp                   → git push origin HEAD
  gc                   → git commit
  gs                   → git status
  ...

╔════════════════════════════════════════════════════════════╗
║                        FUNCTIONS                           ║
╚════════════════════════════════════════════════════════════╝

  exc                  Edit sourced bash helper files with auto-sync to git
  gach                 Add changed files and commit (usage: gach "message")
  gnb                  Create and push a new branch (usage: gnb branch-name)
  hjelp                Display all aliases and functions with their descriptions
  pp                   Navigate up N directories (usage: pp 3 to go up 3 levels)
  proj                 Manage saved project folders (usage: proj to list)
  ss                   Search for text in files recursively
  todo                 Interactive TODO list manager
  unfuck               Reset current branch to match remote
  web                  Manage saved websites
  ...

──────────────────────────────────────────────────────────────
Total: 15 aliases, 42 functions
```

#### Benefits:

- ✅ No more manual description management
- ✅ Descriptions live with the code
- ✅ Search functionality to find what you need
- ✅ Beautiful, organized output
- ✅ Shows file locations in verbose mode
- ✅ Removed the old `setdescription` function (no longer needed!)

---

## 🔄 Migration Guide

### For Existing Functions:

Update your functions to use the `@desc` format:

**Before:**
```bash
function myfunction() {
  # Does something cool
  ...
}
```

**After:**
```bash
function myfunction() {
  # @desc Does something cool
  ...
}
```

Or keep the old format - it still works! The `@desc` tag just makes it more explicit.

### Old `setdescription` Function:

The `setdescription` function has been **removed**. Descriptions are now embedded directly in the code using comments.

If you had descriptions in `~/.function_descriptions`, you should:
1. Find each function
2. Add the description as a `# @desc` comment
3. Delete the old `~/.function_descriptions` file

---

## 📝 Best Practices

### Writing Good Descriptions:

**Good:**
```bash
# @desc Search for text in files recursively (usage: ss "term" [folder])
```

**Better:**
```bash
# @desc Interactive git stash manager with branch tracking
```

**Not ideal:**
```bash
# @desc Does stuff
```

### Guidelines:

1. **Be specific** - Say what the function actually does
2. **Include usage** - Show a quick example if helpful
3. **Keep it short** - One line is ideal (under 80 chars)
4. **Use consistent style** - Either all `@desc` or all plain comments

---

## 🎨 Customization

### Change Default Behavior in `exc`:

Edit `command.sh` and modify the prompts:

```bash
# Change default from "Yes" to "No":
read -p "Commit and push changes? (y/N): " should_commit
should_commit=${should_commit:-N}  # Default to No
```

### Customize `hjelp` Output:

Edit `help.sh` to change the box drawing characters, colors, or format.

---

## 🚀 Quick Reference

### exc Command:
```bash
exc                    # Edit sourced files with auto-sync
```

### hjelp Command:
```bash
hjelp                  # Show all aliases and functions
hjelp -s term          # Search for specific term
hjelp -v               # Verbose mode with file locations
hjelp -h               # Show help
```

### Comment Format:
```bash
function name() {
  # @desc Description here
  ...
}
```

---

## 🐛 Troubleshooting

### VSCode doesn't wait for me to close the file:

The `exc` function tries to use `code --wait`. If this doesn't work:

1. Make sure VSCode is in your PATH
2. Try running: `code --version` to test
3. If `--wait` isn't supported, the function will prompt you to press Enter when done

### hjelp doesn't find my function description:

Make sure:
1. The comment is on the line right after `function name() {`
2. The comment starts with `#` (with optional whitespace)
3. The function is defined in one of your sourced files

### Changes aren't being detected:

The `exc` function uses SHA256 checksums. Make sure either `sha256sum` or `shasum` is installed:

```bash
which sha256sum || which shasum
```

---

## 📚 Examples

### Complete Function with @desc:

```bash
function deploy() {
  # @desc Deploy application to production with safety checks
  
  if [[ $(git symbolic-ref --short HEAD) != "main" ]]; then
    echo "Error: Must be on main branch to deploy"
    return 1
  fi
  
  echo "Deploying to production..."
  # ... deployment logic ...
}
```

### Using hjelp to Find Functions:

```bash
$ hjelp -s deploy
╔════════════════════════════════════════════════════════════╗
║                        FUNCTIONS                           ║
╚════════════════════════════════════════════════════════════╝

  deploy               Deploy application to production with safety checks

──────────────────────────────────────────────────────────────
Total: 0 aliases, 1 functions
Filtered by: 'deploy'
```

### Typical exc Workflow:

```bash
$ exc                          # Start editing
> 2                            # Select git_commands.sh
# Edit in VSCode, save, close
> y                            # Commit? Yes
> Add new gbranch function     # Commit message
# Auto-pushed!
> y                            # Reload shell? Yes
$ gbranch                      # New function immediately available!
```

---

## 🎉 Summary

You now have:
- ✅ Automatic git sync when editing bash functions
- ✅ Self-documenting functions with `@desc` comments
- ✅ Powerful search with `hjelp -s`
- ✅ Clean, organized help output
- ✅ No more manual description management

Happy scripting! 🚀
