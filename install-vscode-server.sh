#!/bin/bash
set -e

# Configuration variables
VSCODE_COMMIT_ID="441438abd1ac652551dbe4d408dfcec8a499b8bf"  # From VS Code 1.92 (July 2025)
SERVER_USER=$(whoami)

echo "Starting VS Code Server installation for Ubuntu..."

# Install dependencies
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y openssh-server build-essential libssl-dev \
    ca-certificates curl wget tar gnupg lsb-release libstdc++6 python3 git

# Configure SSH server if needed
if [ -f /etc/ssh/sshd_config ]; then
    # Create backup of original config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)
    
    # Add or update necessary settings
    sudo grep -q "^AllowTcpForwarding" /etc/ssh/sshd_config && \
        sudo sed -i 's/^AllowTcpForwarding.*/AllowTcpForwarding yes/' /etc/ssh/sshd_config || \
        echo "AllowTcpForwarding yes" | sudo tee -a /etc/ssh/sshd_config

    sudo grep -q "^AllowStreamLocalForwarding" /etc/ssh/sshd_config && \
        sudo sed -i 's/^AllowStreamLocalForwarding.*/AllowStreamLocalForwarding yes/' /etc/ssh/sshd_config || \
        echo "AllowStreamLocalForwarding yes" | sudo tee -a /etc/ssh/sshd_config
        
    sudo grep -q "^ClientAliveInterval" /etc/ssh/sshd_config && \
        sudo sed -i 's/^ClientAliveInterval.*/ClientAliveInterval 60/' /etc/ssh/sshd_config || \
        echo "ClientAliveInterval 60" | sudo tee -a /etc/ssh/sshd_config
        
    sudo grep -q "^ClientAliveCountMax" /etc/ssh/sshd_config && \
        sudo sed -i 's/^ClientAliveCountMax.*/ClientAliveCountMax 3/' /etc/ssh/sshd_config || \
        echo "ClientAliveCountMax 3" | sudo tee -a /etc/ssh/sshd_config
        
    # Restart SSH service
    sudo systemctl restart sshd
    sudo systemctl enable sshd
fi

# Set up SSH directory permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Install specific VS Code Server version
echo "Installing VS Code Server version: $VSCODE_COMMIT_ID"

# Clean up any existing installation
rm -rf ~/.vscode-server/bin/$VSCODE_COMMIT_ID

# Create the directory structure
mkdir -p ~/.vscode-server/bin/$VSCODE_COMMIT_ID

# Download specific server version
wget -O vscode-server.tar.gz https://update.code.visualstudio.com/commit:${VSCODE_COMMIT_ID}/server-linux-x64/stable

# Calculate and store checksum for verification
sha256sum vscode-server.tar.gz > ~/.vscode-server/bin/$VSCODE_COMMIT_ID/checksum.sha256

# Extract the server
tar -xzf vscode-server.tar.gz -C ~/.vscode-server/bin/$VSCODE_COMMIT_ID --strip-components 1

# Create the initialization marker file
touch ~/.vscode-server/bin/$VSCODE_COMMIT_ID/0

# Clean up
rm vscode-server.tar.gz

# Create environment setup file
cat > ~/.vscode-server/server-env-setup <<EOL
# Custom environment variables for VS Code Server
export PATH=/usr/local/bin:$PATH
export LANG=en_US.UTF-8
EOL

# Configure firewall if needed
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow ssh
    sudo ufw --force enable
fi

echo "Installation complete! VS Code Server version $VSCODE_COMMIT_ID is ready."
echo "For client setup, add this host to your VS Code Remote SSH configuration."
