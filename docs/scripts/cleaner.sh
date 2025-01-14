#!/bin/bash
# Version 1.0.3
# This script is designed to be run on a Raspberry Pi with a fresh install of Raspberry Pi OS Lite (64-bit).
# It will remove Node-RED, InfluxDB, and Grafana completely.
# Use at your own risk, and be ready to wipe your Pi and start over if it doesn't work.  Yeehaw!

# Stop any running services
sudo systemctl stop nodered || true
sudo systemctl stop influxdb || true
sudo systemctl stop grafana-server || true

# Remove the services
sudo systemctl disable nodered || true
sudo systemctl disable influxdb || true
sudo systemctl disable grafana-server || true

# Remove Node.js and npm
sudo apt-get remove -y nodejs npm
sudo apt-get autoremove -y

# Properly remove InfluxDB
sudo apt-get remove --purge -y influxdb2
sudo rm -rf /var/lib/influxdb
sudo rm -rf /etc/influxdb
sudo rm -f /etc/apt/sources.list.d/influxdata.list
sudo rm -f /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg

# Remove service files
sudo rm -f /etc/systemd/system/nodered.service
sudo rm -rf ~/.node-red
sudo rm -f /etc/apt/sources.list.d/nodesource.list*
sudo rm -f /etc/apt/sources.list.d/grafana.list

# Clean Keyrings
sudo rm -f /usr/share/keyrings/grafana-archive-keyring.gpg

# First, remove remaining npm directories
sudo rm -rf /usr/lib/node_modules
sudo rm -rf ~/.npm
sudo rm -rf ~/.node-red

# Remove any remaining Node.js files
sudo rm -rf /usr/local/lib/node*
sudo rm -rf /usr/local/include/node*
sudo rm -rf /usr/local/bin/node*
sudo rm -rf /usr/local/bin/npm*

# Clean apt cache
sudo apt clean
sudo apt autoclean
sudo apt autoremove -y

# Remove MetSci specific files
sudo rm -rf /etc/metsci-dashboard
sudo rm -f ~/metsci-credentials.txt

# Verify removals
echo "Checking for remaining service files..."
ls /etc/systemd/system/nodered.service 2>/dev/null || echo "Node-RED service removed"
ls /etc/systemd/system/influxdb.service 2>/dev/null || echo "InfluxDB service removed"
ls /etc/systemd/system/grafana-server.service 2>/dev/null || echo "Grafana service removed"

echo "Checking for remaining config directories..."
ls ~/.node-red 2>/dev/null || echo "Node-RED config removed"
ls /etc/influxdb 2>/dev/null || echo "InfluxDB config removed"
ls /etc/grafana 2>/dev/null || echo "Grafana config removed"

echo "Checking for remaining packages..."
dpkg -l | grep -E 'nodejs|npm|influxdb|grafana' || echo "No packages found"

echo "Cleanup complete!"
