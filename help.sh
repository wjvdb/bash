
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
  
  # Add current script to search path
  if [[ -f "$BASH_SOURCE" ]]; then
    sourced_files+=("$BASH_SOURCE")
  fi
  
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
  
  # Get all function names
  local function_list=($(compgen -A function | grep -v "^_" | sort))
  local func_count=0
  
  for func in "${function_list[@]}"; do
    local description=""
    local file_location=""
    
    # Search for function definition in sourced files
    for file in "${sourced_files[@]}"; do
      # Look for function definition
      if grep -q "^function ${func}()" "$file" 2>/dev/null || \
         grep -q "^${func}()" "$file" 2>/dev/null; then
        
        file_location="$file"
        
        # Extract description using multiple methods:
        
        # Method 1: Look for @desc tag (preferred)
        description=$(sed -n "/^function ${func}()/,/^}/p" "$file" 2>/dev/null | \
                      grep -m 1 "^[[:space:]]*#[[:space:]]*@desc" | \
                      sed 's/^[[:space:]]*#[[:space:]]*@desc[[:space:]]*//')
        
        # Method 2: If no @desc, look for # comment on same line as function
        if [[ -z "$description" ]]; then
          description=$(grep "^function ${func}()" "$file" 2>/dev/null | \
                       sed 's/.*#[[:space:]]*//')
        fi
        
        # Method 3: Look for first comment line after function declaration
        if [[ -z "$description" ]]; then
          description=$(sed -n "/^function ${func}()/,/^}/p" "$file" 2>/dev/null | \
                       sed -n '2p' | \
                       grep "^[[:space:]]*#" | \
                       sed 's/^[[:space:]]*#[[:space:]]*//' | \
                       sed 's/@desc[[:space:]]*//')
        fi
        
        # Method 4: Try without 'function' keyword
        if [[ -z "$description" ]]; then
          description=$(sed -n "/^${func}()/,/^}/p" "$file" 2>/dev/null | \
                       sed -n '2p' | \
                       grep "^[[:space:]]*#" | \
                       sed 's/^[[:space:]]*#[[:space:]]*//')
        fi
        
        break
      fi
    done
    
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