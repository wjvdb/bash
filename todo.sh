
# Simple interactive TODO function
todo() {
  # Config: file location (override with: export TODO_FILE="path")
  local TODO_FILE="${TODO_FILE:-$HOME/.todo.txt}"
  local RESET=$'\e[0m'
  local STRIKE=$'\e[9m'   # Strikethrough (works in most modern terminals)

  # Ensure file exists
  [[ -f "$TODO_FILE" ]] || : > "$TODO_FILE"

  # --- helpers ---
  show_list() {
    if [[ ! -s "$TODO_FILE" ]]; then
      echo "No todos yet. Add one with: todo -a \"Your task\""
      return 1
    fi
    local i=0 status text
    while IFS= read -r line; do
      ((i++))
      status="${line%%|*}"   # 0 or 1
      text="${line#*|}"
      if [[ "$status" == "1" ]]; then
        # show as checked + strikethrough
        printf "%2d. [x] %b%s%b\n" "$i" "$STRIKE" "$text" "$RESET"
      else
        printf "%2d. [ ] %s\n" "$i" "$text"
      fi
    done < "$TODO_FILE"
    return 0
  }

  toggle_item() {
    local n="$1"
    mapfile -t lines < "$TODO_FILE"
    if (( n < 1 || n > ${#lines[@]} )); then
      echo "Invalid number: $n"
      return 1
    fi
    local line="${lines[n-1]}"
    local status="${line%%|*}"
    local text="${line#*|}"
    [[ "$status" == "1" ]] && status=0 || status=1
    lines[n-1]="$status|$text"
    printf "%s\n" "${lines[@]}" > "$TODO_FILE"
  }

  delete_items() {
    # Delete by numbers; supports multiple numbers
    local nums=("$@")
    if [[ "${#nums[@]}" -eq 0 ]]; then
      read -rp "Delete number(s) (e.g., 1 3 5): " -a nums
    fi
    [[ "${#nums[@]}" -eq 0 ]] && { echo "Nothing deleted."; return; }

    # Build a space-delimited set " 1 3 5 "
    local delset=" "
    for n in "${nums[@]}"; do
      [[ "$n" =~ ^[0-9]+$ ]] && delset+=" $n "
    done

    mapfile -t lines < "$TODO_FILE"
    : > "$TODO_FILE"
    local i=1
    for line in "${lines[@]}"; do
      if [[ "$delset" != *" $i "* ]]; then
        echo "$line" >> "$TODO_FILE"
      fi
      ((i++))
    done
    echo "Deleted: ${nums[*]}"
  }

  print_help() {
    cat <<'EOF'
Usage:
  todo -a "task"     Add a new task
  todo               Show list; type number+Enter to toggle done/undone; Enter to quit
  todo -e [nums...]  Delete item(s) permanently (interactive if no numbers)
  todo -h            Show this help

Notes:
  • Data file: ~/.todo.txt (override with: export TODO_FILE="/path/to/file")
  • Toggling: entering the same number again will undo the strikethrough
  • Deleting: supports multiple numbers (e.g., todo -e 2 5)
EOF
  }

  # --- main ---
  case "$1" in
    -a)
      shift
      local item="$*"
      if [[ -z "$item" ]]; then
        read -rp "Add item: " item
      fi
      if [[ -z "$item" ]]; then
        echo "Nothing to add."
        return 1
      fi
      printf "0|%s\n" "$item" >> "$TODO_FILE"
      echo "Added: $item"
      ;;
    -e)
      shift
      show_list || return 0
      if [[ $# -gt 0 ]]; then
        delete_items "$@"
      else
        delete_items
      fi
      ;;
    -h|--help)
      print_help
      ;;
    ""|*)
      # Show + interactive toggle
      show_list || return 0
      while true; do
        read -rp "Toggle number (Enter to quit, or 'q' to quit): " n
        [[ -z "$n" || "$n" == "q" || "$n" == "Q" ]] && break
        if [[ "$n" =~ ^[0-9]+$ ]]; then
          toggle_item "$n"
          show_list
        else
          echo "Please enter a valid number."
        fi
      done
      ;;
  esac
}
