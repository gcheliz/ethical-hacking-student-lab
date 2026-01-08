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

# Start PostgreSQL service first
echo "Starting PostgreSQL service..."
systemctl enable postgresql
systemctl start postgresql

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
MAX_WAIT=30
WAIT_COUNT=0
until sudo -u postgres psql -c '\q' 2>/dev/null || [ $WAIT_COUNT -eq $MAX_WAIT ]; do
    echo "  Waiting for PostgreSQL... ($WAIT_COUNT/$MAX_WAIT)"
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [ $WAIT_COUNT -eq $MAX_WAIT ]; then
    echo "ERROR: PostgreSQL failed to start within ${MAX_WAIT} seconds"
    systemctl status postgresql
    exit 1
fi

echo "✓ PostgreSQL is ready"

# Now initialize Metasploit database
echo "Initializing Metasploit database..."
msfdb init

# Create Metasploit workspace
echo "Creating Metasploit workspace..."
sudo -u vagrant bash << 'EOF'
msfconsole -q -x "workspace -a pdf_exploit_lab; exit" > /dev/null 2>&1
EOF

echo "✓ Tools installed successfully"
