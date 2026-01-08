#!/bin/bash
# Install required penetration testing tools

export DEBIAN_FRONTEND=noninteractive

echo "Updating package lists..."
apt-get update -qq

echo "Installing required packages..."
apt-get install -y -qq \
    metasploit-framework \
    postgresql \
    python3 \
    python3-pip \
    nmap \
    netcat-traditional \
    curl \
    wget \
    vim \
    tmux

# Initialize Metasploit database
echo "Initializing Metasploit database..."
msfdb init
systemctl enable postgresql
systemctl start postgresql

# Create Metasploit workspace
echo "Creating Metasploit workspace..."
sudo -u vagrant bash << 'EOF'
msfconsole -q -x "workspace -a pdf_exploit_lab; exit" > /dev/null 2>&1
EOF

echo "✓ Tools installed successfully"
