#!/bin/bash
# This script is designed to be run on a Raspberry Pi with a fresh install of Raspberry Pi OS Lite (64-bit).
# It will install Node-RED, InfluxDB, and Grafana, and configure them to work together for a non-technical user.
# This includes installing the InfluxDB nodes for Node-RED, and configuring Grafana to use the InfluxDB database.
# At the end, the script should print out all the credentials for the user as well as saving them to a local file.
# Prior to running this script, a "secure-pi.sh" script should be run to harden the Pi and prepare it for the dashboard.
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
VERSION="1.5.5"  
echo "MeteoScientific Dashboard Installer v$VERSION"
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
# install_nodejs_and_npm
# Installs Node.js and npm, ensuring both are present
##############################################################################
install_nodejs_and_npm() {
    show_progress "1" "Installing Node.js and npm"
    
    # Remove any existing conflicting packages
    sudo apt-get remove -y nodejs npm || true
    sudo apt-get autoremove -y
    
    # Clean apt cache
    sudo apt-get clean
    sudo apt-get update
    
    # Add NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    
    # Install Node.js (which includes npm)
    sudo apt-get install -y --no-install-recommends nodejs || error_exit "Failed to install Node.js"
    
    # Verify installations
    node -v || error_exit "Node.js installation failed"
    npm -v || error_exit "npm installation failed"
    
    echo "✓ Node.js $(node -v) and npm $(npm -v) installed"
}

##############################################################################
# install_nodered
# Downloads and installs Node-RED
##############################################################################
install_nodered() {
    show_progress "2" "Installing Node-RED"
    
    # Download the Node-RED install script
    echo "Downloading Node-RED installer..."
    curl -fsSL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered \
        -o /tmp/nodered-install.sh || error_exit "Failed to download Node-RED installer"
    
    # Make it executable
    chmod +x /tmp/nodered-install.sh
    
    # Run the installer
    sudo -u $SUDO_USER /tmp/nodered-install.sh --confirm-install --confirm-pi || \
        error_exit "Failed to install Node-RED"
    
    # Clean up
    rm -f /tmp/nodered-install.sh
    
    # Enable and start the service
    sudo systemctl enable nodered.service
    sudo systemctl start nodered.service
    
    # Verify Node-RED is running
    for i in {1..30}; do
        if curl -s http://localhost:1880/ > /dev/null; then
            echo "✓ Node-RED is running"
            break
        fi
        if [ $i -eq 30 ]; then
            error_exit "Node-RED failed to start"
        fi
        sleep 2
    done
}

##############################################################################
# generate_credentials
# Generates secure credentials for all services
##############################################################################
generate_credentials() {
    # Must run this AFTER Node.js/npm installation
    if ! command -v node > /dev/null || ! command -v npm > /dev/null; then
        error_exit "Node.js and npm must be installed before generating credentials"
    }
    
    show_progress "2" "Generating credentials"
    echo "Generating secure credentials..."
    
    # Prompt for organization name first
    echo "What is your organization name? This will be used in Grafana and InfluxDB."
    echo "The default is 'Your Org'"
    read -p "Do you need to change it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your organization name (letters, numbers, and dashes only): " ORG_INPUT
        INFLUXDB_ORG=$(echo "$ORG_INPUT" | sed 's/[^a-zA-Z0-9-]/-/g')
    else
        INFLUXDB_ORG="Your Org"
    fi
    
    # Random username generation from arrays
    NODERED_NAMES=("neo" "morpheus" "trinity" "tank" "dozer" "apoc" "switch" "cypher")
    INFLUXDB_NAMES=("ewok" "wookie" "jedi" "padawan" "rebel" "pilot" "trooper" "droid")
    GRAFANA_NAMES=("stilgar" "paul" "leto" "gurney" "duncan" "thufir" "jessica" "chani")
    
    # Generate random usernames with confirmation
    NODERED_USERNAME=${NODERED_NAMES[$RANDOM % ${#NODERED_NAMES[@]}]}
    echo "The default username for Node-RED is '${NODERED_USERNAME}'"
    read -p "Is this username OK? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your preferred username for Node-RED: " NODERED_USERNAME
    fi
    
    INFLUXDB_USERNAME=${INFLUXDB_NAMES[$RANDOM % ${#INFLUXDB_NAMES[@]}]}
    echo "The default username for InfluxDB is '${INFLUXDB_USERNAME}'"
    read -p "Is this username OK? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your preferred username for InfluxDB: " INFLUXDB_USERNAME
    fi
    
    GRAFANA_USERNAME=${GRAFANA_NAMES[$RANDOM % ${#GRAFANA_NAMES[@]}]}
    echo "The default username for Grafana is '${GRAFANA_USERNAME}'"
    read -p "Is this username OK? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your preferred username for Grafana: " GRAFANA_USERNAME
    fi
    
    # Install node-red-admin globally
    echo "Installing node-red-admin..."
    sudo npm install -g node-red-admin || error_exit "Failed to install node-red-admin"
    
    # Generate passwords and hashes
    NODERED_PASSWORD=$(openssl rand -base64 32)
    NODERED_HASH=$(node-red-admin hash-pw <<< "${NODERED_PASSWORD}" | tail -n1)
    
    INFLUXDB_PASSWORD=$(openssl rand -base64 32)
    INFLUXDB_TOKEN=$(openssl rand -base64 32)
    GRAFANA_PASSWORD=$(openssl rand -base64 32)
    
    echo "✓ Credentials generated and stored"
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
# system_prep
# Updates system and installs prerequisites
##############################################################################
system_prep() {
    show_progress "1" "Updating system"
    echo "Updating system packages..."
    
    # Update package lists and upgrade existing packages
    sudo apt-get update && sudo apt-get upgrade -y || error_exit "System update failed"
    
    echo "Installing prerequisites..."
    sudo apt-get install -y \
        curl \
        jq \
        gnupg \
        apt-transport-https \
        ca-certificates \
        build-essential \
        git || error_exit "Failed to install prerequisites"
        
    echo "✓ System prepared"
}

##############################################################################
# install_influxdb
# Installs and configures InfluxDB
##############################################################################
install_influxdb() {
    show_progress "4" "Installing InfluxDB"
    echo "Installing InfluxDB..."
    
    # Add InfluxDB repository
    wget -qO - https://repos.influxdata.com/influxdb.key | sudo apt-key add - || \
        error_exit "Failed to add InfluxDB key"
    
    echo "deb https://repos.influxdata.com/debian stable main" | \
        sudo tee /etc/apt/sources.list.d/influxdb.list
    
    # Update and install
    sudo apt-get update
    sudo apt-get install -y influxdb2 || error_exit "Failed to install InfluxDB"
    
    # Enable and start service
    sudo systemctl enable influxdb
    sudo systemctl start influxdb
    
    # Wait for InfluxDB to start
    echo "Waiting for InfluxDB to start..."
    for i in {1..30}; do
        if curl -s http://localhost:8086/health | grep -q "ready"; then
            echo "✓ InfluxDB is responding"
            break
        fi
        if [ $i -eq 30 ]; then
            error_exit "InfluxDB failed to start"
        fi
        echo "Waiting... ($i/30)"
        sleep 2
    done
    
    # Run initial setup
    influx setup \
        --org "${INFLUXDB_ORG}" \
        --bucket "sensors" \
        --username "${INFLUXDB_USERNAME}" \
        --password "${INFLUXDB_PASSWORD}" \
        --token "${INFLUXDB_TOKEN}" \
        --force || error_exit "Failed to configure InfluxDB"
    
    echo "✓ InfluxDB installed and configured"
}

##############################################################################
# configure_nodered_influx
# Installs and configures InfluxDB nodes for Node-RED
##############################################################################
configure_nodered_influx() {
    show_progress "5" "Configuring Node-RED for InfluxDB"
    echo "Installing InfluxDB nodes for Node-RED..."
    
    # Change to Node-RED directory
    cd /home/$SUDO_USER/.node-red || error_exit "Failed to access Node-RED directory"
    
    # Install InfluxDB nodes as the correct user
    sudo -u $SUDO_USER npm install node-red-contrib-influxdb || \
        error_exit "Failed to install InfluxDB nodes"
    
    # Create settings.js with InfluxDB configuration
    cat > /home/$SUDO_USER/.node-red/settings.js << EOL
module.exports = {
    adminAuth: {
        type: "credentials",
        users: [{
            username: "${NODERED_USERNAME}",
            password: "${NODERED_HASH}",
            permissions: "*"
        }]
    },
    functionGlobalContext: {
        influxdb: {
            url: 'http://localhost:8086',
            token: '${INFLUXDB_TOKEN}',
            org: '${INFLUXDB_ORG}',
            bucket: 'sensors'
        }
    }
}
EOL
    
    # Set proper ownership
    sudo chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.node-red
    
    # Restart Node-RED
    sudo systemctl restart nodered.service
    
    # Verify Node-RED is still responding after restart
    for i in {1..30}; do
        if curl -s http://localhost:1880/ > /dev/null; then
            echo "✓ Node-RED restarted successfully with InfluxDB nodes"
            break
        fi
        if [ $i -eq 30 ]; then
            error_exit "Node-RED failed to restart after InfluxDB configuration"
        fi
        sleep 2
    done
}

##############################################################################
# install_grafana
# Installs and configures Grafana
##############################################################################
install_grafana() {
    show_progress "6" "Installing Grafana"
    echo "Installing Grafana..."
    
    # Add Grafana repository and key
    wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add - || \
        error_exit "Failed to add Grafana key"
    
    echo "deb https://packages.grafana.com/oss/deb stable main" | \
        sudo tee /etc/apt/sources.list.d/grafana.list
    
    # Update and install Grafana
    sudo apt-get update
    sudo apt-get install -y grafana || error_exit "Failed to install Grafana"
    
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
    
    # Auto-provision InfluxDB data source
    sudo mkdir -p /etc/grafana/provisioning/datasources
    sudo tee /etc/grafana/provisioning/datasources/influxdb.yml > /dev/null << EOL
apiVersion: 1

datasources:
  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://localhost:8086
    jsonData:
      version: Flux
      organization: ${INFLUXDB_ORG}
      defaultBucket: sensors
    secureJsonData:
      token: ${INFLUXDB_TOKEN}
EOL
    
    # Set proper permissions
    sudo chown -R grafana:grafana /etc/grafana
    
    # Enable and start Grafana
    sudo systemctl enable grafana-server
    sudo systemctl start grafana-server
    
    # Verify Grafana is running
    for i in {1..45}; do
        if curl -s http://localhost:3000/api/health | grep -q "ok"; then
            echo "✓ Grafana is responding"
            break
        fi
        if [ $i -eq 45 ]; then
            error_exit "Grafana failed to start"
        fi
        echo "Waiting for Grafana... ($i/45)"
        sleep 2
    done
}

##############################################################################
# verify_full_stack
# Comprehensive verification of the entire stack
##############################################################################
verify_full_stack() {
    show_progress "7" "Verifying full stack integration"
    echo "Performing final integration checks..."
    
    # Verify Node-RED and InfluxDB nodes
    if ! curl -s http://localhost:1880/nodes | grep -q "node-red-contrib-influxdb"; then
        error_exit "InfluxDB nodes not properly installed in Node-RED"
    fi
    
    # Verify InfluxDB organization and bucket
    if ! influx org list | grep -q "${INFLUXDB_ORG}"; then
        error_exit "InfluxDB organization verification failed"
    fi
    
    if ! influx bucket list | grep -q "sensors"; then
        error_exit "InfluxDB bucket verification failed"
    fi
    
    # Verify Grafana can reach InfluxDB
    if ! curl -s -u "${GRAFANA_USERNAME}:${GRAFANA_PASSWORD}" \
        http://localhost:3000/api/datasources/proxy/1/health | grep -q "ready"; then
        error_exit "Grafana cannot connect to InfluxDB"
    fi
    
    echo "✓ Full stack verification complete"
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
# Verifies secure-pi.sh has been run and sets up correct user context
##############################################################################
check_security_setup() {
    echo "Checking security configuration..."
    
    # Check for metsci-service user
    if ! id metsci-service >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: Security setup not detected${NC}"
        echo "Please run secure-pi.sh first:"
        echo "curl -sSL meteoscientific.com/scripts/secure-pi.sh -o secure-pi.sh"
        echo "chmod +x secure-pi.sh && sudo ./secure-pi.sh"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        # Verify the user is set up correctly
        if ! groups metsci-service | grep -q sudo; then
            error_exit "metsci-service user exists but is not in sudo group"
        fi
        
        # Verify Node-RED directory exists and has correct ownership
        if [ ! -d "/home/metsci-service/.node-red" ]; then
            error_exit "Node-RED directory for metsci-service not found"
        fi
        
        if [ "$(stat -c '%U:%G' /home/metsci-service/.node-red)" != "metsci-service:metsci-service" ]; then
            error_exit "Incorrect ownership on Node-RED directory"
        fi
        
        echo "✓ Security setup verified"
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
# print_install_summary
# Displays installation summary and credentials
##############################################################################
print_install_summary() {
    # Get IP address for display
    PI_IP=$(hostname -I | awk '{print $1}')
    
    # Create summary in credentials file
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
# main
# Orchestrates the entire install in a bombproof sequence
##############################################################################
main() {
    # Version and requirements banner
    echo "MeteoScientific Dashboard Installer v1.5.2"
    echo
    echo "Hardware Requirements:"
    echo "- Raspberry Pi 4 (4GB+ RAM recommended)"
    echo "- 32GB+ SD card recommended"
    echo
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        error_exit "Please run as root (use sudo)"
    fi
    
    # 1. Verify security setup and user context
    check_security_setup
    
    # 2. Quick system update check (even though secure-pi should have done this)
    echo "Verifying system is up to date..."
    sudo apt-get update > /dev/null
    
    # Install Node.js and npm first
    install_nodejs_and_npm
    
    # Then generate credentials (now that we have npm)
    generate_credentials
    
    # Install Node-RED
    install_nodered
    
    # 6. Install and configure InfluxDB
    show_progress "3" "Installing InfluxDB"
    install_influxdb
    
    # Verify InfluxDB is running and configured
    verify_influxdb_setup "${INFLUXDB_ORG}" "${INFLUXDB_USERNAME}"
    
    # 7. Install Node-RED InfluxDB nodes (only after InfluxDB is verified)
    show_progress "4" "Installing InfluxDB nodes for Node-RED"
    configure_nodered_influx
    
    # 8. Install and configure Grafana
    show_progress "5" "Installing Grafana"
    install_grafana
    
    # 9. Final integration verification
    show_progress "6" "Verifying full stack"
    verify_full_stack
    
    # 10. Display credentials and completion message
    echo
    echo "======= MeteoScientific Demo Dashboard ========"
    echo
    echo "Installation completed successfully!"
    echo
    echo "1. Node-RED Credentials"
    echo "   - Username: ${NODERED_USERNAME}"
    echo "   - Password: ${NODERED_PASSWORD}"
    echo
    echo "2. InfluxDB Credentials"
    echo "   - Username: ${INFLUXDB_USERNAME}"
    echo "   - Password: ${INFLUXDB_PASSWORD}"
    echo "   - Organization: ${INFLUXDB_ORG}"
    echo "   - Bucket: sensors"
    echo "   - Token: ${INFLUXDB_TOKEN}"
    echo
    echo "3. Grafana Credentials"
    echo "   - Username: ${GRAFANA_USERNAME}"
    echo "   - Password: ${GRAFANA_PASSWORD}"
    echo
    echo "⚠️  IMPORTANT: Save these credentials and delete the credentials file!"
    echo "   (${CREDS_FILE})"
    echo
    echo "Services are accessible at:"
    echo "   Node-RED: http://$(hostname -I | awk '{print $1}'):1880"
    echo "   InfluxDB: http://$(hostname -I | awk '{print $1}'):8086"
    echo "   Grafana:  http://$(hostname -I | awk '{print $1}'):3000"
    echo
    echo "For troubleshooting, check the log at: ${LOG_FILE}"
    echo "=============================================="
    echo
    
    # Save credentials to file
    save_credentials
    
    # Offer to show the installation log
    show_install_log
}

# Start the installation
main
