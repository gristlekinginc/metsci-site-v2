#!/bin/bash
# Version 1.0.4
# This script is designed to be run on a Raspberry Pi with a fresh install of Raspberry Pi OS Lite (64-bit).
# It will remove Node-RED, InfluxDB, and Grafana completely.
# Use at your own risk, and be ready to wipe your Pi and start over if it doesn't work.  Yeehaw!

echo "Starting cleanup process..."

# Stop any running services
echo "Stopping services..."
for service in nodered influxdb grafana-server; do
    sudo systemctl stop $service 2>/dev/null || true
    sudo systemctl disable $service 2>/dev/null || true
    echo "✓ $service stopped"
done

# Remove Node.js and npm
echo "Removing Node.js and npm..."
sudo apt-get remove -y nodejs npm
sudo apt-get autoremove -y

# Properly remove InfluxDB
echo "Removing InfluxDB..."
sudo apt-get remove --purge -y influxdb2
sudo rm -rf /var/lib/influxdb*
sudo rm -rf /etc/influxdb*
sudo rm -rf /var/log/influxdb*
sudo rm -rf ~/.influxdbv2
sudo rm -rf /etc/default/influxdb*
sudo rm -f /etc/apt/sources.list.d/influxdata.list
sudo rm -f /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg
sudo rm -f /etc/systemd/system/influxd.service
sudo rm -f /etc/systemd/system/influxdb.service

# Remove service files and configs
echo "Removing service files and configs..."
sudo rm -f /etc/systemd/system/nodered.service
sudo rm -rf ~/.node-red
sudo rm -f /etc/apt/sources.list.d/nodesource.list*
sudo rm -f /etc/apt/sources.list.d/grafana.list
sudo rm -rf /etc/grafana
sudo rm -f /usr/share/keyrings/grafana-archive-keyring.gpg

# Clean npm directories
echo "Cleaning npm directories..."
sudo rm -rf /usr/lib/node_modules
sudo rm -rf ~/.npm
sudo rm -rf ~/.node-red

# Remove Node.js files
echo "Removing Node.js files..."
sudo rm -rf /usr/local/lib/node*
sudo rm -rf /usr/local/include/node*
sudo rm -rf /usr/local/bin/node*
sudo rm -rf /usr/local/bin/npm*

# Remove MetSci specific files
echo "Removing MetSci files..."
sudo rm -rf /etc/metsci-dashboard
sudo rm -f ~/metsci-credentials.txt

# Clean apt cache
echo "Cleaning apt cache..."
sudo apt clean
sudo apt autoclean
sudo apt autoremove -y

# Reload systemd
sudo systemctl daemon-reload

# Verify removals
echo "Performing verification checks..."

# Check for remaining service files
echo "Checking service files..."
service_files=(
    "/etc/systemd/system/nodered.service"
    "/etc/systemd/system/influxdb.service"
    "/etc/systemd/system/influxd.service"
    "/etc/systemd/system/grafana-server.service"
)
for file in "${service_files[@]}"; do
    if [ -f "$file" ]; then
        echo "⚠️  Warning: Service file still exists: $file"
    else
        echo "✓ Service file removed: $file"
    fi
done

# Check for remaining config directories
echo "Checking config directories..."
config_dirs=(
    "/etc/influxdb"
    "/etc/grafana"
    "~/.node-red"
    "/etc/metsci-dashboard"
)
for dir in "${config_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "⚠️  Warning: Config directory still exists: $dir"
    else
        echo "✓ Config directory removed: $dir"
    fi
done

# Check for remaining packages
echo "Checking for remaining packages..."
packages=("nodejs" "npm" "influxdb2" "grafana")
for pkg in "${packages[@]}"; do
    if dpkg -l | grep -q "^ii.*$pkg"; then
        echo "⚠️  Warning: Package still installed: $pkg"
    else
        echo "✓ Package removed: $pkg"
    fi
done

# Check for running processes
echo "Checking for running processes..."
processes=("node-red" "influxd" "grafana")
for proc in "${processes[@]}"; do
    if pgrep -f "$proc" > /dev/null; then
        echo "⚠️  Warning: Process still running: $proc"
    else
        echo "✓ Process not running: $proc"
    fi
done

# Check ports
echo "Checking ports..."
ports=(1880 8086 3000)
for port in "${ports[@]}"; do
    if netstat -tuln | grep -q ":$port "; then
        echo "⚠️  Warning: Port $port is still in use"
    else
        echo "✓ Port $port is free"
    fi
done

# Remove Grafana files and keys
echo "Removing Grafana files..."
sudo rm -f /usr/share/keyrings/grafana.gpg
sudo rm -f /usr/share/keyrings/grafana-archive-keyring.gpg
sudo rm -f /etc/apt/sources.list.d/grafana.list
sudo rm -rf /etc/grafana

# Clean Node-RED more thoroughly
echo "Cleaning Node-RED files..."
sudo rm -rf ~/.node-red
sudo rm -f /etc/systemd/system/nodered.service
sudo rm -rf /home/$SUDO_USER/.node-red/settings.js

# Clean Grafana configs thoroughly
echo "Cleaning Grafana configs..."
sudo rm -rf /etc/grafana/*
sudo rm -f /var/lib/grafana/grafana.db

echo "Cleanup complete!"

# Prompt for reboot
echo
echo "It's recommended to reboot your Pi to ensure all changes take effect."
read -p "Would you like to reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting in 5 seconds..."
    sleep 5
    sudo reboot
else
    echo "Please remember to reboot your Pi before running the installation script."
fi
