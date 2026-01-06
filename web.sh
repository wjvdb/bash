web() {
  # Manage saved websites: open or edit the list
  local OPTIND=1
  local website_file="${HOME}/.saved_websites"

  # Ensure website file exists
  [[ -f "$website_file" ]] || : > "$website_file"

  # --- Helpers ---
  # Regex-escape for exact line matches (grep -E / sed -E)
  esc() { sed -E 's/[][\.^$|?*+(){}\\]/\\&/g'; }

  # Load file into array (mapfile if available, fallback otherwise)
  _load_websites() {
    if command -v mapfile >/dev/null 2>&1; then
      mapfile -t websites < "$website_file"
    else
      websites=()
      while IFS= read -r line; do
        [[ -n "$line" ]] && websites+=("$line")
      done < "$website_file"
    fi
  }

  # Pretty list
  _print_list() {
    local -a arr=("$@")
    local i
    echo "Saved websites:"
    for ((i=0; i<${#arr[@]}; i++)); do
      local entry="${arr[$i]}"
      if [[ "$entry" =~ ^([^|]+)\|(.+)$ ]]; then
        printf "%2d: %s (%s)\n" "$((i+1))" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
      else
        printf "%2d: %s\n" "$((i+1))" "$entry"
      fi
    done
    echo ""
  }

  # Deduplicate file (sort -u)
  _dedupe_file() {
    local tmp
    tmp=$(mktemp) || return
    sort -u "$website_file" > "$tmp" && mv -- "$tmp" "$website_file"
  }

  # --- Actions ---
  _action_list_and_open() {
    local -a websites
    _load_websites
    if [[ ${#websites[@]} -eq 0 ]]; then
      echo "No saved websites found."
      return 1
    fi
    _print_list "${websites[@]}"
    read -r -p "Enter the number of the website to open: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice > 0 && choice <= ${#websites[@]} )); then
      local target="${websites[$((choice-1))]}"
      echo "Opening: $target"
      if command -v explorer.exe >/dev/null 2>&1; then
        explorer.exe "$target"
      elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$target"
      elif command -v open >/dev/null 2>&1; then
        open "$target"
      else
        echo "No browser command found. URL: $target"
      fi
    else
      echo "Invalid choice."
      return 1
    fi
  }

  _action_add_website() {
    read -r -p "Enter the website URL to add: " url
    if [[ -z "$url" ]]; then
      echo "URL cannot be empty."
      return 1
    fi
    if grep -q -E "^$(printf '%s' "$url" | esc)$" "$website_file"; then
      echo "This website is already saved."
    else
      printf '%s\n' "$url" >> "$website_file"
      _dedupe_file
      echo "Added: $url"
    fi
  }

  _action_edit_menu() {
    local -a websites
    _load_websites

    echo "Website Management:"
    echo "1: Add a website"
    echo "2: Delete a website"
    read -r -p "Choose an option (1 or 2): " edit_option

    case "$edit_option" in
      1) _action_add_website ;;
      2)
        if [[ ${#websites[@]} -eq 0 ]]; then
          echo "No saved websites to delete."
          return 1
        fi
        _print_list "${websites[@]}"
        read -r -p "Enter the number of the website to delete: " del_choice
        if [[ "$del_choice" =~ ^[0-9]+$ ]] && (( del_choice > 0 && del_choice <= ${#websites[@]} )); then
          local to_delete="${websites[$((del_choice-1))]}"
          local tmp
          tmp=$(mktemp) || { echo "mktemp failed"; return 1; }
          grep -v -E "^$(printf '%s' "$to_delete" | esc)$" "$website_file" > "$tmp"
          mv -- "$tmp" "$website_file"
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
Usage: web [-a] [-e] [-h]
  (no flags)  List websites and prompt to open one
  -a          Add a website to saved list
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
    _action_add_website
  elif (( do_edit )); then
    _action_edit_menu
  else
    _action_list_and_open
  fi
}
