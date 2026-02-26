alias gasoline="rm -rf *" 
alias ets="et; pp" 
alias etgs='et;gs' 
alias refrsh="source ~/.bashrc" 
alias esc_old='vim ~/.bashrc' 
alias exc_old='esc'
alias sjow='explorer.exe .'
alias portal='cd ~' 



function exc() {
  # @desc Edit sourced bash helper files with auto-sync to git, or create new files
  local bashrc="${HOME}/.bashrc"
  local sourced_files=()
  local script_dir=""
  
  # Extract sourced files from bashrc
  while IFS= read -r line; do
    if [[ "$line" =~ ^source\ \"(.*)\" ]]; then
      sourced_files+=("${BASH_REMATCH[1]}")
      # Get the script directory from the first sourced file
      if [[ -z "$script_dir" ]]; then
        script_dir="$(dirname "${BASH_REMATCH[1]}")"
      fi
    fi
  done < <(grep -A 100 "# Sourced from setup.sh" "$bashrc")
  
  # If no script directory found, try to determine from git repo
  if [[ -z "$script_dir" ]]; then
    # Try to find C:\com\bash or current directory
    if [[ -d "C:/com/bash/.git" ]]; then
      script_dir="C:/com/bash"
    elif [[ -d ".git" ]]; then
      script_dir="$(pwd)"
    else
      echo "Could not determine script directory. Please run setup.sh first."
      return 1
    fi
  fi
  
  echo "Sourced files:"
  for ((i=0; i<${#sourced_files[@]}; i++)); do
    echo "$((i+1)): $(basename "${sourced_files[$i]}")"
  done
  echo "B: Edit .bashrc"
  echo "N: Create new file"
  echo ""
  
  read -p "Enter the number of the file to edit (or 'B' for bashrc, 'N' for new): " choice
  
  # Handle bashrc editing
  if [[ "$choice" =~ ^[Bb]$ ]]; then
    selected_file="$bashrc"
    local file_name=".bashrc"
    local is_new_file=false
    
  # Handle new file creation
  elif [[ "$choice" =~ ^[Nn]$ ]]; then
    echo ""
    read -p "Enter new file name (e.g., mycommands.sh): " new_file_name
    
    # Ensure .sh extension
    if [[ ! "$new_file_name" =~ \.sh$ ]]; then
      new_file_name="${new_file_name}.sh"
    fi
    
    local new_file_path="${script_dir}/${new_file_name}"
    
    # Check if file already exists
    if [[ -f "$new_file_path" ]]; then
      echo "File already exists: $new_file_name"
      read -p "Edit existing file? (Y/n): " edit_existing
      edit_existing=${edit_existing:-Y}
      if [[ ! "$edit_existing" =~ ^[Yy]$ ]]; then
        return 1
      fi
    else
      # Create new file with template
      cat > "$new_file_path" << 'EOF'
#!/bin/bash

# Add your custom bash functions and aliases here

EOF
      echo "✓ Created new file: $new_file_name"
    fi
    
    selected_file="$new_file_path"
    local file_name="$new_file_name"
    local is_new_file=true
    
  elif [[ $choice =~ ^[0-9]+$ ]] && (( choice > 0 && choice <= ${#sourced_files[@]} )); then
    selected_file="${sourced_files[$((choice-1))]}"
    local file_name="$(basename "$selected_file")"
    local is_new_file=false
  else
    echo "Invalid choice."
    return 1
  fi
  
  # Get file hash before editing
  local hash_before=""
  if command -v sha256sum &> /dev/null; then
    hash_before=$(sha256sum "$selected_file" 2>/dev/null | awk '{print $1}')
  elif command -v shasum &> /dev/null; then
    hash_before=$(shasum -a 256 "$selected_file" 2>/dev/null | awk '{print $1}')
  fi
  
  # Open in editor (wait for VSCode to close if using --wait flag)
  if command -v code &> /dev/null; then
    # Try to use --wait flag so we know when editing is done
    if code --help 2>&1 | grep -q "\--wait"; then
      echo "Opening $file_name in VSCode (waiting for editor to close)..."
      code --wait "$selected_file"
    else
      echo "Opening $file_name in VSCode..."
      code "$selected_file"
      echo ""
      echo "⚠ VSCode opened in background. Press Enter when done editing..."
      read
    fi
  else
    vim "$selected_file"
  fi
  
  # Get file hash after editing
  local hash_after=""
  if command -v sha256sum &> /dev/null; then
    hash_after=$(sha256sum "$selected_file" 2>/dev/null | awk '{print $1}')
  elif command -v shasum &> /dev/null; then
    hash_after=$(shasum -a 256 "$selected_file" 2>/dev/null | awk '{print $1}')
  fi
  
  # Check if file was modified or if it's a new file
  local file_changed=false
  if [[ "$is_new_file" == true ]]; then
    file_changed=true
  elif [[ -n "$hash_before" && -n "$hash_after" && "$hash_before" != "$hash_after" ]]; then
    file_changed=true
  fi
  
  if [[ "$file_changed" == true ]]; then
    echo ""
    echo "✓ Changes detected in $file_name"
    
    # Add to bashrc if it's a new file
    if [[ "$is_new_file" == true ]]; then
      # Check if file is already sourced in bashrc
      if grep -q "source \"$selected_file\"" "$bashrc"; then
        echo "✓ File already sourced in bashrc"
      else
        echo ""
        read -p "Add to bashrc for auto-loading? (Y/n): " add_to_bashrc
        add_to_bashrc=${add_to_bashrc:-Y}
        
        if [[ "$add_to_bashrc" =~ ^[Yy]$ ]]; then
          # Check if "# Sourced from setup.sh" section exists
          if grep -q "# Sourced from setup.sh" "$bashrc"; then
            # Add after the comment line
            sed -i "/# Sourced from setup.sh/a source \"$selected_file\"" "$bashrc"
          else
            # Create new section
            echo "" >> "$bashrc"
            echo "# Sourced from setup.sh" >> "$bashrc"
            echo "source \"$selected_file\"" >> "$bashrc"
          fi
          echo "✓ Added to bashrc: $file_name"
        fi
      fi
    fi
    
    # Check if we're in a git repo and NOT editing bashrc (bashrc is not in the repo)
    if [[ -d "$script_dir/.git" ]] && [[ "$file_name" != ".bashrc" ]]; then
      echo ""
      read -p "Commit and push changes? (Y/n): " should_commit
      should_commit=${should_commit:-Y}  # Default to Yes
      
      if [[ "$should_commit" =~ ^[Yy]$ ]]; then
        echo ""
        echo "🔄 Starting git sync..."
        echo "────────────────────────────────────────────────"
        
        (
          cd "$script_dir" || exit 1
          
          # Show diff
          echo ""
          echo "📝 Changes made:"
          git diff "$file_name" | head -20
          local diff_lines=$(git diff "$file_name" | wc -l)
          if [[ $diff_lines -gt 20 ]]; then
            echo "... ($(($diff_lines - 20)) more lines)"
          fi
          
          echo ""
          read -p "Commit message (or press Enter for default): " commit_msg
          
          if [[ -z "$commit_msg" ]]; then
            commit_msg="Update $file_name"
          fi
          
          echo ""
          echo "💾 Committing changes..."
          
          # Stage the file
          git add "$file_name"
          
          # Commit
          if git commit -m "$commit_msg"; then
            echo "✓ Committed: $commit_msg"
            
            # Push to remote
            echo ""
            echo "📤 Pushing to remote..."
            if git push origin HEAD; then
              echo "✓ Successfully pushed to remote"
              echo "────────────────────────────────────────────────"
            else
              echo "✗ Failed to push (you may need to push manually later)"
            fi
          else
            echo "✗ Commit failed"
          fi
        )
      else
        echo "Skipped commit. Don't forget to commit your changes later!"
      fi
    fi
    
    # Ask to reload shell
    echo ""
    read -p "Reload shell configuration? (Y/n): " should_reload
    should_reload=${should_reload:-Y}  # Default to Yes
    
    if [[ "$should_reload" =~ ^[Yy]$ ]]; then
      source ~/.bashrc
      echo "✓ Shell configuration reloaded"
    fi
  else
    echo ""
    echo "No changes detected"
  fi
}

function pp { 
  # @desc Navigate up N directories (usage: pp 3 to go up 3 levels)
  num=${1:-1} 
  while [ $num -ne 0 ]; do 
    cd .. 
    num=$((num-1)) 
  done 
}

replace_in_files() { 
  # @desc Replace text in files by extension (usage: replace_in_files old new js)
  if [ $# -ne 2 ]; then 
    echo "Usage: replace_in_files <old_word> <new_word> <file_extensions (optional)>" 
    return 1 
  fi 
  local old_word="$1" 
  local new_word="$2" 
  local extensions="${3:-*}"  # Default: all files if no extension provided 
  find . -type f -name "*.$extensions" -exec sed -i "s/$old_word/$new_word/g" {} \; 
}

ss() { 
  # @desc Search for text in files recursively (usage: ss "searchterm" [folder])
  if [ $# -lt 1 ]; then 
    echo "Usage: search_folder <word> [folder_path]" 
    return 1 
  fi 
  word="$1" 
  folder_path="${2:-$PWD}" 
  grep -r -i "$word" "$folder_path" 
}
edir () { 
  # @desc Create directory and cd into it (usage: edir newfolder)
  mkdir -p "$1" && cd "$1" 
}

sse() { 
  # @desc Search for text in files by extension (usage: sse "term" js)
  if [ $# -lt 2 ]; then 
    echo "Usage: sse <word> <extension> [folder_path]" 
    return 1 
  fi 
  word="$1" 
  extension="$2" 
  folder_path="${3:-$PWD}" 
  grep -r -i "$word" "$folder_path" --include="*.$extension" 
}


function sfs() { 
  # @desc Search for files by name pattern (usage: sfs pattern [path])
  local search_term="$1" 
  local search_path="${2:-.}"  # Default to current directory if no path is given 
  find "$search_path" -type f -name "*$search_term*" 2>/dev/null || \ 
  find "$search_path" -type d -name "*$search_term*" 2>/dev/null 
}
function sfsv() { 
  # Search for files matching the search term and open in vim if one result
  local search_term="$1" 
  local search_path="${2:-.}" 
  local results=($(find "$search_path" -type f -name "*$search_term*" 2>/dev/null)) 
  if [[ ${#results[@]} -eq 1 ]]; then 
    vim "${results[0]}" 
  else 
    for result in "${results[@]}"; do 
      echo "$result" 
    done 
  fi 
} 



function list_files() {
  # List files matching a partial name and optional extension
  local search_term="$1"
  local file_extension="$2"

  # If both search_term and file_extension are empty, show usage
  if [[ -z "$search_term" && -z "$file_extension" ]]; then
    echo "Usage: gto <partial_file_name> [file_extension]"
    return 1
  fi

  # Build the search pattern
  local pattern="*${search_term}*"
  if [[ -n "$file_extension" ]]; then
    pattern="${pattern}${file_extension}"
  fi

  local results=($(find . -type f -iname "$pattern" 2>/dev/null))

  if [[ ${#results[@]} -eq 0 ]]; then
    echo "No files found."
    return 1
  elif [[ ${#results[@]} -eq 1 ]]; then
    selected_file="${results[0]}"
    cd "$(dirname "$selected_file")"
    return 0
  else
    for ((i=0; i<${#results[@]}; i++)); do
      echo "$((i+1)): $(basename "${results[i]}") - $(dirname "${results[i]}")"
    done
    read -p "Enter the number of the file you want to go to: " choice
    if [[ $choice =~ ^[0-9]+$ ]] && (( choice > 0 && choice <= ${#results[@]} )); then
      selected_file="${results[$((choice-1))]}"
      return 0
    else
      echo "Invalid choice."
      return 1
    fi
  fi
}



function open_in_vim() {
  # Open the selected file in vim
  if [[ -n "$selected_file" ]]; then
    vim "$selected_file"
    unset selected_file
  else
    echo "No file selected."
  fi
}

function open_in_explorer() {
  # Open the directory of the selected file in Windows Explorer
  local original_dir="$(pwd)"
  if [[ -n "$selected_file" ]]; then
    cd "$(dirname "$selected_file")"
    explorer.exe .
  fi
  cd "$original_dir"
}

function go_to_directory() {
  # Change to the directory of the selected file
  if [[ -n "$selected_file" ]]; then
    cd "$(dirname "$selected_file")"
  fi
}

function sfsd() {
  # Search for files and change to the directory of the selected file
  list_files "$@"
  if [[ $? -eq 0 ]]; then
    go_to_directory
  fi
}

function sfsv() {
  # Search for files and open in vim
  list_files "$@"
  if [[ $? -eq 0 ]]; then
    open_in_vim
  fi
}

function sfse() {
  # Search for files and open in explorer
  list_files "$@"
  if [[ $? -eq 0 ]]; then
    open_in_explorer
  fi
}
function sex() {
  # Search for files by extension and change to the directory
  local file_extension="$1"

  if [[ -z "$file_extension" ]]; then
    echo "Usage: sex <file_extension>"
    return 1
  fi

  list_files "" ".$file_extension"
  if [[ $? -eq 0 ]]; then
    go_to_directory
  fi
}


ffc() {
  # Find folders with the specified name
  target="$1"
  find . -type d -name "$target" -exec dirname {} \; | sort -u
}



function search_in_files() {
  # Search for a term in files with a specific extension
  local search_term="$1"
  local file_extension="$2"

  list_files "" ".$file_extension"
  if [[ $? -eq 0 ]]; then
    for result in "${results[@]}"; do
      grep -i "$search_term" "$result"
    done
  fi
}


function launch() {
  # Search for executable files and launch the selected one
  list_files "$@"

  if [[ -n "$selected_file" ]]; then
    echo "Launching $selected_file..."
    ./"$selected_file"  # Use './' to execute the file in the current directory
  else
    echo "No executable found."
  fi
}


lex() {
    # Extract lines containing a specific word (case-insensitive) from a file
    input_file=$1
    word=$2
    output_file=${3:-"${word}.txt"}

    grep -i "$word" "$input_file" > "$output_file"
}

function Deportation() {
  # Copy unique files with a specific extension to a destination folder
  local file_extension="$1"
  local destination_folder="${2:-.}"

  # Find all files with the specified extension and sort them by modification time
  local files=($(find . -type f -name "*.$file_extension" 2>/dev/null | sort -k1.1,1.1 -k2,2r))

  # Create an associative array to store unique file hashes
  declare -A file_hashes

  # Loop through the sorted list of files and copy them to the destination folder if they are unique
  for file in "${files[@]}"; do
    local file_hash=$(sha256sum "$file" | awk '{print $1}')
    if [[ -z "${file_hashes[$file_hash]}" ]]; then
      cp "$file" "$destination_folder"
      file_hashes[$file_hash]=1
    fi
  done
}







