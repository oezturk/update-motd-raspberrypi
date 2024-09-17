#!/bin/bash

# Define source and target directories
SOURCE_MOTD_DIR="$(realpath ./update-motd.d)"
TARGET_MOTD_DIR="/etc/update-motd.d"

color() {
    echo -e "\e[$1m$2\e[0m"
}

# Color
directory="3;33" # Italic Yellow
process="3;37"   # Light Gray
error="91"       # Red

# Function to prompt for sudo permission
check_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script requires elevated permissions to modify system files in $(color $directory \"$TARGET_MOTD_DIR\")"
        echo "Please run this script with '$(color 1 sudo)' or as the $(color 1 root user)."
        exit 1
    fi
}

# Function to prompt for confirmation
prompt_confirm() {
    read -p "$(color 1 '::') $1 [Y/n]: " yn
    case $yn in
        [Yy]* | "") return 0;; # Default to 'Yes' if no input
        [Nn]* ) return 1;;
        * ) echo "Please answer 'y' or 'n'.";;
    esac
}

# Function to handle errors
error_exit() {
    echo "$(color $error E:) $1" >&2
    exit 1
}

# Check for sudo permissions
check_sudo

# Check if the source directory exists
[ -d "$SOURCE_MOTD_DIR" ] || error_exit "Source directory \"$SOURCE_MOTD_DIR\" does not exist."

# Prompt for confirmation to delete existing files
echo "This script will install new files to $(color $directory \"$TARGET_MOTD_DIR\")."
if prompt_confirm "Do you wish to continue?"; then
    echo "$(color $process "Proceeding with installation...")"

    # Backup existing MOTD directory if not empty
    if [ "$(find "$TARGET_MOTD_DIR" -mindepth 1 -print -quit 2>/dev/null)" ]; then
        if prompt_confirm "Do you wish to backup older \"$TARGET_MOTD_DIR\"?"; then
            echo "$(color $process "Backing up existing files to \e[4m\"$TARGET_MOTD_DIR.bak\"")"
            rm -rf "$TARGET_MOTD_DIR.bak"
            cp -r "$TARGET_MOTD_DIR" "$TARGET_MOTD_DIR.bak" || error_exit "Failed to backup \"$TARGET_MOTD_DIR\"."
        fi
    fi

    # Clear the target directory
    rm -rf "$TARGET_MOTD_DIR"/* || error_exit "Failed to delete files in \"$TARGET_MOTD_DIR\"."

    # Create the target directory if it doesn't exist
    mkdir -p "$TARGET_MOTD_DIR" || error_exit "Failed to create \"$TARGET_MOTD_DIR\"."

    # Copy files from source to target
    cp -r "$SOURCE_MOTD_DIR/"* "$TARGET_MOTD_DIR/" || error_exit "Failed to copy files to \"$TARGET_MOTD_DIR\"."

    # Set file permissions for scripts and themes
    find "$TARGET_MOTD_DIR" -type f -name '*-*' -exec chmod +x {} \; || error_exit "Failed to set executable permissions for the scripts."
    find "$TARGET_MOTD_DIR/themes" -type f -exec chmod +r {} \; || error_exit "Failed to set readable permissions for the themes."

    echo "Installation successful."
else
    echo "Operation cancelled by the user."
    exit 0
fi
