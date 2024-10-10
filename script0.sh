#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Switching to root..."
   exec sudo bash "$0" "$@"
fi

# Commands to install required packages
apt install -y network-manager
apt install -y sudo

# User to add to sudoers
USER="pinaka"

# Sudoers file path
SUDOERS_FILE="/etc/sudoers.d/$USER"

# Check if the sudoers file already exists
if [[ -f "$SUDOERS_FILE" ]]; then
    echo "Sudoers file for $USER already exists"
else
    # Add the user to the sudoers file with NOPASSWD
    echo "$USER ALL=(ALL) NOPASSWD: ALL" > "$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
    echo "Sudoers file for $USER created successfully"
fi

# Exiting from root after tasks
echo "Tasks completed. Exiting from root..."
exit
