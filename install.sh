#!/bin/bash

# Function to prompt for sudo permission
check_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script requires elevated permissions to modify system files in /etc/update-motd.d/"
        echo "Please run this script with 'sudo' or as the root user."
        exit 1
    fi
}

# Function to prompt for confirmation
prompt_confirm() {
    while true; do
        read -p "$1 [y/n]: " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer 'y' or 'n'.";;
        esac
    done
}

# Function to handle errors
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Check for sudo permissions
check_sudo

# Define source and target directories
SOURCE_MOTD_DIR="$(realpath ./update-motd.d)"
TARGET_MOTD_DIR="/etc/update-motd.d"

# Check if the source directory exists
[ -d "$SOURCE_MOTD_DIR" ] || error_exit "Source directory $SOURCE_MOTD_DIR does not exist."

# Prompt for confirmation to delete existing files
echo "This script will backup and delete all files in $TARGET_MOTD_DIR and install new files from $SOURCE_MOTD_DIR."
if prompt_confirm "Do you wish to continue?"; then
    echo "Proceeding with installation..."

    # Backup existing MOTD directory if not empty
    if [ "$(find "$TARGET_MOTD_DIR" -mindepth 1 -print -quit 2>/dev/null)" ]; then
        echo "Backing up existing files in $TARGET_MOTD_DIR to $TARGET_MOTD_DIR.bak"
        cp -r "$TARGET_MOTD_DIR" "$TARGET_MOTD_DIR.bak" || error_exit "Failed to backup $TARGET_MOTD_DIR."
    fi

    # Clear the target directory
    rm -rf "$TARGET_MOTD_DIR"/* || error_exit "Failed to delete files in $TARGET_MOTD_DIR."

    # Create the target directory if it doesn't exist
    mkdir -p "$TARGET_MOTD_DIR" || error_exit "Failed to create $TARGET_MOTD_DIR."

    # Copy files from source to target
    cp -r "$SOURCE_MOTD_DIR/"* "$TARGET_MOTD_DIR/" || error_exit "Failed to copy files to $TARGET_MOTD_DIR."

    # Set file permissions for all scripts and themes
    for file in "$TARGET_MOTD_DIR"/*; do
        if [[ "$file" == *theme* ]]; then
            chmod +r "$file" || echo "Failed to set readable permission for $file."
        else
            chmod +x "$file" || echo "Failed to set executable permission for $file."
        fi
    done

    echo "Files have been successfully copied to $TARGET_MOTD_DIR and permissions set."
else
    echo "Operation cancelled by the user."
    exit 0
fi
