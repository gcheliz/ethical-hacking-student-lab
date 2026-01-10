#!/bin/bash
# Install required penetration testing tools

export DEBIAN_FRONTEND=noninteractive

echo "Updating package lists..."
apt-get update -qq

echo "Installing required packages (without upgrading existing)..."
apt-get install -y -qq --no-upgrade \
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

echo "Note: Skipping package upgrades to prevent SSH timeouts during provisioning"

# Initialize and start PostgreSQL
echo "Configuring PostgreSQL service..."

# Check if PostgreSQL cluster exists, if not create it
if ! sudo -u postgres psql -c '\q' 2>/dev/null; then
    echo "  PostgreSQL cluster not initialized, creating..."

    # Try to initialize the main cluster (Debian/Kali style)
    if command -v pg_ctlcluster &> /dev/null; then
        PG_VERSION=$(ls /etc/postgresql/ 2>/dev/null | head -n1)
        if [ ! -z "$PG_VERSION" ] && [ ! -d "/var/lib/postgresql/$PG_VERSION/main" ]; then
            echo "  Creating PostgreSQL $PG_VERSION cluster..."
            sudo -u postgres /usr/bin/pg_createcluster $PG_VERSION main --start || true
        fi
    fi
fi

# Enable and restart PostgreSQL
echo "Starting PostgreSQL service..."
systemctl enable postgresql 2>/dev/null || true
systemctl restart postgresql 2>/dev/null || true

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
MAX_WAIT=30
WAIT_COUNT=0
until sudo -u postgres psql -c '\q' 2>/dev/null || [ $WAIT_COUNT -eq $MAX_WAIT ]; do
    echo "  Waiting for PostgreSQL... ($WAIT_COUNT/$MAX_WAIT)"
    sleep 2
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [ $WAIT_COUNT -eq $MAX_WAIT ]; then
    echo "WARNING: PostgreSQL not responding, checking status..."
    systemctl status postgresql --no-pager || true
    journalctl -u postgresql -n 20 --no-pager || true
    echo ""
    echo "Attempting to start PostgreSQL with msfdb..."
    # msfdb init will also start PostgreSQL if needed
else
    echo "✓ PostgreSQL is ready"
fi

# Now initialize Metasploit database
echo "Initializing Metasploit database..."
# msfdb init will start PostgreSQL if needed and create the database
if msfdb init; then
    echo "✓ Metasploit database initialized"
else
    echo "WARNING: msfdb init had issues, trying to reinitialize..."
    # Sometimes a reinit helps
    msfdb reinit --no-prompt 2>/dev/null || true

    # Check if it worked
    if msfdb status | grep -q "connected"; then
        echo "✓ Metasploit database connected after reinit"
    else
        echo "WARNING: Metasploit database initialization had issues"
        echo "This is usually OK - Metasploit will work in degraded mode"
    fi
fi

# Create Metasploit workspace (non-critical, database-dependent)
echo "Creating Metasploit workspace..."
if sudo -u vagrant msfconsole -q -x "workspace -a pdf_exploit_lab; exit" > /dev/null 2>&1; then
    echo "✓ Workspace created"
else
    echo "Note: Workspace creation skipped (database optional for this lab)"
fi

echo "✓ Tools installed successfully"
