#!/bin/bash
# Version 1.0.9
# This script is designed to be run on a Raspberry Pi with a fresh install of Raspberry Pi OS Lite (64-bit).
# It will remove Node-RED, InfluxDB, and Grafana completely, and is used to clean

echo "Starting cleanup process..."

# 1. Stop services first
echo "Stopping services..."
for service in nodered influxdb grafana-server; do
    sudo systemctl stop $service 2>/dev/null || true
    sudo systemctl disable $service 2>/dev/null || true
    echo "✓ $service stopped"
done

# 2. Remove repository sources early
echo "Removing repository sources..."
sudo rm -f /etc/apt/sources.list.d/nodesource.list*
sudo rm -f /etc/apt/sources.list.d/influxdata.list
sudo rm -f /etc/apt/sources.list.d/grafana.list
sudo rm -f /usr/share/keyrings/grafana-archive-keyring.gpg
sudo rm -f /usr/share/keyrings/grafana.gpg
sudo apt-get update

# 3. Remove packages
echo "Removing packages..."
for package in nodejs npm influxdb2 grafana grafana-enterprise; do
    if dpkg -l | grep -q "^ii.*$package"; then
        echo "Removing $package..."
        # Redirect stderr to suppress dpkg warnings about non-empty directories
        sudo apt-get remove --purge -y $package 2>/dev/null || true
    else
        echo "Package $package not installed, skipping..."
    fi
done
sudo apt-get autoremove --purge -y 2>/dev/null || true

# 4. Clean up configuration directories
echo "Removing configuration directories..."
sudo rm -rf /etc/influxdb*
sudo rm -rf /etc/grafana
sudo rm -rf ~/.node-red
sudo rm -rf /home/metsci-service/.node-red
sudo rm -rf /etc/metsci-dashboard
sudo rm -rf /var/lib/influxdb*
sudo rm -rf /var/log/influxdb*
sudo rm -rf ~/.influxdbv2
sudo rm -rf /etc/default/influxdb*

# Also add user cleanup
echo "Removing service user..."
sudo userdel -r metsci-service 2>/dev/null || true

# 5. Clean up Node.js files
echo "Cleaning Node.js files..."
sudo rm -rf /usr/lib/node_modules
sudo rm -rf /usr/local/lib/node_modules
sudo rm -rf ~/.npm
sudo rm -rf /usr/local/bin/node*
sudo rm -rf /usr/local/bin/npm*

# Add before the Node.js files cleanup
echo "Cleaning npm directories..."
sudo rm -rf /usr/lib/node_modules/npm
sudo rm -rf /usr/lib/node_modules/.staging
sudo rm -rf /usr/lib/node_modules/.package-lock.json

# 6. Clean up service files
echo "Cleaning service files..."
for service in nodered influxdb influxd grafana-server; do
    sudo rm -f /etc/systemd/system/$service.service
    sudo rm -f /lib/systemd/system/$service.service
done
sudo systemctl daemon-reload

# 7. Now perform verification checks
echo "Performing verification checks..."

# Check for remaining packages
echo "Checking for remaining packages..."
for pkg in nodejs npm influxdb2 grafana grafana-enterprise; do
    if dpkg -l | grep -q "^ii.*$pkg"; then
        echo "⚠️  Warning: Package still installed: $pkg"
    else
        echo "✓ Package removed: $pkg"
    fi
done

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
