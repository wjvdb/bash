function setdescription() {
  # Set a description for a function to display in hjelp
  local desc_file="${HOME}/.function_descriptions"
  
  # Create file if it doesn't exist
  [[ -f "$desc_file" ]] || : > "$desc_file"
  
  # Get list of all functions
  local function_list=($(compgen -A function | grep -v "^_" | sort))
  
  if [[ ${#function_list[@]} -eq 0 ]]; then
    echo "No functions found."
    return 1
  fi
  
  # Display functions
  echo "Available functions:"
  for ((i=0; i<${#function_list[@]}; i++)); do
    local func="${function_list[$i]}"
    local existing_desc=$(grep "^${func}:" "$desc_file" 2>/dev/null | cut -d':' -f2-)
    if [[ -n "$existing_desc" ]]; then
      printf "%2d: %-20s [%s]\n" "$((i+1))" "$func" "$existing_desc"
    else
      printf "%2d: %-20s\n" "$((i+1))" "$func"
    fi
  done
  echo ""
  
  # Prompt for function selection
  read -p "Enter the number of the function to add/update description: " choice
  
  if [[ ! $choice =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#function_list[@]} )); then
    echo "Invalid choice."
    return 1
  fi
  
  local func_name="${function_list[$((choice-1))]}"
  
  # Prompt for description
  read -p "Enter description for '$func_name': " description
  
  if [[ -z "$description" ]]; then
    echo "Description cannot be empty."
    return 1
  fi
  
  # Remove existing entry for this function
  if grep -q "^${func_name}:" "$desc_file" 2>/dev/null; then
    local tmp
    tmp=$(mktemp) || return 1
    grep -v "^${func_name}:" "$desc_file" > "$tmp" && mv "$tmp" "$desc_file"
  fi
  
  # Add new description
  echo "${func_name}:${description}" >> "$desc_file"
  echo "Description set for '$func_name': $description"
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
  local desc_file="${HOME}/.function_descriptions"
  
  for func in $function_list; do
    local comment=""
    
    # First, try to get description from the description file
    if [[ -f "$desc_file" ]]; then
      comment=$(grep "^${func}:" "$desc_file" 2>/dev/null | cut -d':' -f2-)
    fi
    
    # If not found, extract the comment from the first line after function declaration
    if [[ -z "$comment" ]]; then
      comment=$(sed -n "/^function $func()/,/^}/p" "$BASH_SOURCE" | sed -n '2p' | sed 's/^[[:space:]]*#[[:space:]]*//;s/^[[:space:]]*//')
    fi
    
    if [[ -z "$comment" ]]; then
      comment="No description"
    fi
    
    printf "%-15s %s\n" "$func" "$comment"
  done
}