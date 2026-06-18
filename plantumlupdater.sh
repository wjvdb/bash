#!/bin/bash

# Download the latest PlantUML JAR from git to /c/
download_plantuml() {
    local jar_url="https://github.com/plantuml/plantuml/releases/latest/download/plantuml.jar"
    local target_file="/c/plantuml.jar"
    
    echo "Downloading PlantUML JAR..."
    curl -L "$jar_url" -o "$target_file"
    
    if [ $? -eq 0 ]; then
        echo "PlantUML JAR downloaded successfully to $target_file"
    else
        echo "Error downloading PlantUML JAR"
        return 1
    fi
}



