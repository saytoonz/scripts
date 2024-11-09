#!/bin/bash

# Configuration variables
SCRIPT_NAME="burn_image.sh"
REPO_URL="https://github.com/saytoonz/scripts.git"
SCRIPT_PATH="/usr/local/bin"
REPO_PATH="/tmp/scripts"

# Check if git is installed
if ! command -v git &> /dev/null; then
  echo "Git is not installed. Installing..."
  sudo apt-get update
  sudo apt-get install git -y
fi

# Check if script file exists locally
if [ -d "$REPO_PATH" ]; then
  echo "Repository already cloned. Updating..."
  cd "$REPO_PATH"
  git pull
  cp "$REPO_PATH/$SCRIPT_NAME" .
else
  echo "Script file not found. Cloning repository from GitHub..."
  git clone "$REPO_URL" "$REPO_PATH"
  cp "$REPO_PATH/$SCRIPT_NAME" .
fi

# Check if script file already exists in $SCRIPT_PATH
if [ -f "$SCRIPT_PATH/$SCRIPT_NAME" ]; then
  echo "Script file already exists in $SCRIPT_PATH. Overwriting..."
  sudo rm "$SCRIPT_PATH/$SCRIPT_NAME"
  sudo cp "$SCRIPT_NAME" "$SCRIPT_PATH"
  sudo rm "$SCRIPT_NAME"
else
  echo "Copying script file to $SCRIPT_PATH..."
  sudo cp "$SCRIPT_NAME" "$SCRIPT_PATH"
  sudo rm "$SCRIPT_NAME"
fi

# Change ownership and permissions
sudo chown root:root "$SCRIPT_PATH/$SCRIPT_NAME"
sudo chmod 755 "$SCRIPT_PATH/$SCRIPT_NAME"

# Check if script is already in PATH
if grep -q "$SCRIPT_PATH" /etc/profile || grep -q "$SCRIPT_PATH" ~/.bashrc; then
  echo "Script is already in PATH. Skipping..."
else
  # Add script to system's PATH
  if [ -f "/etc/profile" ]; then
    sudo echo "export PATH=$PATH:$SCRIPT_PATH" >> /etc/profile
  else
    sudo echo "export PATH=$PATH:$SCRIPT_PATH" >> ~/.bashrc
  fi
  echo "Script added to PATH."
fi

# Rename script to saytoonz
sudo mv "$SCRIPT_PATH/$SCRIPT_NAME" "$SCRIPT_PATH/saytoonz"

# Remove temporary repository directory
sudo rm -rf "$REPO_PATH"

echo "Script installed and configured successfully!"