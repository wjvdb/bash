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

function unfuck() {
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
  if [ -z "$1" ]; then
    echo "Usage: newbranch <branch-name>"
    return 1
  fi

  git checkout -b "$1" && git push -u origin "$1"
}
