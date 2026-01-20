alias gp='git push origin HEAD'
alias gc='git commit' 
alias gcm='git commit -m'
alias gca='git add . && git commit -a -m'
alias gac='git add . && git commit -a'
alias gaa='git add .' 
alias gau='git add --all' 
alias ga='git add .' 
alias derkje='git log --graph --decorate --pretty=oneline --abbrev-commit'
alias gs='git status' 
alias glfa='git log --graph --decorate --pretty=oneline --abbrev-commit -- --'

function unfuck() {
  # Reset the current branch to match the remote and optionally delete untracked files
  git fetch origin
  current_branch=$(git symbolic-ref --short HEAD)
  git reset --hard origin/$current_branch

  read -p "Delete untracked files? (y/n): " delete_untracked
  if [[ "$delete_untracked" =~ ^[Yy]$ ]]; then
    git clean -fd
    echo "Untracked files deleted."
  fi
}

function gnb() {
  # Create and push a new branch to origin
  if [ -z "$1" ]; then
    echo "Usage: newbranch <branch-name>"
    return 1
  fi

  git checkout -b "$1" && git push -u origin "$1"
}



# git log (graph, decorate, oneline, abbrev-commit) for a single path
glf() {
  # Usage:
  #   glf path/to/file.ext               # basic history for that path
  #   glf -f path/to/file.ext            # follow across renames
  #   glf -p path/to/file.ext            # include diffs for that path
  #   glf --since="2024-01-01" file.ext  # pass-through extra git log options
  #
  # Flags:
  #   -f | --follow   Follow renames (only one path allowed with --follow)
  #   -p              Include diffs (patches) for that path
  #   -h | --help     Show help

  local follow=0
  local patch=0
  local args=()
  local path=""

  # Parse our simple flags; leave other args to pass through to `git log`
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--follow) follow=1; shift ;;
      -p)          patch=1; shift ;;
      -h|--help)
        cat <<'EOF'
glf - git log (graph, decorate, oneline, abbrev-commit) for a single file/dir

Usage:
  glf [options] <path>
  glf -f path/to/file.ext           # follow renames
  glf -p path/to/file.ext           # include diffs
  glf --since="2024-01-01" <path>   # pass git log filters

Options:
  -f, --follow   Follow renames (only one path is allowed)
  -p             Show patch/diffs for the specified path
  -h, --help     Show this help
EOF
        return 0
        ;;
      --) # explicit end of options; next token is the path
        shift
        if [[ $# -gt 0 ]]; then path="$1"; shift; fi
        break
        ;;
      -*)
        # Any other option goes to `git log`
        args+=("$1")
        shift
        ;;
      *)
        # First non-option is the path
        path="$1"
        shift
        ;;
    esac
  done

  if [[ -z "$path" ]]; then
    echo "glf: missing <path>. Try: glf -h"
    return 1
  fi

  # Base format
  local base=(git log --graph --decorate --pretty=oneline --abbrev-commit)

  # Optional parts
  if [[ $patch -eq 1 ]]; then
    base+=(-p)
  fi
  if [[ $follow -eq 1 ]]; then
    base+=(--follow)
  fi

  # Execute (use -- to mark pathspec)
  "${base[@]}" "${args[@]}" -- -- "$path"
}



## Search commit messages and descriptions for a term# Usage: gsc "<search-term>"
# Example: gsc "fix bug"
gsc() {
    if [ -z "$1" ]; then
        echo "Usage: gsc <search-term>"
        return 1
    fi

    local term="$1"

    # Search commit messages AND descriptions
    git log --all -E --grep="$term" --pretty=format:"%C(yellow)%h%Creset %Cgreen%ad%Creset %s" --date=short
}


# Show file history with diffs for last N commits
gfh() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo 'Usage: gfh "<filename>" <number-of-commits>'
        return 1
    fi

    local file="$1"
    local count="$2"

    # Get commits that touched this file
    commits=$(git log -n "$count" --pretty=format:"%H" -- "$file")

    if [ -z "$commits" ]; then
        echo "No commits found for file: $file"
        return 1
    fi

    for c in $commits; do
        echo -e "\n=============================="
        echo "Commit: $c"
        echo "------------------------------"
        git show "$c" -- "$file"
    done
}
