
function hjelp() {
  # @desc Display all aliases and functions with their descriptions
  local OPTIND=1
  local search_term=""
  local verbose=0
  
  # Parse options
  while getopts ":s:vh" opt; do
    case "$opt" in
      s) search_term="$OPTARG" ;;
      v) verbose=1 ;;
      h)
        cat <<'EOF'
hjelp - Display bash functions and aliases with descriptions

Usage:
  hjelp           Show all aliases and functions
  hjelp -s term   Search for specific term
  hjelp -v        Verbose mode (show file locations)
  hjelp -h        Show this help

Function Documentation Format:
  Functions should use one of these comment styles:

  Style 1 (Recommended):
    function name() {
      # @desc Description of what this function does
      ...
    }

  Style 2 (Alternative):
    function name() {
      # Description of what this function does (first line only)
      ...
    }

  Aliases are automatically documented with their commands.
EOF
        return 0
        ;;
      ?) echo "Unknown option: -$OPTARG (use -h for help)"; return 1 ;;
    esac
  done
  shift $((OPTIND-1))
  
  # Get all sourced files from bashrc to search for functions
  local sourced_files=()
  while IFS= read -r line; do
    if [[ "$line" =~ ^source\ \"(.*)\" ]]; then
      local file="${BASH_REMATCH[1]}"
      if [[ -f "$file" ]]; then
        sourced_files+=("$file")
      fi
    fi
  done < <(grep -A 100 "# Sourced from setup.sh" "${HOME}/.bashrc" 2>/dev/null)
  
  # === ALIASES ===
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║                         ALIASES                            ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
  
  local alias_count=0
  while IFS= read -r line; do
    local alias_name=$(echo "$line" | awk -F"=" '{print $1}' | sed 's/^alias //')
    local alias_cmd=$(echo "$line" | awk -F"=" '{print $2}' | sed "s/^'//;s/'$//")
    
    # Apply search filter if specified
    if [[ -n "$search_term" ]]; then
      if [[ ! "$alias_name" =~ $search_term ]] && [[ ! "$alias_cmd" =~ $search_term ]]; then
        continue
      fi
    fi
    
    printf "  %-20s → %s\n" "$alias_name" "$alias_cmd"
    ((alias_count++))
  done < <(alias | sort)
  
  if [[ $alias_count -eq 0 ]]; then
    echo "  (no aliases found)"
  fi
  
  # === FUNCTIONS ===
  echo ""
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║                        FUNCTIONS                           ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
  
  # Build a single index of all functions from all files at once (much faster!)
  declare -A func_descriptions
  declare -A func_locations
  
  for file in "${sourced_files[@]}"; do
    # Read the entire file once and parse it in bash - much faster than multiple sed calls
    local in_function=""
    local looking_for_desc=0
    
    while IFS= read -r line; do
      # Check if this is a function definition
      if [[ "$line" =~ ^function\ ([a-zA-Z_][a-zA-Z0-9_]*)\(\) ]] || [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\(\) ]]; then
        in_function="${BASH_REMATCH[1]}"
        
        # Skip if already found (first occurrence wins)
        if [[ -z "${func_descriptions[$in_function]}" ]]; then
          looking_for_desc=5  # Look for description in next 5 lines
          func_locations["$in_function"]="$file"
        else
          in_function=""
        fi
        
      # If we're looking for a description
      elif [[ $looking_for_desc -gt 0 && -n "$in_function" ]]; then
        # Check if it's a comment line
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*@desc[[:space:]]*(.*) ]]; then
          # Found @desc tag
          func_descriptions["$in_function"]="${BASH_REMATCH[1]}"
          in_function=""
          looking_for_desc=0
        elif [[ "$line" =~ ^[[:space:]]*#[[:space:]]+(.*) ]]; then
          # Found a regular comment (only use if no description yet)
          if [[ -z "${func_descriptions[$in_function]}" ]]; then
            local comment="${BASH_REMATCH[1]}"
            # Skip empty comments or those starting with @
            if [[ -n "$comment" && ! "$comment" =~ ^@ ]]; then
              func_descriptions["$in_function"]="$comment"
              in_function=""
              looking_for_desc=0
            fi
          fi
        elif [[ ! "$line" =~ ^[[:space:]]*# ]]; then
          # Hit non-comment line, stop looking
          if [[ -z "${func_descriptions[$in_function]}" ]]; then
            func_descriptions["$in_function"]="(no description)"
          fi
          in_function=""
          looking_for_desc=0
        fi
        
        ((looking_for_desc--))
      fi
    done < "$file"
  done
  
  # Get all function names and display them
  local function_list=($(compgen -A function | grep -v "^_" | sort))
  local func_count=0
  
  for func in "${function_list[@]}"; do
    local description="${func_descriptions[$func]}"
    local file_location="${func_locations[$func]}"
    
    # Default description if none found
    if [[ -z "$description" ]]; then
      description="(no description)"
    fi
    
    # Apply search filter if specified
    if [[ -n "$search_term" ]]; then
      if [[ ! "$func" =~ $search_term ]] && [[ ! "$description" =~ $search_term ]]; then
        continue
      fi
    fi
    
    # Display the function
    if [[ $verbose -eq 1 && -n "$file_location" ]]; then
      printf "  %-20s %s\n" "$func" "$description"
      printf "  %-20s   ↳ %s\n" "" "$(basename "$file_location")"
    else
      printf "  %-20s %s\n" "$func" "$description"
    fi
    
    ((func_count++))
  done
  
  if [[ $func_count -eq 0 ]]; then
    echo "  (no functions found)"
  fi
  
  # Summary
  echo ""
  echo "──────────────────────────────────────────────────────────────"
  echo "Total: $alias_count aliases, $func_count functions"
  
  if [[ -n "$search_term" ]]; then
    echo "Filtered by: '$search_term'"
  fi
  
  echo ""
  echo "Tip: Use 'hjelp -s <term>' to search, 'hjelp -v' for verbose mode"
}