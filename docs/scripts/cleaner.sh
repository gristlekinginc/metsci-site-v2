#!/bin/bash
# Version 1.0.1
# This script is designed to be run on a Raspberry Pi with a fresh install of Raspberry Pi OS Lite (64-bit).
# It will remove Node-RED, InfluxDB, and Grafana, and configure them to work together. 
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

# Remove service files
sudo rm -f /etc/systemd/system/nodered.service
sudo rm -rf ~/.node-red
sudo rm -f /etc/apt/sources.list.d/nodesource.list*
sudo rm -f /etc/apt/sources.list.d/influxdb.list
sudo rm -f /etc/apt/sources.list.d/grafana.list

# Update package lists
sudo apt-get update

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
sudo apt autoremove

# Verify Node.js is gone
which node
which npm

# Check for service files
ls /etc/systemd/system/nodered.service
ls /etc/systemd/system/influxdb.service
ls /etc/systemd/system/grafana-server.service

# Check for config directories
ls ~/.node-red
ls /etc/influxdb
ls /etc/grafana