#!/bin/bash

# Download the latest PlantUML from git to /c/
download_plantuml() {
    local repo_url="https://github.com/plantuml/plantuml.git"
    local target_dir="/c/plantuml"
    
    if [ -d "$target_dir" ]; then
        echo "Updating existing PlantUML repository..."
        cd "$target_dir" || exit 1
        git pull origin master
    else
        echo "Cloning PlantUML repository..."
        git clone "$repo_url" "$target_dir"
    fi
    
    if [ $? -eq 0 ]; then
        echo "PlantUML download/update completed successfully at $target_dir"
    else
        echo "Error downloading/updating PlantUML"
        return 1
    fi
}



