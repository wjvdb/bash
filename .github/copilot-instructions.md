# Bash Utilities Copilot Instructions

## Project Overview
This is a collection of bash shell utilities and aliases designed to accelerate common development workflows, particularly Git operations, file navigation, and system administration tasks. The project provides both lightweight aliases and more complex utility functions.

## Architecture & Key Components

### Core Files
- **`command.sh`** - Main utility library containing all aliases and functions (~424 lines)
- **`work.sh`** - Initialization script that injects utilities into the user's `.bashrc`

### Key Utility Categories

#### Git Aliases & Functions
- **Shorthand Aliases**: `gs` (status), `ga`/`gaa` (add), `gc`/`gcm` (commit), `gp` (push), `gca`/`gac` (add+commit combined)
- **Complex Functions**: `gnb()` (create & push new branch), `unfuck()` (hard reset to origin), `derkje` (fancy git log)
- Git operations assume origin/HEAD workflow

#### Navigation & File Utilities
- **`pp [n]`** - Navigate up n directories (default 1)
- **`edir <path>`** - Create directory and immediately cd into it
- **`sfs <term> [path]`** - Search files/directories by name pattern
- **`sfsv <term> [path]`** - Search files and open single match in vim
- **`replace_in_files <old> <new> [ext]`** - Batch string replacement by file extension
- **`ss <word> [folder]`** - Case-insensitive recursive grep search

#### Environment
- **`portal`** - Jump to home directory (`cd ~`)
- **`devportal`** - Jump to development directory (`/c/dev/`)
- **`refrsh`** - Reload bashrc
- **`esc`/`exc`** - Edit bashrc in vim

## Developer Workflows

### Setup & Injection
Run `work.sh` to automatically inject utilities into `~/.bashrc`:
```bash
source work.sh
```
The script adds a `source` line to `.bashrc` if not already present, enabling utilities in new shell sessions.

### Common Patterns
- **Quick branch creation**: `gnb feature-name` creates and pushes in one command
- **Batch file edits**: `replace_in_files old_pattern new_pattern js` for JavaScript files
- **Finding code**: `sfs filename` then `sfsv filename` to jump to file
- **Navigation**: Use `pp 2` instead of `cd ../../`

## Project Conventions

### File Extension Support
The `replace_in_files` function accepts wildcards: use `replace_in_files old new "tsx|ts"` for multiple extensions (note: uses `sed -i ''` for BSD/macOS compatibility).

### Search Behavior
- `ss` and `sfs` use recursive search; suppress errors with `2>/dev/null`
- Searches default to current directory (`.`) if no path provided
- Case sensitivity differs: `ss` ignores case (`-i`), `sfs` is case-sensitive

### Error Handling
Functions validate required arguments and return exit code 1 on missing parameters (see `gnb()`, `replace_in_files()`, `ss()`).

## Integration Points

### External Dependencies
- Requires `bash` 4.0+ (uses `${#array[@]}` syntax)
- Assumes `git` is installed and configured
- Requires standard GNU/BSD utilities: `sed`, `grep`, `find`, `awk`
- `sjow` alias calls `explorer.exe` (Windows-specific; bash on Windows/Git Bash context)

### Platform Considerations
- Uses macOS-compatible `sed -i ''` syntax (not GNU `sed -i` without filename arg)
- `portal` alias hardcoded to `~` (platform-agnostic)
- `sjow` assumes Windows with Git Bash

## When Modifying This Codebase

**Priority focuses for AI agents:**
1. Maintain consistent function validation patterns (check `$#` for required args)
2. Use relative paths and `$PWD` defaults where possible
3. Test string replacement logic with both GNU and BSD `sed` variants
4. Preserve existing alias names—they're documented in `hjelp()` output
5. New utilities should follow the pattern: parameter validation → implementation → error handling

**Caution areas:**
- Don't remove `inject()` from `work.sh`—it's the bootstrap mechanism
- Git operations assume tracking branch setup; `unfuck()` requires valid remote
- File operations using `find` may produce large result sets; consider adding limits for performance
