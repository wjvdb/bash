alias derkje='git log --graph --decorate --pretty=oneline --abbrev-commit'
alias gs='git status' 
alias esc='vim ~/.bashrc' 
alias exc='esc' 
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
 alias refrsh="source ~/.bashrc" 
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


alias gasoline="rm -rf *" 
alias ets="et; pp" 
alias etgs='et;gs' 


function inject() {
local bashrc_file="$HOME/.bashrc"
 local bashfile_path="$(realpath "$0")"
local source_command="source $bashfile_path"

# Check if the source command is already in .bashrc
if ! grep -Fxq "$source_command" "$bashrc_file"; then
 echo "$source_command" >> "$bashrc_file"
 echo "Added $bashfile_path to $bashrc_file"
refrsh
else
 echo "$bashfile_path is already sourced in $bashrc_file"
fi
}
inject