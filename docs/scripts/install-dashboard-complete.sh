#!/bin/bash
# Version 1.0.0
# This script is designed to be run on a Raspberry Pi with a fresh install of Raspberry Pi OS Lite (64-bit).
# It will install Node-RED, InfluxDB, and Grafana, and configure them to work together. 
# Use at your own risk, and be ready to wipe your Pi and start over if it doesn't work.  Yeehaw!

echo "MeteoScientific Dashboard Installer v1.0.0"
echo
echo "Hardware Requirements:"
echo "- Raspberry Pi 4 (4GB+ RAM recommended)"
echo "- 32GB+ SD card recommended"

# Check RAM
total_ram=$(free -m | awk '/^Mem:/{print $2}')
if [ "$total_ram" -lt 4000 ]; then
    echo "⚠️  Warning: This Pi has less than 4GB RAM ($total_ram MB)"
    echo "The dashboard may run slowly or have stability issues."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check disk space
available_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$available_space" -lt 16 ]; then
    echo "⚠️  Warning: Less than 16GB free space available ($available_space GB)"
    echo "You may run out of space when collecting data."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Set up logging
LOG_FILE="/tmp/dashboard-install-$(date +%Y%m%d-%H%M%S).log"
exec 1> >(tee -a "$LOG_FILE") 2>&1

# Add Netstat to check ports
command -v netstat >/dev/null 2>&1 || {
    echo "Installing net-tools..."
    sudo apt-get update && sudo apt-get install -y net-tools

# Add Curl to check repositories
command -v curl >/dev/null 2>&1 || {
    echo "Installing curl..."
    sudo apt-get update && sudo apt-get install -y curl
}
}

 # Add to install_nodejs()
   sudo npm install -g npm@latest

# Progress indicator function
show_progress() {
    local step="$1"
    local total="6"
    local message="$2"
    
    echo ""
    echo "==================================================================="
    echo "Progress: Step $step of $total"
    echo "Current: $message"
    echo "Status:  $(date '+%H:%M:%S')"
    echo "==================================================================="
    echo ""
}

# Function for error handling
error_exit() {
    echo "Error: $1" >&2
    echo "Check $LOG_FILE for details"
    # Attempt rollback if specified
    if [ "$2" = "rollback" ]; then
        perform_rollback
    fi
    exit 1
}

# Rollback function
perform_rollback() {
    echo "Installation failed. Rolling back changes..."
    
    # Stop services if they exist
    for service in nodered influxdb grafana-server; do
        if systemctl is-active --quiet $service; then
            sudo systemctl stop $service
            sudo systemctl disable $service
        fi
    done

    # Remove installed packages
    sudo apt-get remove -y nodejs npm influxdb2 grafana
    sudo apt-get autoremove -y

    # Clean up directories
    sudo rm -rf /etc/metsci-dashboard
    sudo rm -rf ~/.node-red

    echo "Rollback complete. Please check the error message above and try again."
}

# Enhanced check_requirements function
check_requirements() {
    echo "Performing system checks..."

    # Check internet connectivity first
    echo "Testing internet connection..."
    if ! ping -c 1 google.com &> /dev/null; then
        if ! ping -c 1 8.8.8.8 &> /dev/null; then
            error_exit "No internet connection detected. Please check your network."
        else
            error_exit "DNS resolution failed. Check your network settings."
        fi
    fi

    # Check repository access
    echo "Verifying repository access..."
    repos=(
        "https://deb.nodesource.com/setup_20.x"
        "https://repos.influxdata.com/influxdata-archive_compat.key"
        "https://packages.grafana.com/gpg.key"
    )
    
    for repo in "${repos[@]}"; do
        if ! curl -sL "$repo" -o /dev/null; then
            error_exit "Cannot access repository: $repo"
        fi
    done

    # Check if running on Pi
    if ! grep -q "Raspberry Pi" /proc/cpuinfo; then
        error_exit "This script must be run on a Raspberry Pi"
    fi

    # Check for 64-bit OS
    if [ "$(uname -m)" != "aarch64" ]; then
        error_exit "This script requires a 64-bit OS (aarch64)"
    fi

    # Enhanced memory check with warning
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_mem" -lt 1800 ]; then
        error_exit "Insufficient memory. 2GB RAM minimum required, 4GB+ recommended"
    elif [ "$total_mem" -lt 3800 ]; then
        echo -e "${YELLOW}Warning: Running with less than 4GB RAM might impact performance${NC}"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Enhanced disk space check
    root_space=$(df / | awk 'NR==2 {print $4}')
    if [ "$root_space" -lt 5242880 ]; then  # 5GB in KB
        error_exit "Insufficient disk space. At least 5GB required on root partition"
    fi

    # Check required ports availability
    echo "Checking required ports..."
    for port in 1880 3000 8086; do
        if netstat -tuln | grep -q ":$port "; then
            echo -e "${YELLOW}Warning: Port $port is already in use${NC}"
            read -p "Continue anyway? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                error_exit "Please free port $port before continuing"
            fi
        fi
    done

    # Check for existing installations
    services=("nodered" "influxdb" "grafana-server")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet $service; then
            echo -e "${YELLOW}Warning: $service is already installed and running${NC}"
            read -p "Would you like to reinstall $service? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                error_exit "Please remove or stop existing $service installation first"
            fi
        fi
    done

    echo "✓ System requirements met. Proceeding with installation..."
}

# Verify repository access
check_repositories() {
    echo "Checking repository access..."
    
    # Test NodeSource repository
    if ! curl -sL https://deb.nodesource.com/setup_20.x -o /dev/null; then
        error_exit "Cannot access NodeSource repository"
    fi

    # Test InfluxDB repository
    if ! curl -sL https://repos.influxdata.com/influxdata-archive_compat.key -o /dev/null; then
        error_exit "Cannot access InfluxDB repository"
    fi

    # Test Grafana repository
    if ! curl -sL https://packages.grafana.com/gpg.key -o /dev/null; then
        error_exit "Cannot access Grafana repository"
    fi

    echo "Repository access verified"
}

# Clean up existing Node.js installation
clean_nodejs() {
    echo "Cleaning up existing Node.js installation..."
    sudo apt-get remove -y nodejs npm
    sudo apt-get autoremove -y
    sudo rm -rf /etc/apt/sources.list.d/nodesource.list*
    sudo apt-get update
}

# Install Node.js and verify
install_nodejs() {
    echo "Installing Node.js..."
    
    # Clean up first
    clean_nodejs
    
    # Install Node.js from NodeSource
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || error_exit "Failed to setup Node.js repository" "rollback"
    sudo apt-get install -y nodejs || error_exit "Failed to install Node.js" "rollback"
    
    # Verify installation
    node_version=$(node --version)
    if [[ ! "$node_version" =~ ^v20 ]]; then
        error_exit "Node.js installation failed or wrong version installed" "rollback"
    fi
    
    echo "✓ Node.js $node_version installed successfully"
}

# Install Node-RED with improved handling
install_nodered() {
    echo "Installing Node-RED..."
    
    # Install Node-RED
    echo "Installing Node-RED..."
    sudo npm install -g --unsafe-perm node-red

    # Create Node-RED service
    sudo tee /etc/systemd/system/nodered.service > /dev/null << EOL
    [Unit]
    Description=Node-RED
    After=network.target

    [Service]
    ExecStart=/usr/bin/node-red --max-old-space-size=512
    Restart=on-failure
    User=$SUDO_USER
    Group=$SUDO_USER
    Environment=NODE_ENV=production

    [Install]
    WantedBy=multi-user.target
    EOL

    # Enable and start Node-RED
    sudo systemctl daemon-reload
    sudo systemctl enable nodered
    sudo systemctl start nodered
}

# Add status file to track progress
STATUS_FILE="/tmp/dashboard-install-status"

update_status() {
    echo "$1" > "$STATUS_FILE"
}

check_status() {
    if [ -f "$STATUS_FILE" ]; then
        cat "$STATUS_FILE"
    else
        echo "Not started"
    fi
}

# Add this function for service management
manage_service() {
    local service=$1
    local action=$2
    local port=""
    
    # Assign ports based on service
    case "$service" in
        "nodered") port="1880" ;;
        "influxdb") port="8086" ;;
        "grafana-server") port="3000" ;;
    esac
    
    echo "Managing $service: $action (port $port)"
    
    case "$action" in
        "start")
            sudo systemctl enable $service
            sudo systemctl start $service
            ;;
        *)
            error_exit "Unknown service action: $action"
            ;;
    esac
    
    # Wait for service to be ready and port to be listening
    echo "Waiting for $service to be ready..."
    for i in {1..30}; do  # Increase from 24 to 30 cycles
        if systemctl is-active --quiet $service && netstat -tuln | grep -q ":$port "; then
            echo "✓ $service is running and listening on port $port"
            return 0
        fi
        echo "Waiting... ($i/30)"
        sleep 5
    done
    
    # If we get here, show service status and logs
    echo "Service status:"
    systemctl status $service
    echo "Last 50 log entries:"
    journalctl -u $service --no-pager -n 50
    
    return 1
}

# Update the start_services function
start_services() {
    echo "Starting services..."
    
    # Start Node-RED
    manage_service nodered start || {
        journalctl -u nodered --no-pager -n 50
        error_exit "Failed to start Node-RED" "rollback"
    }
    
    # Start InfluxDB
    manage_service influxdb start || {
        journalctl -u influxdb --no-pager -n 50
        error_exit "Failed to start InfluxDB" "rollback"
    }
    
    # Start Grafana
    sudo systemctl daemon-reload
    manage_service grafana-server start || {
        journalctl -u grafana-server --no-pager -n 50
        error_exit "Failed to start Grafana" "rollback"
    }
    
    echo "All services started successfully!"
}

# Main installation process
main() {
    show_progress 1 "Checking system requirements"
    check_requirements
    
    show_progress 2 "Verifying repository access"
    check_repositories
    
    show_progress 3 "Installing Node.js and Node-RED"
    install_nodejs
    install_nodered
    
    show_progress 4 "Installing InfluxDB"
    install_influxdb
    
    show_progress 5 "Installing Grafana"
    install_grafana
    
    show_progress 6 "Starting and verifying services"
    start_services
    verify_services
    
    print_next_steps
}

# Update verify_services with better error handling
verify_services() {
    echo "Verifying services..."
    
    # Define service ports and endpoints
    declare -A service_config=(
        ["nodered,port"]="1880"
        ["nodered,endpoint"]="/"
        ["influxdb,port"]="8086"
        ["influxdb,endpoint"]="/ping"
        ["grafana-server,port"]="3000"
        ["grafana-server,endpoint"]="/"
    )
    
    for service in nodered influxdb grafana-server; do
        local port="${service_config[$service,port]}"
        local endpoint="${service_config[$service,endpoint]}"
        
        echo "Checking $service (port $port)..."
        
        # More detailed service check
        if ! systemctl is-active --quiet $service; then
            echo "Service $service is not running. Checking logs..."
            systemctl status $service
            journalctl -u $service --no-pager -n 50
            error_exit "Service $service failed to start" "rollback"
        fi
        
        # More detailed port check with netstat and lsof
        echo "Checking port $port..."
        if ! netstat -tuln | grep -q ":$port "; then
            echo "Port check failed. Checking with lsof..."
            sudo lsof -i :$port || true
            error_exit "Port $port is not listening for $service" "rollback"
        fi
        
        # HTTP endpoint check with retry
        echo "Checking endpoint http://localhost:$port$endpoint..."
        for i in {1..6}; do
            if curl -s "http://localhost:$port$endpoint" > /dev/null; then
                break
            fi
            echo "Endpoint not responding, attempt $i/6..."
            sleep 5
            if [ $i -eq 6 ]; then
                error_exit "$service endpoint not responding" "rollback"
            fi
        done
        
        echo "✓ $service verified"
    done
    
    # Check credentials file
    if [ ! -f ~/metsci-credentials.txt ]; then
        error_exit "Credentials file was not created" "rollback"
    fi
    echo "✓ Credentials file created successfully"
    
    echo "All services verified and running!"
}

# Print next steps
print_next_steps() {
    echo "
Installation completed successfully!

Your services are available at:
- Node-RED: http://localhost:1880
- InfluxDB: http://localhost:8086
- Grafana: http://localhost:3000

Next Steps:
1. Save your credentials from ~/metsci-credentials.txt
2. Delete the credentials file: rm ~/metsci-credentials.txt
3. Set up Cloudflare tunnel for remote access (optional)

For troubleshooting, check the log at: $LOG_FILE
"
}

# Add InfluxDB repository
curl -s https://repos.influxdata.com/influxdata-archive_compat.key | sudo apt-key add -
echo "deb https://repos.influxdata.com/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

# Add Grafana repository
curl -s https://apt.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

# Update package lists
sudo apt-get update

# Add InfluxDB repository setup
install_influxdb() {
    echo "Setting up InfluxDB repository..."
    curl -s https://repos.influxdata.com/influxdata-archive_compat.key | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.asc > /dev/null
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.asc] https://repos.influxdata.com/debian stable main" | sudo tee /etc/apt/sources.list.d/influxdata.list

    sudo apt-get update
    sudo apt-get install -y influxdb2 || error_exit "Failed to install InfluxDB"

    # After installation, verify version
    influx_version=$(influx version 2>/dev/null || echo "FAIL")
    if [[ "$influx_version" == "FAIL" ]]; then
        error_exit "InfluxDB installation failed" "rollback"
    fi
    echo "✓ InfluxDB $influx_version installed successfully"
}

# Add Grafana repository setup
install_grafana() {
    echo "Setting up Grafana repository..."
    wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
    echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

    sudo apt-get update
    sudo apt-get install -y grafana || error_exit "Failed to install Grafana"

    # After installation, verify version
    grafana_version=$(grafana-server -v 2>/dev/null || echo "FAIL")
    if [[ "$grafana_version" == "FAIL" ]]; then
        error_exit "Grafana installation failed" "rollback"
    fi
    echo "✓ Grafana $grafana_version installed successfully"
}

# Run the main installation
main


