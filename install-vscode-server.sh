#!/bin/bash
set -e

# Create the target directory
mkdir -p ~/.vscode-server/bin

# Download and execute the installation script
wget -O- https://aka.ms/install-vscode-server/setup.sh | sh
