alias gp='git push origin HEAD'
alias gpf='git push origin HEAD --force-with-lease'
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
alias givehead='gp'
alias forcehead='gpf'


function gach() {
  # @desc Add changed files and commit (usage: gach "message" or just gach for editor)
  if [ -z "$1" ]; then
    # No message provided - stage modified files and commit in editor
    git add -u && git commit
  else
    # Message provided - stage modified files and commit with message
    git add -u && git commit -m "$1"
  fi
}


function unfuck() {
  # @desc Reset current branch to match remote and optionally delete untracked files
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
  # @desc Create and push a new branch (usage: gnb branch-name)
  if [ -z "$1" ]; then
    echo "Usage: newbranch <branch-name>"
    return 1
  fi

  git checkout -b "$1" && git push -u origin "$1"
}



glf() {
  # @desc Git log for a specific file with options (use -h for help)
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



gsc() {
  # @desc Search commit messages for a term (usage: gsc "search term")
  if [ -z "$1" ]; then
      echo "Usage: gsc <search-term>"
      return 1
  fi

  local term="$1"

  # Search commit messages AND descriptions
  git log --all -E --grep="$term" --pretty=format:"%C(yellow)%h%Creset %Cgreen%ad%Creset %s" --date=short
}


gfh() {
  # @desc Show file history with diffs for last N commits (usage: gfh "file.txt" 5)
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


# Add files/folders to .gitignore easily
# Usage:
#   gignore <file-or-folder>           # Add a specific file or folder
#   gignore -f <folder>                # Add all files in a folder
#   gignore -u                         # Add all unstaged changes
#   gignore -m                         # Add all modified files (staged or not)
gignore() {
    local gitignore=".gitignore"
    
    # Create .gitignore if it doesn't exist
    if [ ! -f "$gitignore" ]; then
        touch "$gitignore"
        echo "Created .gitignore file"
    fi
    
    case "$1" in
        -h|--help)
            cat <<'EOF'
gignore - Add files/folders to .gitignore easily

Usage:
  gignore <path>              Add a specific file or folder
  gignore -f <folder>         Add all files/folders within a folder
  gignore -u                  Add all unstaged changes (modified/new files)
  gignore -m                  Add all modified files (staged and unstaged)
  gignore -n                  Add all new/untracked files
  gignore -h, --help          Show this help

Examples:
  gignore node_modules/       # Add node_modules folder
  gignore config.local.json   # Add specific file
  gignore -f dist/            # Add all items in dist/ folder
  gignore -u                  # Add all unstaged changes
EOF
            return 0
            ;;
        -f)
            # Add all files in a folder
            if [ -z "$2" ]; then
                echo "Error: Please specify a folder path"
                return 1
            fi
            
            local folder="${2%/}"  # Remove trailing slash if present
            
            if [ ! -d "$folder" ]; then
                echo "Error: Folder '$folder' does not exist"
                return 1
            fi
            
            echo "Adding all items in '$folder/' to .gitignore..."
            find "$folder" -type f -o -type d | while read -r item; do
                # Make path relative and add to gitignore if not already there
                if ! grep -qxF "$item" "$gitignore"; then
                    echo "$item" >> "$gitignore"
                    echo "  + $item"
                fi
            done
            
            # Also add the folder pattern itself
            if ! grep -qxF "${folder}/" "$gitignore" && ! grep -qxF "${folder}" "$gitignore"; then
                echo "${folder}/" >> "$gitignore"
                echo "  + ${folder}/"
            fi
            echo "Done!"
            ;;
        -u)
            # Add all unstaged changes
            echo "Adding all unstaged changes to .gitignore..."
            git status --porcelain | grep '^ M\|^??|^ D' | awk '{print $2}' | while read -r file; do
                if [ -n "$file" ] && ! grep -qxF "$file" "$gitignore"; then
                    echo "$file" >> "$gitignore"
                    echo "  + $file"
                fi
            done
            echo "Done!"
            ;;
        -m)
            # Add all modified files (staged and unstaged)
            echo "Adding all modified files to .gitignore..."
            git status --porcelain | grep '^ M\|^M \|^MM' | awk '{print $2}' | while read -r file; do
                if [ -n "$file" ] && ! grep -qxF "$file" "$gitignore"; then
                    echo "$file" >> "$gitignore"
                    echo "  + $file"
                fi
            done
            echo "Done!"
            ;;
        -n)
            # Add all new/untracked files
            echo "Adding all untracked files to .gitignore..."
            git status --porcelain | grep '^??' | awk '{print $2}' | while read -r file; do
                if [ -n "$file" ] && ! grep -qxF "$file" "$gitignore"; then
                    echo "$file" >> "$gitignore"
                    echo "  + $file"
                fi
            done
            echo "Done!"
            ;;
        *)
            # Add a specific file or folder
            if [ -z "$1" ]; then
                echo "Error: Please specify a file or folder, or use -h for help"
                return 1
            fi
            
            local path="$1"
            
            # Check if it's a directory, add trailing slash
            if [ -d "$path" ]; then
                path="${path%/}/"  # Ensure single trailing slash
            fi
            
            # Check if already in gitignore
            if grep -qxF "$path" "$gitignore"; then
                echo "'$path' is already in .gitignore"
                return 0
            fi
            
            echo "$path" >> "$gitignore"
            echo "Added '$path' to .gitignore"
            ;;
    esac
}


# Enhanced git stash management with branch tracking
# Usage:
#   gash             List stashes and apply interactively
#   gash -a          Create a new stash with description and branch tracking
gash() {
    case "$1" in
        -a|--add)
            # Create a new stash with branch and commit info
            local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
            local current_commit=$(git rev-parse --short HEAD)
            
            read -p "Enter stash description: " description
            
            if [ -z "$description" ]; then
                echo "Error: Description is required"
                return 1
            fi
            
            # Format: [branch:commit] description
            local stash_msg="[${current_branch}:${current_commit}] ${description}"
            
            git stash push -m "$stash_msg"
            echo "✓ Stashed on branch '$current_branch' at commit $current_commit"
            ;;
        -h|--help)
            cat <<'EOF'
gash - Enhanced git stash management with branch tracking

Usage:
  gash              List all stashes with branch info and apply interactively
  gash -a           Add/create a new stash with description and branch tracking
  gash -h, --help   Show this help

Examples:
  gash -a           # Create a new tracked stash
  gash              # List and interactively apply stashes
EOF
            return 0
            ;;
        "")
            # List stashes and allow interactive selection
            local stash_list=$(git stash list)
            
            if [ -z "$stash_list" ]; then
                echo "No stashes found"
                return 0
            fi
            
            echo "Available stashes:"
            echo "========================================"
            
            # Parse and display stashes with better formatting
            local index=0
            while IFS= read -r stash; do
                # Extract branch and commit if present
                if [[ "$stash" =~ stash@\{[0-9]+\}:.*\[([^:]+):([^\]]+)\]\ (.+) ]]; then
                    local branch="${BASH_REMATCH[1]}"
                    local commit="${BASH_REMATCH[2]}"
                    local desc="${BASH_REMATCH[3]}"
                    echo "$index) $desc"
                    echo "   Branch: $branch | Commit: $commit"
                else
                    # Fallback for stashes without our format
                    echo "$index) $stash"
                fi
                echo ""
                ((index++))
            done <<< "$stash_list"
            
            echo "========================================"
            read -p "Select stash number (or press Enter to cancel): " selection
            
            if [ -z "$selection" ]; then
                echo "Cancelled"
                return 0
            fi
            
            # Validate selection
            if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
                echo "Error: Invalid selection"
                return 1
            fi
            
            local stash_count=$(git stash list | wc -l)
            if [ "$selection" -ge "$stash_count" ]; then
                echo "Error: Stash number out of range"
                return 1
            fi
            
            # Get the stash reference
            local stash_ref="stash@{${selection}}"
            local stash_info=$(git stash list | sed -n "$((selection + 1))p")
            
            # Extract branch from stash message if it exists
            local stash_branch=""
            if [[ "$stash_info" =~ \[([^:]+):[^\]]+\] ]]; then
                stash_branch="${BASH_REMATCH[1]}"
            fi
            
            local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
            
            echo ""
            echo "Selected stash: $stash_ref"
            echo ""
            
            if [ -n "$stash_branch" ] && [ "$stash_branch" != "$current_branch" ] && [ "$stash_branch" != "detached" ]; then
                echo "Original branch: $stash_branch"
                echo "Current branch:  $current_branch"
                echo ""
                echo "Options:"
                echo "  1) Checkout '$stash_branch' and apply stash"
                echo "  2) Apply stash to current branch '$current_branch'"
                echo "  3) Cancel"
                read -p "Select option [1/2/3]: " apply_option
                
                case "$apply_option" in
                    1)
                        echo "Checking out branch '$stash_branch'..."
                        git checkout "$stash_branch" || return 1
                        echo "Applying stash..."
                        git stash pop "$stash_ref"
                        ;;
                    2)
                        echo "Applying stash to current branch..."
                        git stash pop "$stash_ref"
                        ;;
                    *)
                        echo "Cancelled"
                        return 0
                        ;;
                esac
            else
                read -p "Apply this stash? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    git stash pop "$stash_ref"
                else
                    echo "Cancelled"
                fi
            fi
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use 'gash -h' for help"
            return 1
            ;;
    esac
}


# Merge current branch into main with validation and optional rebase
# Usage: mergemain
mergemain() {
    # merge current branch into main with checks and optional rebase
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    
    if [ -z "$current_branch" ]; then
        echo "Error: Not on a branch (detached HEAD)"
        return 1
    fi
    
    # Check if already on main
    if [ "$current_branch" = "main" ]; then
        echo "Error: Already on main branch. Switch to the branch you want to merge first."
        return 1
    fi
    
    echo "Current branch: $current_branch"
    echo ""
    
    # Fetch latest from origin to ensure we have up-to-date refs
    echo "Fetching latest from origin..."
    git fetch origin main || {
        echo "Warning: Could not fetch from origin. Continuing with local refs..."
    }
    
    # Check if main branch exists locally
    if ! git rev-parse --verify main >/dev/null 2>&1; then
        echo "Error: 'main' branch does not exist locally"
        return 1
    fi
    
    # Validate if current branch was created from main
    echo "Validating branch ancestry..."
    local merge_base=$(git merge-base "$current_branch" main 2>/dev/null)
    
    if [ -z "$merge_base" ]; then
        echo "Warning: Could not determine common ancestor with main"
        read -p "Continue anyway? (y/n): " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            echo "Aborted"
            return 0
        fi
    else
        # Check if merge-base is an ancestor of main
        if git merge-base --is-ancestor "$merge_base" main; then
            echo "✓ Branch '$current_branch' has common ancestry with main"
            
            # Get the commit where the branch diverged from main
            local main_head=$(git rev-parse main)
            if [ "$merge_base" = "$main_head" ]; then
                echo "✓ Branch is up-to-date with main (no divergence)"
            else
                # Count commits behind
                local commits_behind=$(git rev-list --count ${current_branch}..main)
                if [ "$commits_behind" -gt 0 ]; then
                    echo "ℹ Main branch is $commits_behind commit(s) ahead"
                fi
            fi
        else
            echo "Warning: Branch '$current_branch' does not appear to originate from main"
            read -p "Continue with merge anyway? (y/n): " continue_merge
            if [[ ! "$continue_merge" =~ ^[Yy]$ ]]; then
                echo "Aborted"
                return 0
            fi
        fi
    fi
    
    echo ""
    
    # Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        echo "Error: You have uncommitted changes. Please commit or stash them first."
        git status --short
        return 1
    fi
    
    # Ask if user wants to rebase on top of main first
    read -p "Do you want to rebase '$current_branch' on top of main before merging? (y/n): " do_rebase
    
    if [[ "$do_rebase" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Rebasing '$current_branch' on top of main..."
        git rebase main || {
            echo ""
            echo "Error: Rebase failed. Resolve conflicts and run:"
            echo "  git rebase --continue"
            echo "Or abort the rebase with:"
            echo "  git rebase --abort"
            return 1
        }
        echo "✓ Rebase completed successfully"
        echo ""
    fi
    
    # Switch to main branch
    echo "Switching to main branch..."
    git checkout main || {
        echo "Error: Could not switch to main branch"
        return 1
    }
    
    # Pull latest changes on main
    echo "Pulling latest changes on main..."
    git pull origin main || {
        echo "Warning: Could not pull from origin/main. Continuing with local main..."
    }
    
    echo ""
    
    # Merge the branch into main
    echo "Merging '$current_branch' into main..."
    if git merge "$current_branch" --no-ff; then
        echo ""
        echo "✓ Successfully merged '$current_branch' into main"
        echo ""
        read -p "Push main to origin? (y/n): " push_main
        if [[ "$push_main" =~ ^[Yy]$ ]]; then
            git push origin main
            echo "✓ Pushed main to origin"
        fi
        
        echo ""
        read -p "Delete local branch '$current_branch'? (y/n): " delete_local
        if [[ "$delete_local" =~ ^[Yy]$ ]]; then
            git branch -d "$current_branch"
            echo "✓ Deleted local branch '$current_branch'"
            
            read -p "Delete remote branch 'origin/$current_branch'? (y/n): " delete_remote
            if [[ "$delete_remote" =~ ^[Yy]$ ]]; then
                git push origin --delete "$current_branch" 2>/dev/null && echo "✓ Deleted remote branch 'origin/$current_branch'" || echo "Note: Remote branch may not exist or could not be deleted"
            fi
        fi
    else
        echo ""
        echo "Error: Merge failed. Resolve conflicts and commit, or run:"
        echo "  git merge --abort"
        return 1
    fi
}

function sbr() {
  # Squash the entire branch from its branching point
  current_branch=$(git symbolic-ref --short HEAD)
  
  # Check if we're on a branch
  if [ -z "$current_branch" ]; then
    echo "Error: Not currently on a branch"
    return 1
  fi
  
  # Try to find the base branch (master or main)
  base_branch=""
  if git show-ref --verify --quiet refs/heads/master; then
    base_branch="master"
  elif git show-ref --verify --quiet refs/heads/main; then
    base_branch="main"
  else
    echo "Error: Could not find master or main branch"
    return 1
  fi
  
  # Don't allow squashing the base branch itself
  if [ "$current_branch" = "$base_branch" ]; then
    echo "Error: Cannot squash the $base_branch branch"
    return 1
  fi
  
  # Find the branching point
  merge_base=$(git merge-base HEAD $base_branch)
  
  if [ -z "$merge_base" ]; then
    echo "Error: Could not find branching point"
    return 1
  fi
  
  # Count commits to be squashed
  commit_count=$(git rev-list --count $merge_base..HEAD)
  
  if [ "$commit_count" -eq 0 ]; then
    echo "No commits to squash"
    return 0
  fi
  
  echo "This will squash $commit_count commit(s) from branch '$current_branch'"
  
  # Ask for commit message
  read -p "Enter commit message: " commit_message
  
  if [ -z "$commit_message" ]; then
    echo "Error: Commit message cannot be empty"
    return 1
  fi
  
  # Perform the squash
  git reset --soft $merge_base && git commit -m "$commit_message"
  
  if [ $? -eq 0 ]; then
    echo "Successfully squashed $commit_count commit(s) into one"
  else
    echo "Error: Failed to squash commits"
    return 1
  fi
}

function delc() {
  # Delete a commit from the branch by picking a number
  
  # Get the number of commits to show (default 10, or use argument)
  local count=${1:-10}
  
  echo "Recent commits:"
  echo ""
  
  # Show numbered list of commits
  git log --oneline -n "$count" | nl -v 1 -w 3 -s '. '
  
  echo ""
  read -p "Enter commit number to delete (1 = most recent): " commit_num
  
  # Validate input
  if ! [[ "$commit_num" =~ ^[0-9]+$ ]]; then
    echo "Error: Please enter a valid number"
    return 1
  fi
  
  if [ "$commit_num" -lt 1 ] || [ "$commit_num" -gt "$count" ]; then
    echo "Error: Number out of range"
    return 1
  fi
  
  # Get the commit hash to delete
  commit_hash=$(git log --oneline -n "$count" | sed -n "${commit_num}p" | awk '{print $1}')
  
  if [ -z "$commit_hash" ]; then
    echo "Error: Could not find commit"
    return 1
  fi
  
  # Show which commit will be deleted
  echo ""
  echo "Will delete:"
  git log --oneline -n 1 "$commit_hash"
  echo ""
  
  read -p "Confirm deletion? (y/n): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    return 0
  fi
  
  # Use interactive rebase to delete the commit
  GIT_SEQUENCE_EDITOR="sed -i '/${commit_hash}/d'" git rebase -i "${commit_hash}^"
  
  if [ $? -eq 0 ]; then
    echo "Commit deleted successfully"
  else
    echo "Error: Failed to delete commit. You may need to resolve conflicts or run: git rebase --abort"
    return 1
  fi
}


function gcp() {
    # Commit and push from the directory containing this script
    # Usage:
    #   gcp "message"     # Commit with message and push
    #   gcp              # Commit with editor and push
    
    local message="$1"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [ -z "$message" ]; then
        (cd "$script_dir" && git commit && git push origin HEAD)
    else
        (cd "$script_dir" && git commit -m "$message" && git push origin HEAD)
    fi
}

function gbclean() {
    # List old branches that haven't been merged into the current branch
    # Shows branch name and last commit date
    # Usage:
    #   gbclean           # List unmerged branches with last commit time
    #   gbclean -d        # Delete branches interactively
    
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    
    if [ -z "$current_branch" ]; then
        echo "Error: Not on a branch (detached HEAD)"
        return 1
    fi
    
    echo "Unmerged branches (compared to '$current_branch'):"
    echo "=================================================="
    echo ""
    
    local branches=$(git branch -v --no-merged "$current_branch")
    
    if [ -z "$branches" ]; then
        echo "No unmerged branches found"
        return 0
    fi
    
    # Display branches with numbers and last commit date
    local index=1
    declare -a branch_list
    git for-each-ref --sort=-committerdate refs/heads --format='%(refname:short)|%(committerdate:short)' | 
    while IFS='|' read -r branch date; do
        # Check if branch is merged
        if ! git merge-base --is-ancestor "$branch" "$current_branch" 2>/dev/null; then
            printf "%2d) %-30s %s\n" "$index" "$branch" "$date"
            branch_list+=("$branch")
            ((index++))
        fi
    done
    
    echo ""
    echo "=================================================="
    read -p "Enter branch number to delete (or press Enter to cancel): " branch_num
    
    if [ -z "$branch_num" ]; then
        echo "Cancelled"
        return 0
    fi
    
    if ! [[ "$branch_num" =~ ^[0-9]+$ ]] || [ "$branch_num" -lt 1 ]; then
        echo "Error: Invalid selection"
        return 1
    fi
    
    # Get selected branch (adjust for 1-based indexing)
    local selected_branch=$(git for-each-ref --sort=-committerdate refs/heads --format='%(refname:short)' | 
        awk -v idx="$branch_num" 'BEGIN{count=0} {if(!system("git merge-base --is-ancestor \"" $0 "\" '"$current_branch"'" &>/dev/null")){count++; if(count==idx){print $0; exit}}}')
    
    if [ -z "$selected_branch" ]; then
        echo "Error: Branch number out of range"
        return 1
    fi
    
    read -p "Delete '$selected_branch' locally and remotely? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        git branch -d "$selected_branch" && git push origin --delete "$selected_branch" && echo "✓ Deleted '$selected_branch'"
    else
        echo "Cancelled"
    fi
}


function gbmerge() {
    # Merge a branch into another by selecting from lists
    # Usage:
    #   gbmerge           # Interactive selection of source and target branches
    
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    
    if [ -z "$current_branch" ]; then
        echo "Error: Not on a branch (detached HEAD)"
        return 1
    fi
    
    echo "Current branch: $current_branch"
    echo ""
    echo "Select source branch (branch to merge FROM):"
    echo "=============================================="
    
    local branches=$(git branch -v)
    local index=1
    declare -a branch_array
    
    while IFS= read -r line; do
        local branch=$(echo "$line" | awk '{print $1}' | sed 's/^\* //')
        printf "%2d) %s\n" "$index" "$branch"
        branch_array+=("$branch")
        ((index++))
    done <<< "$branches"
    
    echo ""
    read -p "Select source branch number: " source_num
    
    if ! [[ "$source_num" =~ ^[0-9]+$ ]] || [ "$source_num" -lt 1 ] || [ "$source_num" -gt "${#branch_array[@]}" ]; then
        echo "Error: Invalid selection"
        return 1
    fi
    
    local source_branch="${branch_array[$((source_num - 1))]}"
    
    echo ""
    echo "Select target branch (branch to merge INTO):"
    echo "=============================================="
    
    index=1
    local target_array=()
    
    while IFS= read -r line; do
        local branch=$(echo "$line" | awk '{print $1}' | sed 's/^\* //')
        printf "%2d) %s\n" "$index" "$branch"
        target_array+=("$branch")
        ((index++))
    done <<< "$branches"
    
    echo ""
    read -p "Select target branch number: " target_num
    
    if ! [[ "$target_num" =~ ^[0-9]+$ ]] || [ "$target_num" -lt 1 ] || [ "$target_num" -gt "${#target_array[@]}" ]; then
        echo "Error: Invalid selection"
        return 1
    fi
    
    local target_branch="${target_array[$((target_num - 1))]}"
    
    if [ "$source_branch" = "$target_branch" ]; then
        echo "Error: Source and target branches cannot be the same"
        return 1
    fi
    
    echo ""
    echo "Merging '$source_branch' into '$target_branch'..."
    
    git checkout "$target_branch" || return 1
    git merge "$source_branch" --no-ff || {
        echo "Error: Merge failed. Resolve conflicts and run: git merge --abort"
        return 1
    }
    
    echo "✓ Successfully merged '$source_branch' into '$target_branch'"
}

gta() {
    git fetch --tags
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
    if [ -z "$LAST_TAG" ]; then
        echo "No tags found in this repository."
    else
        echo "Last tag: $LAST_TAG"
    fi
    echo -n "Enter new tag name: "
    read NEW_TAG
    if [ -z "$NEW_TAG" ]; then
        echo "No tag name entered. Exiting."
        return 1
    fi
    git rev-parse "$NEW_TAG" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Tag '$NEW_TAG' already exists. Exiting."
        return 1
    fi
    git tag "$NEW_TAG"
    if [ $? -eq 0 ]; then
        echo "Tag '$NEW_TAG' created successfully."
        echo "Pushing tag to origin..."
        git push origin "$NEW_TAG"
    else
        echo "Failed to create tag."
        return 1
    fi
}


rebasemain() {
    # Rebase current branch onto main with checks
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    
    if [ -z "$current_branch" ]; then
        echo "Error: Not on a branch (detached HEAD)"
        return 1
    fi
    
    if [ "$current_branch" = "main" ]; then
        echo "Error: Already on main branch. Switch to the branch you want to rebase first."
        return 1
    fi
    
    echo "Current branch: $current_branch"
    echo ""
    
    echo "Fetching latest from origin..."
    git fetch origin main || {
        echo "Warning: Could not fetch from origin. Continuing with local refs..."
    }
    
    if ! git rev-parse --verify main >/dev/null 2>&1; then
        echo "Error: 'main' branch does not exist locally"
        return 1
    fi
    
    echo "Rebasing '$current_branch' onto main..."
    git rebase main || {
        echo ""
        echo "Error: Rebase failed. Resolve conflicts and run:"
        echo "  git rebase --continue"
        echo "Or abort the rebase with:"
        echo "  git rebase --abort"
        return 1
    }
    
    echo "✓ Rebase completed successfully"
}

ginit() {
    # Initialize a new git repository with optional remote
    # Usage:
    #   ginit [remote-url]

    

    git init
    if [ $? -ne 0 ]; then
        echo "Error: Failed to initialize git repository"
        return 1
    fi
    
    echo "Initialized empty git repository"

    git add .
    if [ $? -ne 0 ]; then
        echo "Error: Failed to add files"
        return 1
    fi
    
    echo "Added all files to staging area"


    if [ -n "$1" ]; then
        git remote add origin "$1"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to add remote '$1'"
            return 1
        fi
        echo "Added remote 'origin' with URL: $1"
    fi
}

pullall() {
    # @desc Checkout main and pull latest for repos in current directory
    # Usage:
    #   pullall           # List repos and select by number or 'all'
    
    local base_dir="$(pwd)"
    local repos=()
    
    # Find all subdirectories that are git repos
    for dir in "$base_dir"/*/; do
        if [ -d "${dir}.git" ]; then
            repos+=("$(basename "$dir")")
        fi
    done
    
    if [ ${#repos[@]} -eq 0 ]; then
        echo "No git repositories found in current directory"
        return 1
    fi
    
    echo "Git repositories in $(basename "$base_dir"):"
    echo "=============================================="
    
    local index=1
    for repo in "${repos[@]}"; do
        printf "%2d) %s\n" "$index" "$repo"
        ((index++))
    done
    
    echo ""
    echo "=============================================="
    echo "Enter number(s) to select (e.g., 1 2 3), 'all' for all repos, or press Enter to cancel"
    read -p "> " selection
    
    if [ -z "$selection" ]; then
        echo "Cancelled"
        return 0
    fi
    
    local selected_repos=()
    
    if [ "$selection" = "all" ]; then
        selected_repos=("${repos[@]}")
    else
        # Parse space-separated numbers
        for num in $selection; do
            if ! [[ "$num" =~ ^[0-9]+$ ]]; then
                echo "Error: Invalid input '$num'"
                return 1
            fi
            if [ "$num" -lt 1 ] || [ "$num" -gt ${#repos[@]} ]; then
                echo "Error: Number $num out of range"
                return 1
            fi
            selected_repos+=("${repos[$((num - 1))]}")
        done
    fi
    
    # Ask for branch to pull
    echo ""
    read -p "Branch to pull (default: main/master auto-detect): " target_branch
    
    echo ""
    
    for repo in "${selected_repos[@]}"; do
        echo "----------------------------------------"
        echo "Processing: $repo"
        echo "----------------------------------------"
        
        cd "$base_dir/$repo" || {
            echo "  Error: Could not enter directory"
            continue
        }
        
        # Check for uncommitted changes and stash them
        local had_changes=0
        if ! git diff-index --quiet HEAD -- 2>/dev/null || [ -n "$(git status --porcelain 2>/dev/null)" ]; then
            echo "  Local changes detected - stashing..."
            git stash push -m "pullall auto-stash for $repo"
            had_changes=1
        fi
        
        # Determine branch to pull
        local main_branch=""
        if [ -n "$target_branch" ]; then
            # User specified a branch - verify it exists
            if git show-ref --verify --quiet "refs/heads/$target_branch"; then
                main_branch="$target_branch"
            else
                echo "  Error: Branch '$target_branch' not found - skipping"
                cd "$base_dir"
                continue
            fi
        else
            # Auto-detect main/master
            if git show-ref --verify --quiet refs/heads/main; then
                main_branch="main"
            elif git show-ref --verify --quiet refs/heads/master; then
                main_branch="master"
            else
                echo "  Error: No main or master branch found - skipping"
                cd "$base_dir"
                continue
            fi
        fi
        
        local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
        
        if [ "$current_branch" != "$main_branch" ]; then
            echo "  Checking out $main_branch..."
            git checkout "$main_branch" || {
                echo "  Error: Could not checkout $main_branch"
                cd "$base_dir"
                continue
            }
        fi
        
        echo "  Pulling latest..."
        git pull origin "$main_branch" || {
            echo "  Error: Pull failed"
            if [ $had_changes -eq 1 ]; then
                echo "  Restoring stashed changes..."
                git stash pop
            fi
            cd "$base_dir"
            continue
        }
        
        echo "  ✓ Updated to latest $main_branch"
        
        # Restore stashed changes if any
        if [ $had_changes -eq 1 ]; then
            echo "  Restoring stashed changes..."
            git stash pop || {
                echo "  Warning: Could not auto-restore stash (may have conflicts)"
                echo "  Use 'git stash pop' manually to restore"
            }
        fi
        
        cd "$base_dir"
    done
    
    echo ""
    echo "Done!"
}

