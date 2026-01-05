#!/bin/bash

# Function to delete changes made by setup.sh
delete_setup_changes() {
  BASHRC="${HOME}/.bashrc"
  
  # Check if bashrc exists
  if [[ ! -f "$BASHRC" ]]; then
    echo "No .bashrc file found at $BASHRC"
    return 1
  fi
  
  # Create a temporary file
  local temp_file=$(mktemp)
  
  # Remove lines added by setup.sh
  # This removes the comment line and all subsequent 'source' lines from the script directory
  sed '/# Sourced from setup.sh/,/^$/d' "$BASHRC" > "$temp_file"
  
  # Replace the original bashrc with the modified version
  if mv "$temp_file" "$BASHRC"; then
    echo "Successfully removed setup.sh sourced files from $BASHRC"
    return 0
  else
    echo "Failed to update $BASHRC"
    rm -f "$temp_file"
    return 1
  fi
}

# Run the function if script is executed
delete_setup_changes
