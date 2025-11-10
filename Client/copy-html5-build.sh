#!/bin/bash
# Post-build script to copy HTML5 build output to server static directory

echo -e "\033[32mCopying HTML5 build to server static/client directory...\033[0m"

SOURCE_DIR="Export/html5/bin"
DEST_DIR="../Server/static/client"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "\033[31mError: Source directory '$SOURCE_DIR' not found!\033[0m"
    exit 1
fi

# Create destination directory if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
    echo -e "\033[33mCreating destination directory: $DEST_DIR\033[0m"
    mkdir -p "$DEST_DIR"
fi

# Copy files
if cp -r "$SOURCE_DIR"/* "$DEST_DIR"/; then
    echo -e "\033[32mSuccessfully copied HTML5 build to $DEST_DIR\033[0m"
else
    echo -e "\033[31mError copying files\033[0m"
    exit 1
fi
