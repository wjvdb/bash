proj() {
  # Manage saved project folders: open or edit the list
  local OPTIND=1
  local project_file="${HOME}/.project_folders"

  # Ensure project file exists
  [[ -f "$project_file" ]] || : > "$project_file"

  # --- Helpers ---
  # Regex-escape for exact line matches (grep -E / sed -E)
  esc() { sed -E 's/[][\.^$|?*+(){}\\]/\\&/g'; }

  # Load file into array (mapfile if available, fallback otherwise)
  _load_projects() {
    if command -v mapfile >/dev/null 2>&1; then
      mapfile -t projects < "$project_file"
    else
      projects=()
      while IFS= read -r line; do
        [[ -n "$line" ]] && projects+=("$line")
      done < "$project_file"
    fi
  }

  # Pretty list
  _print_list() {
    local -a arr=("$@")
    local i
    echo "Saved projects:"
    for ((i=0; i<${#arr[@]}; i++)); do
      printf "%2d: %s\n" "$((i+1))" "${arr[$i]}"
    done
    echo ""
  }

  # Normalize path to reduce duplicates
  _normpath() {
    local p="$1"
    if command -v realpath >/dev/null 2>&1; then
      realpath -m -- "$p"
    else
      p="${p%/}"
      case "$p" in
        /*) printf '%s\n' "$p" ;;
        *)  printf '%s\n' "$(pwd)/$p" ;;
      esac
    fi
  }

  # Deduplicate file (sort -u)
  _dedupe_file() {
    local tmp
    tmp=$(mktemp) || return
    sort -u "$project_file" > "$tmp" && mv -- "$tmp" "$project_file"
  }

  # --- Actions ---
  _action_list_and_open() {
    local -a projects
    _load_projects
    if [[ ${#projects[@]} -eq 0 ]]; then
      echo "No saved project folders found."
      return 1
    fi
    _print_list "${projects[@]}"
    read -r -p "Enter the number of the project to open: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice > 0 && choice <= ${#projects[@]} )); then
      local target="${projects[$((choice-1))]}"
      if [[ -d "$target" ]]; then
        cd -- "$target" || { echo "Failed to change directory."; return 1; }
        echo "Changed to: $(pwd)"
      else
        echo "Directory no longer exists: $target"
        return 1
      fi
    else
      echo "Invalid choice."
      return 1
    fi
  }

  _action_add_current() {
    local current_dir norm
    current_dir="$(pwd)"
    norm="$(_normpath "$current_dir")"
    if grep -q -E "^$(printf '%s' "$norm" | esc)$" "$project_file"; then
      echo "This folder is already saved as a project."
    else
      printf '%s\n' "$norm" >> "$project_file"
      _dedupe_file
      echo "Added: $norm"
    fi
  }

  _action_edit_menu() {
    local -a projects
    _load_projects

    echo "Project Management:"
    echo "1: Add current folder as a project"
    echo "2: Delete a project folder"
    read -r -p "Choose an option (1 or 2): " edit_option

    case "$edit_option" in
      1) _action_add_current ;;
      2)
        if [[ ${#projects[@]} -eq 0 ]]; then
          echo "No saved project folders to delete."
          return 1
        fi
        _print_list "${projects[@]}"
        read -r -p "Enter the number of the project to delete: " del_choice
        if [[ "$del_choice" =~ ^[0-9]+$ ]] && (( del_choice > 0 && del_choice <= ${#projects[@]} )); then
          local to_delete="${projects[$((del_choice-1))]}"
          local tmp
          tmp=$(mktemp) || { echo "mktemp failed"; return 1; }
          grep -v -E "^$(printf '%s' "$to_delete" | esc)$" "$project_file" > "$tmp"
          mv -- "$tmp" "$project_file"
          echo "Deleted: $to_delete"
        else
          echo "Invalid choice."
          return 1
        fi
        ;;
      *) echo "Invalid option."; return 1 ;;
    esac
  }

  _usage() {
    cat <<'EOF'
Usage: proj [-a] [-e] [-h]
  (no flags)  List projects and prompt to open one
  -a          Add current directory to saved projects
  -e          Open edit menu (add/delete)
  -h          Show help
EOF
  }

  # --- Parse flags ---
  local opt
  local do_add=0 do_edit=0
  while getopts ":aeh" opt; do
    case "$opt" in
      a) do_add=1 ;;
      e) do_edit=1 ;;
      h) _usage; return 0 ;;
      ?) echo "Unknown option: -$OPTARG"; _usage; return 1 ;;
    esac
  done
  shift $((OPTIND-1))

  # --- Dispatch ---
  if (( do_add )); then
    _action_add_current
  elif (( do_edit )); then
    _action_edit_menu
  else
    _action_list_and_open
  fi
}