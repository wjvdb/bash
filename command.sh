alias gasoline="rm -rf *" 
alias ets="et; pp" 
alias etgs='et;gs' 
alias refrsh="source ~/.bashrc" 
alias esc='vim ~/.bashrc' 
alias exc='esc'
alias sjow='explorer.exe .'
alias portal='cd ~' 
function pp { 
  num=${1:-1} 
  while [ $num -ne 0 ]; do 
    cd .. 
    num=$((num-1)) 
  done 
} 

replace_in_files() { 
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

  if [ $# -lt 1 ]; then 
    echo "Usage: search_folder <word> [folder_path]" 
    return 1 
  fi 
  word="$1" 
  folder_path="${2:-$PWD}"  # Use current directory (PWD) if no folder_path provided 
  grep -r -i "$word" "$folder_path" 
} 
edir () { 

  mkdir -p "$1" && cd "$1" 

} 


function sfs() { 
  local search_term="$1" 
  local search_path="${2:-.}"  # Default to current directory if no path is given 
  find "$search_path" -type f -name "*$search_term*" 2>/dev/null || \ 
  find "$search_path" -type d -name "*$search_term*" 2>/dev/null 
} 
function sfsv() { 
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
  alias_list=$(alias | awk -F'=' '{print $1}')
  function_list=$(compgen -A function)

  echo "Aliases:"
  echo "$alias_list"

  echo "Functions:"
  echo "$function_list"
}

function list_files() {
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
  if [[ -n "$selected_file" ]]; then
    vim "$selected_file"
    unset selected_file
  else
    echo "No file selected."
  fi
}

function open_in_explorer() {
  local original_dir="$(pwd)"
  if [[ -n "$selected_file" ]]; then
    cd "$(dirname "$selected_file")"
    explorer.exe .
  fi
  cd "$original_dir"
}

function go_to_directory() {
  if [[ -n "$selected_file" ]]; then
    cd "$(dirname "$selected_file")"
  fi
}

function sfsd() {
  list_files "$@"
  if [[ $? -eq 0 ]]; then
    go_to_directory
  fi
}

function sfsv() {
  list_files "$@"
  if [[ $? -eq 0 ]]; then
    open_in_vim
  fi
}

function sfse() {
  list_files "$@"
  if [[ $? -eq 0 ]]; then
    open_in_explorer
  fi
}
function sex() {
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
  target="$1"
  find . -type d -name "$target" -exec dirname {} \; | sort -u
}



function search_in_files() {
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
  list_files "$@"

  if [[ -n "$selected_file" ]]; then
    echo "Launching $selected_file..."
    ./"$selected_file"  # Use './' to execute the file in the current directory
  else
    echo "No executable found."
  fi
}


lex() {
    input_file=$1
    word=$2
    output_file=${3:-"${word}.txt"}

    grep -i "$word" "$input_file" > "$output_file"
}

function Deportation() {
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
