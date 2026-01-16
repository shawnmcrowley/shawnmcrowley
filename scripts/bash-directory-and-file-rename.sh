#!/bin/bash

# Script to rename directories and files:
# - Convert uppercase to lowercase
# - Replace underscores with hyphens

# Check if a directory argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <directory>"
    echo "Example: $0 /path/to/directory"
    exit 1
fi

TARGET_DIR="$1"

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

# Function to rename a single item (file or directory)
rename_item() {
    local item="$1"
    local dir=$(dirname "$item")
    local base=$(basename "$item")
    
    # Convert to lowercase and replace underscores with hyphens
    local new_base=$(echo "$base" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
    
    # Only rename if the name actually changed
    if [ "$base" != "$new_base" ]; then
        local new_path="$dir/$new_base"
        
        # Check if target already exists
        if [ -e "$new_path" ] && [ "$item" != "$new_path" ]; then
            echo "Warning: Cannot rename '$item' to '$new_path' - target already exists"
        else
            mv "$item" "$new_path"
            echo "Renamed: $item -> $new_path"
        fi
    fi
}

# Process directories first (depth-first, bottom-up)
# This ensures we rename child directories before parent directories
find "$TARGET_DIR" -depth -type d | while read -r dir; do
    # Skip the root directory itself
    if [ "$dir" != "$TARGET_DIR" ]; then
        rename_item "$dir"
    fi
done

# Process files
find "$TARGET_DIR" -type f | while read -r file; do
    rename_item "$file"
done

echo "Renaming complete!"
