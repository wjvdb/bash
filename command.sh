alias gasoline="rm -rf *" 
alias ets="et; pp" 
alias etgs='et;gs' 
alias refrsh="source ~/.bashrc" 
alias derkje='git log --graph --decorate --pretty=oneline --abbrev-commit'
alias gs='git status' 
alias esc='vim ~/.bashrc' 
alias exc='esc'
alias sjow='explorer.exe .'
alias gp='git push origin HEAD'
alias gc='git commit' 
alias gcm='git commit -m'
alias gca='git add . && git commit -a -m'
alias gac='git add . && git commit -a'
alias gaa='git add .' 
alias gau='git add --all' 
alias ga='git add .' 
alias gau='git add --all' 



function pp { 
  num=${1:-1} 
  while [ $num -ne 0 ]; do 
    cd .. 
    num=$((num-1)) 
  done 
} 
alias portal='cd ~' 
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
function sfse_old(){
  local search_term="$1" 
  local search_path="${2:-.}" 
  local results=($(find "$search_path" -type f -name "*$search_term*" 2>/dev/null)) 
  if [[ ${#results[@]} -eq 1 ]]; then 
    explorer.exe "${results[0]}" 
  else 
    for result in "${results[@]}"; do 
      echo "$result" 
    done 
  fi 
}

function sfse(){
  local search_term="$1" 
  local search_path="${2:-.}" 

  # Check if search_term and search_path are provided
  if [[ -z "$search_term" || -z "$search_path" ]]; then
    echo "Usage: sfse <search_term> [search_path]"
    return 1
  fi

  local results=($(find "$search_path" -type f -name "*$search_term*" 2>/dev/null)) 

  if [[ ${#results[@]} -eq 0 ]]; then 
    echo "No files found."
  elif [[ ${#results[@]} -eq 1 ]]; then 
    # Try to open the file in a graphical viewer if possible
    if command -v explorer &> /dev/null; then
      explorer.exe "${results[0]}" 
    else
      echo "File found: ${results[0]}"
      # If no explorer, you can use other methods like cat for text files or open for GUI-based editors
    fi
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



function inject() {
local bashrc_file="$HOME/.bashrc"
 local bashfile_path="$(realpath "$0")"
local source_command="source $bashfile_path"

# Check if the source command is already in .bashrc
if ! grep -Fxq "$source_command" "$bashrc_file"; then
 echo "$source_command" >> "$bashrc_file"
 echo "Added $bashfile_path to $bashrc_file"
 refrsh
fi
}
inject



function sfsd() {
  local search_term="$1"
  local file_extension="$2"

  # Check if search_term is provided
  if [[ -z "$search_term" ]]; then
    echo "Usage: gto <partial_file_name> [file_extension]"
    return 1
  fi

  local results=($(find . -type f -name "*$search_term*$file_extension" 2>/dev/null))

  if [[ ${#results[@]} -eq 0 ]]; then
    echo "No files found."
  elif [[ ${#results[@]} -eq 1 ]]; then
    cd "$(dirname "${results[0]}")"
  else
    for ((i=0; i<${#results[@]}; i++)); do
      echo "$((i+1)): $(basename "${results[i]}")"
    done

    read -p "Enter the number of the file you want to go to: " choice
    if [[ $choice =~ ^[0-9]+$ ]] && (( $choice > 0 && $choice <= ${#results[@]} )); then
      cd "$(dirname "${results[$((choice-1))]}")"
    else
      echo "Invalid choice."
    fi
  fi
}