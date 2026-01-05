alias gasoline="rm -rf *" 
alias ets="et; pp" 
alias etgs='et;gs' 
alias refrsh="source ~/.bashrc" 
alias esc_old='vim ~/.bashrc' 
alias exc_old='esc'
alias sjow='explorer.exe .'
alias portal='cd ~' 



function exc() {
# Edit sourced files in bashrc
  local bashrc="${HOME}/.bashrc"
  local sourced_files=()
  

  while IFS= read -r line; do
    if [[ "$line" =~ ^source\ \"(.*)\" ]]; then
      sourced_files+=("${BASH_REMATCH[1]}")
    fi
  done < <(grep -A 100 "# Sourced from setup.sh" "$bashrc")
  
  if [[ ${#sourced_files[@]} -eq 0 ]]; then
    echo "No sourced files found in bashrc."
    return 1
  fi
  
  echo "Sourced files:"
  for ((i=0; i<${#sourced_files[@]}; i++)); do
    echo "$((i+1)): $(basename "${sourced_files[$i]}")"
  done
  echo ""
  
  read -p "Enter the number of the file to edit: " choice
  
  if [[ $choice =~ ^[0-9]+$ ]] && (( choice > 0 && choice <= ${#sourced_files[@]} )); then
    selected_file="${sourced_files[$((choice-1))]}"
    
    if command -v code &> /dev/null; then
      code "$selected_file"
    else
      vim "$selected_file"
    fi
  else
    echo "Invalid choice."
    return 1
  fi
}

function pp { 
  # Navigate up N directories
  num=${1:-1} 
  while [ $num -ne 0 ]; do 
    cd .. 
    num=$((num-1)) 
  done 
} 

replace_in_files() { 
# Replace old_word with new_word in files with specified extensions
  if [ $# -ne 2 ]; then 
    echo "Usage: replace_in_files <old_word> <new_word> <file_extensions (optional)>" 
    return 1 
  fi 
  local old_word="$1" 
  local new_word="$2" 
  local extensions="${3:-*}"  # Default: all files if no extension provided 
  find . -type f -name "*.$extensions" -exec sed -i '' -e "s/$old_word/$new_word/g" {} \; 
}  

ss() { 
  # Search for a word in files within a folder
  if [ $# -lt 1 ]; then 
    echo "Usage: search_folder <word> [folder_path]" 
    return 1 
  fi 
  word="$1" 
  folder_path="${2:-$PWD}" 
  grep -r -i "$word" "$folder_path" 
} 
edir () { 

  mkdir -p "$1" && cd "$1" 

} 


function sfs() { 
  # Search for files or directories matching the search term
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

function hjelp() {
  # Display aliases and functions with descriptions
  echo "=== ALIASES ==="
  alias | while read -r line; do
    alias_name=$(echo "$line" | awk -F"=" '{print $1}')
    alias_cmd=$(echo "$line" | awk -F"=" '{print $2}' | sed "s/^'//;s/'$//")
    printf "%-15s %s\n" "$alias_name" "$alias_cmd"
  done

  echo ""
  echo "=== FUNCTIONS ==="
  function_list=$(compgen -A function | grep -v "^_")
  
  for func in $function_list; do
    # Extract the comment from the first line after function declaration
    local comment=$(sed -n "/^function $func()/,/^}/p" "$BASH_SOURCE" | sed -n '2p' | sed 's/^[[:space:]]*#[[:space:]]*//;s/^[[:space:]]*//')
    
    if [[ -z "$comment" ]]; then
      comment="No description"
    fi
    
    printf "%-15s %s\n" "$func" "$comment"
  done
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

function proj() {
  # Manage saved project folders - open or edit the list
  local project_file="${HOME}/.project_folders"
  
  # Create project file if it doesn't exist
  if [[ ! -f "$project_file" ]]; then
    touch "$project_file"
  fi
  
  echo "1: Open a saved project folder"
  echo "2: Edit project folders (add/delete)"
  read -p "Choose an option (1 or 2): " option
  
  case $option in
    1)
      # Open a saved project folder
      local projects=()
      while IFS= read -r line; do
        [[ -n "$line" ]] && projects+=("$line")
      done < "$project_file"
      
      if [[ ${#projects[@]} -eq 0 ]]; then
        echo "No saved project folders found."
        return 1
      fi
      
      echo "Saved projects:"
      for ((i=0; i<${#projects[@]}; i++)); do
        echo "$((i+1)): ${projects[$i]}"
      done
      echo ""
      
      read -p "Enter the number of the project to open: " choice
      if [[ $choice =~ ^[0-9]+$ ]] && (( choice > 0 && choice <= ${#projects[@]} )); then
        cd "${projects[$((choice-1))]}"
        echo "Changed to: $(pwd)"
      else
        echo "Invalid choice."
        return 1
      fi
      ;;
    2)
      # Edit project folders
      local projects=()
      while IFS= read -r line; do
        [[ -n "$line" ]] && projects+=("$line")
      done < "$project_file"
      
      echo "Project Management:"
      echo "1: Add current folder as a project"
      echo "2: Delete a project folder"
      read -p "Choose an option (1 or 2): " edit_option
      
      case $edit_option in
        1)
          local current_dir="$(pwd)"
          if grep -q "^$(printf '%s\n' "$current_dir" | sed 's/[[\.*^$/]/\\&/g')$" "$project_file" 2>/dev/null; then
            echo "This folder is already saved as a project."
          else
            echo "$current_dir" >> "$project_file"
            echo "Added: $current_dir"
          fi
          ;;
        2)
          if [[ ${#projects[@]} -eq 0 ]]; then
            echo "No saved project folders to delete."
            return 1
          fi
          
          echo "Saved projects:"
          for ((i=0; i<${#projects[@]}; i++)); do
            echo "$((i+1)): ${projects[$i]}"
          done
          echo ""
          
          read -p "Enter the number of the project to delete: " del_choice
          if [[ $del_choice =~ ^[0-9]+$ ]] && (( del_choice > 0 && del_choice <= ${#projects[@]} )); then
            local to_delete="${projects[$((del_choice-1))]}"
            grep -v "^$(printf '%s\n' "$to_delete" | sed 's/[[\.*^$/]/\\&/g')$" "$project_file" > "${project_file}.tmp"
            mv "${project_file}.tmp" "$project_file"
            echo "Deleted: $to_delete"
          else
            echo "Invalid choice."
            return 1
          fi
          ;;
        *)
          echo "Invalid option."
          return 1
          ;;
      esac
      ;;
    *)
      echo "Invalid option."
      return 1
      ;;
  esac
}


