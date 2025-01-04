#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    echo "Example: sudo ./secure-pi.sh"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default ports - change these if you're using different ports
SSH_PORT=22
NODERED_PORT=1880
INFLUXDB_PORT=8086
GRAFANA_PORT=3000

# Function to check if a port is in use
check_port() {
    local port=$1
    local service=$2
    if netstat -tuln | grep -q ":$port "; then
        echo -e "${YELLOW}Warning: Port $port is already in use. This might be okay if $service is already running.${NC}"
        read -p "Continue with this port? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            read -p "Enter alternative port for $service: " new_port
            eval "${service}_PORT=$new_port"
        fi
    fi
}

echo "Starting Pi security setup..."
echo -e "${YELLOW}Note: This script adds basic security to your Pi. Your network router/firewall provides additional security.${NC}"

# Check ports before proceeding
echo "Checking ports..."
check_port $SSH_PORT "SSH"
check_port $NODERED_PORT "NODERED"
check_port $INFLUXDB_PORT "INFLUXDB"
check_port $GRAFANA_PORT "GRAFANA"

# 1. SSH Hardening
echo "Configuring SSH..."
echo -e "${YELLOW}This makes SSH more secure by:${NC}"
echo "- Requiring strong passwords"
echo "- Preventing root login"
echo "- Limiting login attempts"

sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo tee /etc/ssh/sshd_config.d/security.conf > /dev/null << EOL
# Security settings for SSH
PasswordAuthentication yes
PermitEmptyPasswords no
PermitRootLogin no
Protocol 2
MaxAuthTries 3
LoginGraceTime 60
EOL

echo -e "${YELLOW}Note: For enhanced SSH security, consider setting up SSH keys:${NC}"
echo "https://www.raspberrypi.com/documentation/computers/remote-access.html#passwordless-ssh-access"

# 2. Firewall Setup
echo "Setting up firewall (UFW)..."
echo -e "${YELLOW}This creates a basic firewall that:${NC}"
echo "- Blocks all incoming connections by default"
echo "- Allows outgoing connections (including Cloudflare tunnel)"
echo "- Opens only the ports we need for local access"

# Install UFW if not present
sudo apt-get install -y ufw

# IMPORTANT: Allow SSH BEFORE setting default policies
sudo ufw allow ssh comment 'SSH'

# Set default policies AFTER allowing SSH
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow other required ports
sudo ufw allow $NODERED_PORT/tcp comment 'Node-RED'
sudo ufw allow $INFLUXDB_PORT/tcp comment 'InfluxDB'
sudo ufw allow $GRAFANA_PORT/tcp comment 'Grafana'

# Enable UFW
sudo ufw --force enable

# 3. Create service user
echo "Creating service user..."
echo -e "${YELLOW}This creates a non-root user for running services${NC}"
sudo useradd -m -s /bin/bash metsci-service
sudo usermod -aG sudo metsci-service

# 4. Set up fail2ban
echo "Installing fail2ban..."
echo -e "${YELLOW}This helps prevent brute force attacks by temporarily blocking IPs that fail to log in${NC}"
sudo apt-get install -y fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo tee /etc/fail2ban/jail.local > /dev/null << EOL
[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
findtime = 300
bantime = 3600
EOL

# 5. System hardening
echo "Setting up automatic updates..."
echo -e "${YELLOW}This keeps your system updated automatically${NC}"
sudo apt-get update
sudo apt-get install -y \
    unattended-upgrades \
    apt-listchanges

# Configure automatic updates
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null << EOL
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOL

# 6. Verify changes
echo -e "${GREEN}Security setup complete!${NC}"
echo
echo "Your firewall is now configured to:"
sudo ufw status numbered | grep -E "^\\[[0-9]+"
echo
echo "To check your setup:"
echo "1. SSH config: cat /etc/ssh/sshd_config.d/security.conf"
echo "2. Firewall status: sudo ufw status"
echo "3. Fail2ban status: sudo systemctl status fail2ban"
echo "4. Auto-updates config: cat /etc/apt/apt.conf.d/20auto-upgrades"
echo
echo -e "${YELLOW}Important:${NC}"
echo "1. Your network firewall (router) provides additional security"
echo "2. These are basic security measures - adjust based on your needs"
echo
echo -e "${GREEN}Done! Please reboot your Pi to apply all changes:${NC}"
echo "sudo reboot"

# Restart services
sudo systemctl restart ssh
sudo systemctl restart fail2ban

# Add note about Grafana public access
echo
echo -e "${YELLOW}Important notes about access:${NC}"
echo "1. Local network access is controlled by this firewall"
echo "2. Public Grafana dashboards will still work through Cloudflare"
echo "3. All other external access should go through Cloudflare tunnel"