#!/bin/bash
# Version 1.0.9
# This script is designed to be run on a Raspberry Pi with a fresh install of Raspberry Pi OS Lite (64-bit).
# It will remove Node-RED, InfluxDB, and Grafana completely, and is used to clean

# Force standard output formatting
export TERM=linux
stty columns 80 rows 24 2>/dev/null || true

# Clear any existing formatting
reset

# Function to standardize output
print_status() {
    printf "%-70s" "$1"
}

print_result() {
    printf "%s\n" "$2"
}

echo "Starting cleanup process..."

# Add more aggressive process cleanup before the service stops
print_status "Forcefully stopping any remaining processes..."
for process in "node-red" "influxd" "grafana-server"; do
    if pgrep -f "$process" > /dev/null; then
        sudo pkill -9 -f "$process" 2>/dev/null || true
    fi
done
print_result "" "done"

# 1. Stop services first
print_status "Stopping services..."
for service in nodered influxdb grafana-server; do
    print_status "Stopping $service..."
    sudo systemctl stop $service 2>/dev/null || true
    sudo systemctl disable $service 2>/dev/null || true
    if systemctl is-active --quiet $service; then
        sudo killall -9 $service 2>/dev/null || true
    fi
    print_result "" "✓"
done

# 2. Remove repository sources early
print_status "Removing repository sources..."
sudo rm -f /etc/apt/sources.list.d/nodesource.list*
sudo rm -f /etc/apt/sources.list.d/influxdata.list
sudo rm -f /etc/apt/sources.list.d/grafana.list
sudo rm -f /usr/share/keyrings/grafana-archive-keyring.gpg
sudo rm -f /usr/share/keyrings/grafana.gpg
sudo apt-get update

# Add to the repository cleanup section
print_status "Cleaning up repository keys..."
sudo rm -f /home/$SUDO_USER/influxdata-archive_compat.key*
sudo rm -f /etc/apt/keyrings/influxdata-archive-keyring.gpg

# 3. Remove packages
print_status "Removing packages..."
for package in nodejs npm influxdb2 grafana grafana-enterprise; do
    print_status "Checking package $package..."
    if dpkg -l | grep -q "^ii.*$package"; then
        sudo apt-get remove --purge -y $package >/dev/null 2>&1 || {
            sudo dpkg --force-all -P $package >/dev/null 2>&1 || true
        }
        print_result "" "removed"
    else
        print_result "" "not installed"
    fi
done
sudo apt-get autoremove --purge -y >/dev/null 2>&1 || true

# 4. Clean up configuration directories
print_status "Removing configuration directories..."
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
print_status "Removing service user..."
sudo userdel -r metsci-service 2>/dev/null || true

# 5. Clean up Node.js files
print_status "Cleaning Node.js files..."
npm_dirs=(
    "/usr/lib/node_modules"
    "/usr/local/lib/node_modules"
    "~/.npm"
    "/usr/local/bin/node*"
    "/usr/local/bin/npm*"
)

for dir in "${npm_dirs[@]}"; do
    if [ -d "$dir" ] || [ -f "$dir" ]; then
        echo "Removing $dir..."
        if ! sudo rm -rf "$dir" 2>/dev/null; then
            # If directory not empty, try force remove
            find "$dir" -type f -delete 2>/dev/null
            find "$dir" -type d -empty -delete 2>/dev/null
            remaining=$(find "$dir" -type d 2>/dev/null | wc -l)
            if [ "$remaining" -gt 0 ]; then
                echo "⚠️  Warning: Could not fully remove $dir ($remaining items remain)"
            fi
        fi
    fi
done

# 6. Clean up service files
print_status "Cleaning service files..."
for service in nodered influxdb influxd grafana-server; do
    sudo rm -f /etc/systemd/system/$service.service
    sudo rm -f /lib/systemd/system/$service.service
done
sudo systemctl daemon-reload

# 7. Now perform verification checks
print_status "Performing verification checks..."

# Check for remaining packages
print_status "Checking for remaining packages..."
for pkg in nodejs npm influxdb2 grafana grafana-enterprise; do
    if dpkg -l | grep -q "^ii.*$pkg"; then
        printf "⚠️  Warning: Package still installed: %s\n" "$pkg"
    else
        printf "✓ Package removed: %s\n" "$pkg"
    fi
done

# Check for remaining service files
print_status "Checking service files..."
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
print_status "Checking for running processes..."
processes=("node-red" "influxd" "grafana")
for proc in "${processes[@]}"; do
    if pgrep -f "$proc" > /dev/null; then
        echo "⚠️  Warning: Process still running: $proc"
    else
        echo "✓ Process not running: $proc"
    fi
done

# Check ports
print_status "Checking ports..."
for port in 1880 8086 3000; do
    if netstat -tuln | grep -q ":$port "; then
        echo "⚠️  Warning: Port $port is still in use"
        # Add process identification
        pid=$(sudo lsof -t -i:$port 2>/dev/null)
        if [ ! -z "$pid" ]; then
            echo "Process using port $port: $(ps -p $pid -o comm=)"
            echo "Attempting to force kill process..."
            sudo kill -9 $pid 2>/dev/null || true
        fi
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
