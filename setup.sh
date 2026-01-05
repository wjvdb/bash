#!/bin/bash

# Script to select .sh files from this folder and add them as sources to bashrc

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="${HOME}/.bashrc"

# Find all .sh files in the current directory
shopt -s nullglob
sh_files=("${SCRIPT_DIR}"/*.sh)
shopt -u nullglob

# Filter out setup.sh itself
filtered_files=()
for file in "${sh_files[@]}"; do
  if [[ "$(basename "$file")" != "setup.sh" ]]; then
    filtered_files+=("$file")
  fi
done

# If no files found, exit
if [[ ${#filtered_files[@]} -eq 0 ]]; then
  echo "No .sh files found in $SCRIPT_DIR"
  exit 0
fi

# Display options and let user select
echo "Available .sh files in $SCRIPT_DIR:"
echo ""
for i in "${!filtered_files[@]}"; do
  echo "$((i+1))) $(basename "${filtered_files[$i]}")"
done
echo ""

# Get user selection
read -p "Select files to source (comma-separated numbers, or 'all' for all files): " selection

# Process selection
selected_files=()
exclude_files=()
if [[ "$selection" == "all" ]]; then
  selected_files=("${filtered_files[@]}")
else
  IFS=',' read -ra selections <<< "$selection"
  for sel in "${selections[@]}"; do
    sel=$(echo "$sel" | xargs) # trim whitespace
    if [[ "$sel" =~ ^!([0-9]+)$ ]]; then
      # Exclusion mode: !number
      num=${BASH_REMATCH[1]}
      if (( num >= 1 && num <= ${#filtered_files[@]} )); then
        exclude_files+=($((num-1)))
      fi
    elif [[ "$sel" =~ ^[0-9]+$ ]] && (( sel >= 1 && sel <= ${#filtered_files[@]} )); then
      selected_files+=("${filtered_files[$((sel-1))]}")
    fi
  done
  
  # If exclusions were specified, select all except excluded
  if [[ ${#exclude_files[@]} -gt 0 ]]; then
    selected_files=()
    for i in "${!filtered_files[@]}"; do
      if [[ ! " ${exclude_files[@]} " =~ " $i " ]]; then
        selected_files+=("${filtered_files[$i]}")
      fi
    done
  fi
fi

# Add sourcing commands to bashrc
if [[ ${#selected_files[@]} -gt 0 ]]; then
  echo "" >> "$BASHRC"
  echo "# Sourced from setup.sh" >> "$BASHRC"
  for file in "${selected_files[@]}"; do
    echo "source \"$file\"" >> "$BASHRC"
    echo "Added: $(basename "$file")"
  done
  echo "Setup complete! Added sources to $BASHRC"
else
  echo "No files selected."
fi
