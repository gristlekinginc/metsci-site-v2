#!/bin/bash
# This script is designed to be run on a Raspberry Pi with a fresh install of Raspberry Pi OS Lite (64-bit).
# It will install Node-RED, InfluxDB, and Grafana, and configure them to work together.
# Use at your own risk, and be ready to wipe your Pi and start over if it doesn't work. Yeehaw!

#----------------------------------------------------------------------
# Colors
#----------------------------------------------------------------------
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#----------------------------------------------------------------------
# Script Version Info
#----------------------------------------------------------------------
VERSION="1.5.0"  
echo "MeteoScientific Dashboard Installer v$VERSION"
echo
echo "Hardware Requirements:"
echo "- Raspberry Pi 4 (4GB+ RAM recommended)"
echo "- 32GB+ SD card recommended"

#----------------------------------------------------------------------
# Globals
#----------------------------------------------------------------------
CREDS_FILE="/home/$SUDO_USER/metsci-credentials.txt"
ENV_FILE="/etc/metsci-dashboard/.env"
STATUS_FILE="/tmp/dashboard-install-status"
LOG_FILE="/var/log/metsci-dashboard-install-$(date +%Y%m%d-%H%M%S).log"

# Set up logging (capture both stdout and stderr)
exec 1> >(tee -a "$LOG_FILE") 2>&1

# Arrays used for random username generation
NODERED_NAMES=("neo" "morpheus" "trinity" "oracle" "tank" "dozer" "switch" "apoc" "niobe" "commander")
INFLUXDB_NAMES=("skywalker" "kenobi" "yoda" "windu" "ewok" "bobafett" "lando" "vader" "hansolo" "wookie" "salaciouscrumb")
GRAFANA_NAMES=("muaddib" "chani" "stilgar" "leto" "ghanima" "irulan" "hawat" "kynes" "gurney" "idaho" "fenring")

#----------------------------------------------------------------------
# Functions
#----------------------------------------------------------------------

##############################################################################
# show_progress
# Prints a "step X of Y" banner with a message and timestamp.
##############################################################################
show_progress() {
    local step="$1"
    local total="9"
    local message="$2"
    
    echo ""
    echo "==================================================================="
    echo "Progress: Step $step of $total"
    echo "Current: $message"
    echo "Status:  $(date '+%H:%M:%S')"
    echo "==================================================================="
    echo ""
}

##############################################################################
# error_exit
# Prints an error, optionally calls rollback, then exits.
##############################################################################
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    echo "Check $LOG_FILE for details."
    if [ "$2" = "rollback" ]; then
        perform_rollback
    fi
    exit 1
}

##############################################################################
# perform_rollback
# Attempts to remove partial installations if the script fails mid-way.
##############################################################################
perform_rollback() {
    echo "Installation failed. Rolling back changes..."
    
    for service in nodered influxdb grafana-server; do
        if systemctl is-active --quiet $service; then
            sudo systemctl stop $service
            sudo systemctl disable $service
        fi
    done

    sudo apt-get remove -y nodejs npm influxdb2 grafana
    sudo apt-get autoremove -y
    sudo rm -rf /etc/metsci-dashboard
    sudo rm -rf /home/$SUDO_USER/.node-red
    sudo rm -f "$ENV_FILE"
    sudo rm -f "$CREDS_FILE"

    echo "Rollback complete. Please check the error message above and try again."
}

##############################################################################
# install_prerequisites
# Ensures required packages (net-tools, curl, jq) are installed.
##############################################################################
install_prerequisites() {
    command -v netstat >/dev/null 2>&1 || {
        echo "Installing net-tools..."
        sudo apt-get update && sudo apt-get install -y net-tools
    }

    command -v curl >/dev/null 2>&1 || {
        echo "Installing curl..."
        sudo apt-get update && sudo apt-get install -y curl
    }

    command -v jq >/dev/null 2>&1 || {
        echo "Installing jq..."
        sudo apt-get update && sudo apt-get install -y jq
    }
}

##############################################################################
# configure_grafana
# Sets up Grafana security and configuration.
##############################################################################
configure_grafana() {
    echo "Configuring Grafana security..."
    
    # Update Grafana configuration file
    sudo tee /etc/grafana/grafana.ini > /dev/null << EOL
[security]
admin_user = ${GRAFANA_USERNAME}
admin_password = ${GRAFANA_PASSWORD}

[auth]
disable_login_form = false

[auth.anonymous]
enabled = true
org_role = Viewer

[feature_toggles]
publicDashboards = true
EOL

    sudo chown grafana:grafana /etc/grafana/grafana.ini
    sudo chmod 640 /etc/grafana/grafana.ini
    
    # Restart Grafana to apply changes
    sudo systemctl restart grafana-server
    sleep 10  # Give Grafana time to restart
    
    echo "✓ Grafana security configured"
}

##############################################################################
# configure_memory_limits
# Configures memory limits for services.
##############################################################################
configure_memory_limits() {
    echo "Configuring memory limits for services..."
    
    # Create override directories if they don't exist
    sudo mkdir -p /etc/systemd/system/nodered.service.d
    sudo mkdir -p /etc/systemd/system/influxdb.service.d
    sudo mkdir -p /etc/systemd/system/grafana-server.service.d
    
    # Node-RED memory limit (1GB max)
    sudo tee /etc/systemd/system/nodered.service.d/override.conf > /dev/null << EOL
[Service]
Environment=NODE_OPTIONS=--max_old_space_size=1024
EOL

    # InfluxDB memory limits (1.5GB max)
    sudo tee /etc/systemd/system/influxdb.service.d/override.conf > /dev/null << EOL
[Service]
Environment=INFLUXD_BOLT_MAX_CACHE=512MB
Environment=INFLUXD_MAX_CONCURRENT_COMPACTIONS=2
EOL

    # Grafana memory optimization - only append if not already present
    if ! grep -q "\[analytics\]" /etc/grafana/grafana.ini; then
        sudo tee -a /etc/grafana/grafana.ini > /dev/null << EOL
[analytics]
reporting_enabled = false

[metrics]
enabled = false

[dashboards]
versions_to_keep = 5
EOL
    fi

    sudo systemctl daemon-reload
}

##############################################################################
# configure_log_rotation
# Configures log rotation for services.
##############################################################################
configure_log_rotation() {
    sudo tee /etc/logrotate.d/metsci-dashboard > /dev/null << EOL
/var/log/nodered.log
/var/log/influxdb/*.log
/var/log/grafana/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}
EOL
}

##############################################################################
# generate_credentials
# Asks for org/usernames, generates random passwords, writes them to .env and
# a local credentials file for reference.
##############################################################################
generate_credentials() {
    echo "Generating secure credentials..."
    
    # Ask for organization name
    DEFAULT_ORG="Your Org"
    echo "What is your organization name? This will be used in Grafana and InfluxDB."
    echo "The default is '${DEFAULT_ORG}'"
    read -p "Do you need to change it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your organization name (letters, numbers, and dashes only): " INFLUXDB_ORG
        # Remove spaces & special chars, convert to lowercase
        INFLUXDB_ORG=$(echo "$INFLUXDB_ORG" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
        if [ -z "$INFLUXDB_ORG" ]; then
            INFLUXDB_ORG=$DEFAULT_ORG
            echo "Using default organization: $DEFAULT_ORG"
        fi
    else
        INFLUXDB_ORG=$DEFAULT_ORG
    fi
    
    # Helper function to pick random name from array
    get_random_name() {
        local arr=("$@")
        echo "${arr[RANDOM % ${#arr[@]}]}"
    }
    
    # Generate default usernames
    DEFAULT_NODERED_USER=$(get_random_name "${NODERED_NAMES[@]}")
    DEFAULT_INFLUXDB_USER=$(get_random_name "${INFLUXDB_NAMES[@]}")
    DEFAULT_GRAFANA_USER=$(get_random_name "${GRAFANA_NAMES[@]}")
    
    # Node-RED username
    echo "The default username for Node-RED is '${DEFAULT_NODERED_USER}'"
    read -p "Is this username OK? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        while true; do
            read -p "Enter new Node-RED username (anything but 'admin'): " NODERED_USERNAME
            if [ "$NODERED_USERNAME" != "admin" ]; then
                break
            else
                echo "Please choose a different username."
            fi
        done
    else
        NODERED_USERNAME=$DEFAULT_NODERED_USER
    fi
    
    # InfluxDB username
    echo "The default username for InfluxDB is '${DEFAULT_INFLUXDB_USER}'"
    read -p "Is this username OK? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        while true; do
            read -p "Enter new InfluxDB username (anything but 'admin'): " INFLUXDB_USERNAME
            if [ "$INFLUXDB_USERNAME" != "admin" ]; then
                break
            else
                echo "Please choose a different username."
            fi
        done
    else
        INFLUXDB_USERNAME=$DEFAULT_INFLUXDB_USER
    fi
    
    # Grafana username
    echo "The default username for Grafana is '${DEFAULT_GRAFANA_USER}'"
    read -p "Is this username OK? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        while true; do
            read -p "Enter new Grafana username (anything but 'admin'): " GRAFANA_USERNAME
            if [ "$GRAFANA_USERNAME" != "admin" ]; then
                break
            else
                echo "Please choose a different username."
            fi
        done
    else
        GRAFANA_USERNAME=$DEFAULT_GRAFANA_USER
    fi
    
    # Generate random passwords
    NODERED_PASSWORD=$(openssl rand -base64 24)
    INFLUXDB_PASSWORD=$(openssl rand -base64 24)
    GRAFANA_PASSWORD=$(openssl rand -base64 24)
    INFLUXDB_TOKEN=$(openssl rand -base64 32)
    
    # Write to local credentials file
    cat > "$CREDS_FILE" << EOL
MeteoScientific Dashboard Credentials
====================================
Generated on: $(date)

Node-RED:
Username: $NODERED_USERNAME
Password: $NODERED_PASSWORD

InfluxDB:
Username: $INFLUXDB_USERNAME
Password: $INFLUXDB_PASSWORD
Organization: $INFLUXDB_ORG
Bucket: sensors
Token: $INFLUXDB_TOKEN

Grafana:
Username: $GRAFANA_USERNAME
Password: $GRAFANA_PASSWORD

Save these credentials and delete this file!
EOL

    # Write to environment file
    sudo mkdir -p /etc/metsci-dashboard
    sudo chmod 700 /etc/metsci-dashboard
    
    sudo tee "$ENV_FILE" > /dev/null << EOL
# MeteoScientific Dashboard Environment
NODERED_USERNAME=$NODERED_USERNAME
NODERED_PASSWORD=$NODERED_PASSWORD
INFLUXDB_USERNAME=$INFLUXDB_USERNAME
INFLUXDB_PASSWORD=$INFLUXDB_PASSWORD
INFLUXDB_TOKEN=$INFLUXDB_TOKEN
INFLUXDB_ORG=$INFLUXDB_ORG
INFLUXDB_BUCKET=sensors
GRAFANA_USERNAME=$GRAFANA_USERNAME
GRAFANA_PASSWORD=$GRAFANA_PASSWORD
EOL

    sudo chmod 600 "$ENV_FILE"
    sudo chown root:root "$ENV_FILE"

    echo "✓ Credentials generated and stored"
    print_install_summary
}

##############################################################################
# check_requirements
# Checks if we are on RPi 64-bit, memory, disk space, free ports, connectivity.
##############################################################################
check_requirements() {
    echo "Performing system checks..."

    # Check if running on Pi
    if ! grep -q "Raspberry Pi" /proc/cpuinfo; then
        error_exit "This script must be run on a Raspberry Pi."
    fi

    # Check for 64-bit OS
    if [ "$(uname -m)" != "aarch64" ]; then
        error_exit "This script requires a 64-bit OS (aarch64)."
    fi

    # Check RAM
    total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 1800 ]; then
        error_exit "Insufficient memory. 2GB RAM minimum required."
    elif [ "$total_ram" -lt 4000 ]; then
        echo -e "${YELLOW}⚠️  Warning: This Pi has less than 4GB RAM ($total_ram MB)${NC}"
        echo "The dashboard will work great for most small IoT setups. You might see performance impacts if you're:
- Collecting data from 50+ sensors every minute
- Running complex real-time calculations
- Supporting many simultaneous dashboard users
- Storing and querying years of historical data"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Check disk space
    available_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_space" -lt 16 ]; then
        echo -e "${YELLOW}⚠️  Warning: Less than 16GB free space available ($available_space GB)${NC}"
        echo "You may run out of space when collecting data."
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Check required ports
    for port in 1880 3000 8086; do
        if netstat -tuln | grep -q ":$port "; then
            error_exit "Port $port is already in use. Please free it before continuing."
        fi
    done

    # Check internet connectivity
    if ! ping -c 1 -W 5 google.com &> /dev/null; then
        error_exit "Internet connection required. Check your network."
    fi

    echo "✓ System requirements met"
}

##############################################################################
# install_nodejs
# Installs Node.js (v20.x) via NodeSource, cleans up partial installs first.
##############################################################################
install_nodejs() {
    show_progress "4" "Installing Node.js"
    echo "Installing Node.js..."
    
    # Clean up any failed installations (from v1)
    sudo apt-get remove -y nodejs npm || true
    sudo apt-get autoremove -y
    sudo rm -rf /etc/apt/sources.list.d/nodesource.list*
    
    # Add NodeSource repository (from v1)
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || error_exit "Failed to add NodeSource repository"
    
    # Install Node.js (from v1)
    sudo apt-get install -y nodejs || error_exit "Failed to install Node.js"
    
    # Update npm to latest version (from v1)
    sudo npm install -g npm@latest || error_exit "Failed to update npm"
    
    echo "✓ Node.js v$(node --version) (npm $(npm --version)) installed successfully"
}

##############################################################################
# install_nodered
# Installs Node-RED and configures InfluxDB integration
##############################################################################
install_nodered() {
    show_progress "5" "Installing Node-RED"
    echo "Installing Node-RED..."
    
    # Use official Node-RED install script with automatic confirmation
    bash <(curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered) --confirm-install --confirm-pi || error_exit "Failed to install Node-RED"
    
    # Enable and start the service
    sudo systemctl enable nodered.service
    sudo systemctl start nodered.service
    
    # Wait for Node-RED to start
    echo "Waiting for Node-RED to start..."
    for i in {1..30}; do
        if curl -s http://localhost:1880/ > /dev/null; then
            break
        fi
        echo "Waiting for Node-RED... ($i/30)"
        sleep 2
    done
    
    # Install InfluxDB nodes
    echo "Installing InfluxDB integration..."
    cd /home/$SUDO_USER/.node-red || error_exit "Failed to change directory"
    npm install node-red-contrib-influxdb || error_exit "Failed to install InfluxDB nodes"
    
    # Create a basic flow connecting to InfluxDB
    cat > /home/$SUDO_USER/.node-red/flows.json << EOL
[
    {
        "id": "influxdb-config",
        "type": "influxdb",
        "hostname": "localhost",
        "port": "8086",
        "protocol": "http",
        "database": "sensors",
        "name": "InfluxDB Connection",
        "influxdbVersion": "2.0",
        "url": "http://localhost:8086",
        "token": "${INFLUXDB_TOKEN}",
        "org": "${INFLUXDB_ORG}",
        "bucket": "sensors"
    }
]
EOL
    
    # Set proper ownership
    sudo chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.node-red
    
    # Restart Node-RED to load new nodes and flow
    sudo systemctl restart nodered.service
    
    echo "✓ Node-RED installed and configured with InfluxDB integration"
}

##############################################################################
# install_influxdb
# Installs and configures InfluxDB v2
##############################################################################
install_influxdb() {
    show_progress "6" "Installing InfluxDB"
    echo "Installing InfluxDB..."
    
    # Import InfluxData GPG key
    curl -s https://repos.influxdata.com/influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg >/dev/null
    
    # Add InfluxDB repository
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main" | sudo tee /etc/apt/sources.list.d/influxdb.list
    
    # Install InfluxDB
    sudo apt-get update && sudo apt-get install -y influxdb2 influxdb2-cli || error_exit "Failed to install InfluxDB"
    
    # Start InfluxDB service
    sudo systemctl enable influxdb
    sudo systemctl start influxdb
    
    # Wait for InfluxDB to start
    echo "Waiting for InfluxDB to start..."
    for i in {1..30}; do
        if curl -s http://localhost:8086/health | grep -q "ready"; then
            echo "InfluxDB is responding to health checks. Waiting additional time for full initialization..."
            sleep 5
            break
        fi
        echo "Waiting for InfluxDB... ($i/30)"
        sleep 2
    done
    
    # Setup initial user and organization
    echo "Setting up InfluxDB..."
    influx setup \
        --org "${INFLUXDB_ORG}" \
        --bucket "sensors" \
        --username "${INFLUXDB_USERNAME}" \
        --password "${INFLUXDB_PASSWORD}" \
        --token "${INFLUXDB_TOKEN}" \
        --force || error_exit "Failed to setup InfluxDB"
        
    # Verify setup
    verify_influxdb "${INFLUXDB_ORG}" "${INFLUXDB_USERNAME}"
}

##############################################################################
# install_grafana
# Installs and configures Grafana
##############################################################################
install_grafana() {
    show_progress "7" "Installing Grafana"
    echo "Installing Grafana..."
    
    # Stop any existing Grafana service
    sudo systemctl stop grafana-server || true
    
    # Add Grafana GPG key
    curl -fsSL https://packages.grafana.com/gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/grafana.gpg
    
    # Add Grafana repository
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/grafana.gpg] https://packages.grafana.com/oss/deb stable main" | \
        sudo tee /etc/apt/sources.list.d/grafana.list
    
    # Install Grafana
    sudo apt-get update && sudo apt-get install -y grafana || error_exit "Failed to install Grafana"
    
    # Create required directories with proper permissions
    sudo mkdir -p /var/lib/grafana
    sudo chown -R grafana:grafana /var/lib/grafana
    
    # Configure Grafana
    sudo tee /etc/grafana/grafana.ini > /dev/null << EOL
[security]
admin_user = ${GRAFANA_USERNAME}
admin_password = ${GRAFANA_PASSWORD}

[auth.anonymous]
enabled = true
org_role = Viewer

[feature_toggles]
publicDashboards = true
EOL

    # Set proper permissions
    sudo chown -R grafana:grafana /etc/grafana/grafana.ini
    sudo chmod 640 /etc/grafana/grafana.ini
    
    # Start Grafana
    sudo systemctl daemon-reload
    sudo systemctl enable grafana-server
    sudo systemctl start grafana-server
    
    # Wait for Grafana to start
    echo "Waiting for Grafana to start..."
    for i in {1..45}; do
        if curl -s http://localhost:3000/api/health | grep -q "ok"; then
            echo "✓ Grafana is responding"
            break
        fi
        echo "Waiting for Grafana... ($i/45)"
        sleep 2
    done
}

##############################################################################
# start_services
# Enables & starts all services, waits a bit for them to fully initialize.
##############################################################################
start_services() {
    echo "Starting services..."
    
    for service in nodered influxdb grafana-server; do
        echo "Starting $service..."
        sudo systemctl enable $service
        sudo systemctl start $service || error_exit "Failed to start $service" "rollback"
        echo "✓ $service started"
    done
    
    echo "Waiting for services to initialize..."
    sleep 10
}

##############################################################################
# verify_services
# Verifies all services are running correctly
##############################################################################
verify_services() {
    echo "Verifying services..."
    
    # Verify Node-RED
    if ! curl -s http://localhost:1880/ > /dev/null; then
        error_exit "Node-RED is not responding"
    fi
    
    # Verify InfluxDB
    if ! curl -s http://localhost:8086/health | grep -q "ready"; then
        error_exit "InfluxDB is not responding"
    fi
    
    # Verify Grafana
    if ! curl -s http://localhost:3000/api/health | grep -q "ok"; then
        error_exit "Grafana is not responding"
    fi
    
    echo "✓ All services verified"
}

##############################################################################
# show_install_log
# Displays the full installation log.
##############################################################################
show_install_log() {
    echo
    echo "Would you like to see the full installation log? (y/n) "
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        less "$LOG_FILE"
    fi
}

##############################################################################
# save_credentials
# Saves all credentials to a file and displays them
##############################################################################
save_credentials() {
    # Get IP address for display
    PI_IP=$(hostname -I | awk '{print $1}')
    
    # Save credentials to file
    cat > "${CREDS_FILE}" << EOL
======= MeteoScientific Demo Dashboard ========

Installation completed successfully!

1. Node-RED Credentials
   - Username: ${NODERED_USERNAME}
   - Password: ${NODERED_PASSWORD}

2. InfluxDB Credentials
   - Username: ${INFLUXDB_USERNAME}
   - Password: ${INFLUXDB_PASSWORD}
   - Organization: ${INFLUXDB_ORG}
   - Bucket: sensors
   - Token: ${INFLUXDB_TOKEN}

Use @InfluxDBv2 @Grafana @Node-RED and @https://flows.nodered.org/node/node-red-contrib-influxdb for the installation of InfluxDB nodes in Node-RED.

3. Grafana Credentials
   - Username: ${GRAFANA_USERNAME}
   - Password: ${GRAFANA_PASSWORD}

⚠️  IMPORTANT: Save these credentials and delete the credentials file!
   (${CREDS_FILE})

Services are accessible at:
   Node-RED: http://${PI_IP}:1880
   InfluxDB: http://${PI_IP}:8086
   Grafana:  http://${PI_IP}:3000

For troubleshooting, check the log at: ${LOG_FILE}
==============================================
EOL

    # Set proper permissions on credentials file
    chmod 600 "${CREDS_FILE}"
    chown "${SUDO_USER}:${SUDO_USER}" "${CREDS_FILE}"
    
    # Display the credentials
    cat "${CREDS_FILE}"
}

##############################################################################
# print_completion
# Displays final success message
##############################################################################
print_completion() {
    echo
    echo "Installation complete! 🎉"
    echo
    echo "Your credentials have been saved to: ${CREDS_FILE}"
    echo "Please save these credentials somewhere safe and then delete the file."
    echo
    echo "To get started:"
    echo "1. Open Node-RED: http://${PI_IP}:1880"
    echo "2. Import the example flows from the documentation"
    echo "3. Configure your InfluxDB connection using the token above"
    echo "4. Start collecting data!"
    echo
    echo "Need help? Visit: https://meteoscientific.com/docs"
}

##############################################################################
# check_security_setup
# Checks if secure-pi.sh has been run
##############################################################################
check_security_setup() {
    if ! id metsci-service >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: Security setup not detected. It's recommended to run secure-pi.sh first.${NC}"
        echo "Get it from: https://github.com/gristlekinginc/metsci-site-v2/blob/main/docs/scripts/secure-pi.sh"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        # Use metsci-service user if it exists
        SUDO_USER="metsci-service"
        # Verify home directory exists
        if [ ! -d "/home/$SUDO_USER" ]; then
            error_exit "Home directory for $SUDO_USER does not exist"
        fi
    fi
}

##############################################################################
# Function to verify InfluxDB setup
##############################################################################
verify_influxdb_setup() {
    local org=$1
    local username=$2
    local bucket="sensors"
    
    # Verify organization exists
    if ! influx org list | grep -q "$org"; then
        error_exit "Organization verification failed" "rollback"
    fi
    
    # Verify user exists
    if ! influx user list | grep -q "$username"; then
        error_exit "User verification failed" "rollback"
    fi
    
    # Verify bucket exists
    if ! influx bucket list --org "$org" | grep -q "$bucket"; then
        error_exit "Bucket verification failed" "rollback"
    fi
    
    # Verify token works
    if ! influx auth ls --user "$username" &>/dev/null; then
        error_exit "Token verification failed" "rollback"
    fi
    
    echo "✓ InfluxDB setup verified successfully"
}

##############################################################################
# main
# Orchestrates the entire install in a step-by-step fashion.
##############################################################################
main() {
    check_security_setup
    show_progress 1 "Checking system requirements"
    check_requirements
    
    show_progress 2 "Installing prerequisites"
    install_prerequisites
    
    show_progress 3 "Gathering user preferences"
    generate_credentials
    
    echo
    echo "All required information collected. Beginning installation..."
    echo "This may take several minutes. You can monitor progress in: $LOG_FILE"
    echo
    
    show_progress 4 "Installing Node.js"
    install_nodejs
    
    show_progress 5 "Installing Node-RED"
    install_nodered
    
    show_progress 6 "Installing InfluxDB"
    install_influxdb
    
    show_progress 7 "Installing Grafana"
    install_grafana
    
    show_progress 8 "Optimizing system configuration"
    configure_memory_limits
    configure_log_rotation
    
    show_progress 9 "Starting and verifying services"
    start_services
    verify_services
    
    print_completion
}

# Run the main function
main
