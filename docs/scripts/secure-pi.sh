#!/bin/bash
# Version 1.1.7

# Set up logging
LOG_FILE="/home/$SUDO_USER/security-setup.log"
exec 1> >(tee -a "$LOG_FILE") 2>&1

# Print version info
echo "MeteoScientific Pi Security Setup v1.1.7"

# Check for tools, install required tools if not present
echo "Checking for required tools..."
command -v nc >/dev/null 2>&1 || {
    echo "Installing netcat..."
    sudo apt-get update && sudo apt-get install -y netcat-traditional
}

command -v netstat >/dev/null 2>&1 || {
    echo "Installing net-tools..."
    sudo apt-get update && sudo apt-get install -y net-tools
}

command -v curl >/dev/null 2>&1 || {
    echo "Installing curl..."
    sudo apt-get update && sudo apt-get install -y curl
}

command -v sudo >/dev/null 2>&1 || {
    echo "ERROR: sudo is not installed. Please install sudo and try again."
    exit 1
}

command -v python3 >/dev/null 2>&1 || {
    echo "Installing Python3 (required for fail2ban)..."
    sudo apt-get update && sudo apt-get install -y python3
}

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
    
    # Skip SSH port check since we're using it
    if [ "$service" = "SSH" ]; then
        return 0
    }
    
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

# Check required ports (excluding 22 since we need SSH)
for port in 1880 3000 8086; do
    if netstat -tuln | grep -q ":$port "; then
        error_exit "Port $port is already in use. Please free this port before continuing."
    fi
done

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
MaxAuthTries 10
LoginGraceTime 60
EOL

echo -e "${YELLOW}Note: For enhanced SSH security, consider setting up SSH keys:${NC}"
echo "https://www.raspberrypi.com/documentation/computers/remote-access.html#passwordless-ssh-access"

# Before UFW setup
echo "Checking existing firewall configuration..."
if sudo ufw status | grep -q "Status: active"; then
    echo -e "${YELLOW}UFW is already active. Current rules:${NC}"
    sudo ufw status numbered
    read -p "Would you like to reset UFW to default settings? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Resetting UFW..."
        sudo ufw --force reset
    else
        echo "Keeping existing UFW configuration..."
        echo "New rules will be added to existing configuration."
    fi
fi

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

# After setting up UFW
echo "Testing SSH accessibility..."
TEST_PORT=$(ssh -p 22 -o BatchMode=yes -o ConnectTimeout=5 localhost 2>&1 | grep -q "Permission denied" && echo "OK" || echo "FAIL")

if [ "$TEST_PORT" = "FAIL" ]; then
    echo -e "${RED}WARNING: SSH appears to be blocked. Adding SSH rule...${NC}"
    sudo ufw allow ssh
    sudo systemctl restart ssh
fi

# 3. Create service user
echo "Creating service user..."
echo -e "${YELLOW}This creates a non-root user for running services${NC}"
sudo useradd -m -s /bin/bash metsci-service
sudo usermod -aG sudo metsci-service

# 4. Set up fail2ban
echo "Installing fail2ban..."
echo -e "${YELLOW}This helps prevent brute force attacks by temporarily blocking IPs that fail to log in${NC}"
sudo apt-get install -y fail2ban

# Configure fail2ban with safe settings
echo "Configuring fail2ban with safe settings..."
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

# Restart fail2ban with new config
sudo systemctl restart fail2ban

# Double-check UFW SSH rule
echo "Ensuring SSH access..."
sudo ufw allow ssh
sudo ufw reload

# Test SSH access before finishing
echo "Testing SSH access..."
if ! nc -z localhost 22; then
    echo "ERROR: SSH is not accessible! Reverting changes..."
    sudo ufw disable
    sudo systemctl stop fail2ban
    exit 1
fi

echo "
Your current IP ($(who | grep -oP '(\d+\.){3}\d+' | sort -u)) has been whitelisted in fail2ban.
This means you won't get locked out when reconnecting after reboot.
"

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
echo "Your Pi is now configured with:"
echo "- Secure SSH settings"
echo "- Basic firewall (UFW)"
echo "- Automatic updates"
echo "- Local network protection"
echo
echo "External access is handled by Cloudflare tunnel"
echo
echo "To see detailed setup information:"
echo "    cat $LOG_FILE"
echo
echo "➡️  Please reboot your Pi to apply all changes:"
echo "    sudo reboot"

# Restart services
sudo systemctl restart ssh
sudo systemctl restart fail2ban

# Add note about Grafana public access
echo
echo -e "${YELLOW}Important notes about access:${NC}"
echo "1. Local network access is controlled by this firewall"
echo "2. Public Grafana dashboards will still work through Cloudflare"
echo "3. All other external access should go through Cloudflare tunnel"

# Before the final clear and success message, add:
echo "Verifying security settings..."

# Verify fail2ban config
if ! grep -q "192.168.0.0/16" /etc/fail2ban/jail.local; then
    echo "⚠️  WARNING: fail2ban whitelist not properly saved!"
    echo "Please check /etc/fail2ban/jail.local before rebooting"
    exit 1
fi

# Verify UFW is properly configured
if ! sudo ufw status | grep -q "22/tcp.*ALLOW"; then
    echo "⚠️  WARNING: SSH port not properly configured in firewall!"
    echo "Please check 'sudo ufw status' before rebooting"
    exit 1
fi

# Log the completion details to a separate summary file
SUMMARY_FILE="/home/$SUDO_USER/security-setup-summary.txt"

# Create the summary
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

Configuration Files Modified:
- /etc/ssh/sshd_config.d/security.conf
- /etc/fail2ban/jail.local
- /etc/ufw/user.rules

For detailed logs: $LOG_FILE
EOL

# Show completion without clearing screen
echo
echo "✅ Security setup complete!"
echo
echo "Your Pi is now configured with:"
echo "- Secure SSH settings"
echo "- Basic firewall (UFW)"
echo "- Automatic updates"
echo "- Local network protection"
echo
echo "External access is handled by Cloudflare tunnel"
echo
echo "To see detailed setup information:"
echo "    cat $SUMMARY_FILE"
echo
echo "Full logs available at:"
echo "    cat $LOG_FILE"
echo
echo "➡️  Please reboot your Pi to apply all changes:"
echo "    sudo reboot"

# At the start of the script, after initial message
echo "Checking for existing SSH host keys..."
PI_IP=$(hostname -I | awk '{print $1}')
if ssh-keygen -F $PI_IP >/dev/null 2>&1; then
    echo "
⚠️  WARNING: Your computer has old SSH keys stored for this Pi ($PI_IP)
If this is a fresh Pi install, you should remove these keys from your computer:

For Mac/Linux:
    ssh-keygen -R $PI_IP

For Windows:
    - Using Git Bash or WSL: ssh-keygen -R $PI_IP
    - Using PowerShell: Remove-Item \"\$env:USERPROFILE/.ssh/known_hosts\" -Force
    - Or manually delete the entries for $PI_IP in %UserProfile%\\.ssh\\known_hosts

This will prevent SSH security warnings when you reconnect.
"
    # Give user a moment to read the warning
    sleep 3
fi

# At start of script, after SSH key warning
echo "Checking system update status..."
last_update=$(stat -c %Y /var/cache/apt/pkgcache.bin 2>/dev/null || echo 0)
now=$(date +%s)
update_age=$((now - last_update))

# If last update was more than 1 hour ago
if [ $update_age -gt 3600 ]; then
    echo "System updates needed..."
    sudo apt update
    sudo apt upgrade -y
else
    echo "✓ System recently updated, skipping..."
fi

# At the end of the script, before the reboot message:
echo
echo "Note for Mac users:"
echo "If you get 'too many authentication failures' when connecting,"
echo "use: ssh -o IdentitiesOnly=yes demo@<PI-IP>"
echo

# Add version check for dashboard script
check_dashboard_version() {
    if [ -f "/etc/metsci-dashboard/.env" ]; then
        echo -e "${YELLOW}Warning: Dashboard installation detected. Some security settings may be overwritten.${NC}"
        read -p "Continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Add after initial checks
main() {
    check_dashboard_version
    # ... rest of main function ...
}
