#!/bin/bash

#!/bin/bash
# Git Tag Manager Script as a single function

git_tag_manager() {
    git fetch --tags
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
    if [ -z "$LAST_TAG" ]; then
        echo "No tags found in this repository."
    else
        echo "Last tag: $LAST_TAG"
    fi
    echo -n "Enter new tag name: "
    read NEW_TAG
    if [ -z "$NEW_TAG" ]; then
        echo "No tag name entered. Exiting."
        return 1
    fi
    git rev-parse "$NEW_TAG" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "Tag '$NEW_TAG' already exists. Exiting."
        return 1
    fi
    git tag "$NEW_TAG"
    if [ $? -eq 0 ]; then
        echo "Tag '$NEW_TAG' created successfully."
        echo "Pushing tag to origin..."
        git push origin "$NEW_TAG"
    else
        echo "Failed to create tag."
        return 1
    fi
}

# Call the function
git_tag_manager
