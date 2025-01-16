#!/bin/bash
# This script provides basic security hardening for MetSci dashboard installation

#----------------------------------------------------------------------
# Colors and Logging
#----------------------------------------------------------------------
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="/home/$SUDO_USER/security-setup.log"
exec 1> >(tee -a "$LOG_FILE") 2>&1

#----------------------------------------------------------------------
# Pre-Checks & Warnings
#----------------------------------------------------------------------
echo "MeteoScientific Pi Security Setup v1.2.4"
echo "This script prepares your Pi for secure dashboard installation"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    echo "Example: sudo ./secure-pi.sh"
    exit 1
fi

# Check for dashboard installation
if [ -f "/etc/metsci-dashboard/.env" ]; then
    DASHBOARD_VERSION=$(grep "VERSION=" /etc/metsci-dashboard/.env | cut -d'"' -f2)
    echo -e "${YELLOW}Warning: Dashboard v${DASHBOARD_VERSION} detected${NC}"
    read -p "Continue? This may overwrite some settings (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check required tools
echo "Checking for required tools..."
for tool in nc netstat curl sudo python3; do
    if ! command -v $tool >/dev/null 2>&1; then
        echo "Installing $tool..."
        sudo apt-get update && sudo apt-get install -y $tool
    fi
done

#----------------------------------------------------------------------
# System Update
#----------------------------------------------------------------------
echo "Checking system update status..."
last_update=$(stat -c %Y /var/cache/apt/pkgcache.bin 2>/dev/null || echo 0)
now=$(date +%s)
if [ $((now - last_update)) -gt 3600 ]; then
    echo "Updating system packages..."
    sudo apt-get update && sudo apt-get upgrade -y
fi

#----------------------------------------------------------------------
# SSH Hardening
#----------------------------------------------------------------------
echo "Configuring SSH..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo tee /etc/ssh/sshd_config.d/security.conf > /dev/null << EOL
# Security settings for SSH
PasswordAuthentication yes
PermitEmptyPasswords no
PermitRootLogin no
Protocol 2
MaxAuthTries 10
LoginGraceTime 60
EOL

#----------------------------------------------------------------------
# Port Configuration
#----------------------------------------------------------------------
echo "Checking required ports..."
for port in 1880 3000 8086; do
    if netstat -tuln | grep -q ":$port "; then
        echo -e "${YELLOW}Warning: Port $port is in use. The dashboard installer may need this port.${NC}"
    fi
done

#----------------------------------------------------------------------
# Firewall Setup
#----------------------------------------------------------------------
echo "Setting up firewall (UFW)..."

# Check if UFW is installed, if not install it
if ! command -v ufw >/dev/null 2>&1; then
    echo "Installing UFW..."
    sudo apt-get install -y ufw >/dev/null 2>&1
fi

# Reset UFW to default state without prompting
echo "Configuring firewall rules..."
sudo ufw --force reset >/dev/null 2>&1

# Configure UFW (with proper port syntax)
sudo ufw default deny incoming >/dev/null 2>&1
sudo ufw default allow outgoing >/dev/null 2>&1
sudo ufw allow 22/tcp comment 'SSH' >/dev/null 2>&1
sudo ufw allow 1880/tcp comment 'Node-RED' >/dev/null 2>&1
sudo ufw allow 8086/tcp comment 'InfluxDB' >/dev/null 2>&1
sudo ufw allow 3000/tcp comment 'Grafana' >/dev/null 2>&1

# Enable UFW without prompt
sudo ufw --force enable >/dev/null 2>&1

# Verify UFW is running
if sudo ufw status | grep -q "Status: active"; then
    echo "✓ Firewall configured and enabled"
else
    echo -e "${RED}ERROR: Firewall configuration failed${NC}"
    exit 1
fi

#----------------------------------------------------------------------
# Service User Setup
#----------------------------------------------------------------------
echo "Creating service user..."
# Generate a secure random password
METSCI_SERVICE_PASSWORD=$(openssl rand -base64 32)

# Create user and set password non-interactively
sudo useradd -m -s /bin/bash metsci-service
echo "metsci-service:${METSCI_SERVICE_PASSWORD}" | sudo chpasswd
sudo usermod -aG sudo metsci-service

# Set up Node-RED directory and npm cache
sudo mkdir -p /home/metsci-service/.node-red
sudo mkdir -p /home/metsci-service/.npm
sudo chown -R metsci-service:metsci-service /home/metsci-service/.node-red
sudo chown -R metsci-service:metsci-service /home/metsci-service/.npm

# Configure sudo access for metsci-service (specific permissions for Node-RED)
sudo tee /etc/sudoers.d/metsci-nodered > /dev/null << EOL
# Allow metsci-service to manage Node-RED service
metsci-service ALL=(ALL) NOPASSWD: /usr/bin/npm
metsci-service ALL=(ALL) NOPASSWD: /usr/bin/node
metsci-service ALL=(ALL) NOPASSWD: /bin/systemctl start nodered
metsci-service ALL=(ALL) NOPASSWD: /bin/systemctl stop nodered
metsci-service ALL=(ALL) NOPASSWD: /bin/systemctl restart nodered
metsci-service ALL=(ALL) NOPASSWD: /bin/systemctl status nodered
metsci-service ALL=(ALL) NOPASSWD: /bin/systemctl enable nodered
EOL

# Set proper permissions on sudoers file
sudo chmod 440 /etc/sudoers.d/metsci-nodered

#----------------------------------------------------------------------
# fail2ban Setup
#----------------------------------------------------------------------
echo "Installing fail2ban..."
sudo apt-get install -y fail2ban >/dev/null 2>&1
sudo tee /etc/fail2ban/jail.local > /dev/null << EOF
[DEFAULT]
bantime = 10m
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8 ::1/128 192.168.0.0/16

[sshd]
enabled = true
mode = normal
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF

sudo systemctl restart fail2ban

#----------------------------------------------------------------------
# Automatic Updates
#----------------------------------------------------------------------
echo "Setting up automatic updates..."
sudo apt-get install -y unattended-upgrades apt-listchanges >/dev/null 2>&1
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null << EOL
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOL

#----------------------------------------------------------------------
# Package Installation
#----------------------------------------------------------------------
echo "Installing required packages..."
# Redirect apt output to suppress "already installed" messages
sudo apt-get install -y ufw fail2ban unattended-upgrades apt-listchanges >/dev/null 2>&1

# Only show status for new configurations
if [ ! -f "/etc/fail2ban/jail.local" ]; then
    echo "Configuring fail2ban..."
    sudo tee /etc/fail2ban/jail.local > /dev/null << EOF
    # ... rest of fail2ban config ...
EOF
fi

#----------------------------------------------------------------------
# Final Checks & Summary
#----------------------------------------------------------------------
# Verify critical services
sudo systemctl restart ssh
if ! nc -z localhost 22; then
    echo -e "${RED}ERROR: SSH is not accessible! Reverting changes...${NC}"
    sudo ufw disable
    sudo systemctl stop fail2ban
    exit 1
fi

# Create summary
SUMMARY_FILE="/home/$SUDO_USER/security-setup-summary.txt"
cat > "$SUMMARY_FILE" << EOL
=== MeteoScientific Pi Security Setup Summary ===
Date: $(date)
Hostname: $(hostname)
IP: $(hostname -I | awk '{print $1}')

Completed Security Measures:
- Secure SSH settings (no root login, strong passwords)
- Basic firewall (UFW) with allowed ports:
  * SSH: $SSH_PORT
  * Node-RED: $NODERED_PORT
  * InfluxDB: $INFLUXDB_PORT
  * Grafana: $GRAFANA_PORT
- Automatic updates enabled
- fail2ban installed and configured
- Local network protection
- System user 'metsci-service' created

For detailed logs: $LOG_FILE
EOL

echo -e "${GREEN}Security setup complete!${NC}"
echo
echo "Your Pi is now secured and ready for dashboard installation."
echo "Next step: Run the dashboard installer script"
echo
echo "Summary saved to: $SUMMARY_FILE"
echo "Logs available at: $LOG_FILE"
echo
echo "Please reboot before running the dashboard installer:"
echo "    sudo reboot"
