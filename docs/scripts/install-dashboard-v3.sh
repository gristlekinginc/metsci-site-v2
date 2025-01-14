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
VERSION="1.2.8"  
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
LOG_FILE="/tmp/dashboard-install-$(date +%Y%m%d-%H%M%S).log"

# Set up logging (capture both stdout and stderr)
exec 1> >(tee -a "$LOG_FILE") 2>&1

# Arrays used for random username generation
NODERED_NAMES=("neo" "morpheus" "trinity" "oracle" "tank" "dozer" "switch" "apoc" "niobe" "link" "commander")
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
# print_install_summary
# Shows summary of services to be installed, gets user confirmation.
##############################################################################
print_install_summary() {
    echo
    echo "Installation Summary"
    echo "--------------------"
    echo
    echo "The following services will be installed:"
    echo "  1. Node-RED"
    echo "  2. InfluxDB"
    echo "  3. Grafana"
    echo
    echo "Credentials will be displayed after successful installation."
    echo
    read -p "Continue with installation? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
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
    echo "Installing Node.js..."
    
    # Clean up any failed installations
    sudo apt-get remove -y nodejs npm || true
    sudo apt-get autoremove -y
    sudo rm -rf /etc/apt/sources.list.d/nodesource.list*
    
    # Add NodeSource repository
    echo "Adding NodeSource repository..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || {
        error_exit "Failed to add NodeSource repository" "rollback"
    }
    
    # Install Node.js
    echo "Installing Node.js packages..."
    sudo apt-get install -y nodejs || {
        error_exit "Failed to install Node.js" "rollback"
    }
    
    # Update npm to latest version
    echo "Updating npm to latest version..."
    sudo npm install -g npm@latest || {
        error_exit "Failed to update npm" "rollback"
    }
    
    node_version=$(node --version)
    npm_version=$(npm --version)
    echo "✓ Node.js $node_version (npm $npm_version) installed successfully"
}

##############################################################################
# install_nodered
# Installs Node-RED globally and sets up a systemd service under $SUDO_USER.
##############################################################################
install_nodered() {
    echo "Installing Node-RED..."
    
    # Install Node-RED
    sudo npm install -g --unsafe-perm node-red
    
    # Create settings directory
    sudo mkdir -p /home/$SUDO_USER/.node-red
    
    # Create settings.js with basic auth
    cat > /home/$SUDO_USER/.node-red/settings.js << EOF
module.exports = {
    uiPort: process.env.PORT || 1880,
    mqttReconnectTime: 15000,
    serialReconnectTime: 15000,
    debugMaxLength: 1000,
    functionGlobalContext: {},
    
    // Basic auth for simplicity - protected by Cloudflare Zero Trust
    adminAuth: {
        type: "credentials",
        users: [{
            username: "$NODERED_USERNAME",
            password: "$NODERED_PASSWORD",
            permissions: "*"
        }]
    },
    
    editorTheme: {
        projects: {
            enabled: false
        }
    },
    
    influxdb: {
        url: 'http://localhost:8086',
        token: '$INFLUXDB_TOKEN',
        org: '$INFLUXDB_ORG',
        bucket: 'sensors'
    },
    
    credentialSecret: false,
    
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        }
    }
}
EOF
    
    # Set proper ownership
    sudo chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.node-red
    
    # Create service file
    sudo tee /etc/systemd/system/nodered.service > /dev/null << EOL
[Unit]
Description=Node-RED
After=network.target

[Service]
ExecStart=/usr/bin/node-red --userDir /home/$SUDO_USER/.node-red
Restart=on-failure
User=$SUDO_USER
Group=$SUDO_USER

[Install]
WantedBy=multi-user.target
EOL
    
    # Enable and start Node-RED
    sudo systemctl daemon-reload
    sudo systemctl enable nodered
    sudo systemctl start nodered
    
    echo "✓ Node-RED installed and configured"
}

##############################################################################
# install_influxdb
# Installs InfluxDB 2.x, sets up an org/bucket, and updates token for Node-RED.
##############################################################################
install_influxdb() {
    echo "Installing InfluxDB..."
    source "$ENV_FILE"
    
    # Install InfluxDB
    wget -q https://repos.influxdata.com/influxdata-archive_compat.key
    echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
    echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
    
    sudo apt-get update && sudo apt-get install -y influxdb2
    
    # Start InfluxDB
    sudo systemctl enable influxdb
    sudo systemctl start influxdb
    
    # Wait for InfluxDB to be ready
    echo "Waiting for InfluxDB to start..."
    sleep 10
    
    # Initialize InfluxDB (token already in ENV_FILE from generate_credentials)
    echo "Setting up InfluxDB..."
    influx setup \
        --username "$INFLUXDB_USERNAME" \
        --password "$INFLUXDB_PASSWORD" \
        --org "$INFLUXDB_ORG" \
        --bucket "sensors" \
        --retention 365d \
        --token "$INFLUXDB_TOKEN" \
        --force 2>/dev/null || error_exit "Failed to initialize InfluxDB"
    
    # Verify setup with increased timeout
    max_attempts=30
    attempt=1
    while ! influx bucket list --org "$INFLUXDB_ORG" | grep -q "sensors"; do
        if [ $attempt -ge $max_attempts ]; then
            error_exit "InfluxDB setup verification failed after 30 attempts" "rollback"
        fi
        echo "Waiting for InfluxDB to be ready... (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    echo "✓ InfluxDB installed and configured"
}

##############################################################################
# install_grafana
# Installs and configures Grafana.
##############################################################################
install_grafana() {
    echo "Installing Grafana..."
    source "$ENV_FILE"
    
    # Add Grafana repository and key
    curl -fsSL https://packages.grafana.com/gpg.key \
        | sudo gpg --dearmor -o /usr/share/keyrings/grafana.gpg
    echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" \
        | sudo tee /etc/apt/sources.list.d/grafana.list
    
    sudo apt-get update
    sudo apt-get install -y grafana || error_exit "Failed to install Grafana"
    
    # Enable and start Grafana
    sudo systemctl daemon-reload
    sudo systemctl enable grafana-server
    sudo systemctl start grafana-server
    
    # Wait for Grafana to be ready
    echo "Waiting for Grafana to start..."
    for i in {1..30}; do
        if curl -s http://localhost:3000/api/health >/dev/null; then
            echo "Grafana is responding to health checks."
            break
        fi
        echo "Waiting for Grafana... ($i/30)"
        sleep 2
        if [ $i -eq 30 ]; then
            journalctl -u grafana-server --no-pager -n 50
            error_exit "Grafana failed to respond to health checks" "rollback"
        fi
    done
    
    # Call configure_grafana after installation
    configure_grafana || error_exit "Failed to configure Grafana" "rollback"
    
    echo "✓ Grafana installed and configured with user: $GRAFANA_USERNAME"
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
# Checks each service port and then does a final systemctl is-active check.
##############################################################################
verify_services() {
    echo "Verifying all services are running..."
    
    # Node-RED port check
    echo "Checking Node-RED on port 1880..."
    for i in {1..30}; do
        if curl -s http://localhost:1880/ >/dev/null; then
            echo "✓ Node-RED verified"
            break
        fi
        echo "Waiting for Node-RED... ($i/30)"
        sleep 2
        if [ $i -eq 30 ]; then
            error_exit "Node-RED is not responding on port 1880" "rollback"
        fi
    done
    
    # InfluxDB port check
    echo "Checking InfluxDB on port 8086..."
    for i in {1..30}; do
        if curl -s http://localhost:8086/health >/dev/null; then
            echo "✓ InfluxDB port verified"
            verify_influxdb_setup "$INFLUXDB_ORG" "$INFLUXDB_USERNAME"
            break
        fi
        echo "Waiting for InfluxDB... ($i/30)"
        sleep 2
        if [ $i -eq 30 ]; then
            error_exit "InfluxDB is not responding on port 8086" "rollback"
        fi
    done
    
    # Grafana port check
    echo "Checking Grafana on port 3000..."
    for i in {1..30}; do
        if curl -s http://localhost:3000/api/health >/dev/null; then
            echo "✓ Grafana verified"
            break
        fi
        echo "Waiting for Grafana... ($i/30)"
        sleep 2
        if [ $i -eq 30 ]; then
            journalctl -u grafana-server --no-pager -n 50
            error_exit "Grafana is not responding on port 3000" "rollback"
        fi
    done
    
    # Final verification: ensure systemctl sees them as active
    echo "Final systemctl check..."
    for service in nodered influxdb grafana-server; do
        if ! systemctl is-active --quiet $service; then
            error_exit "Service $service failed final verification" "rollback"
        fi
    done
    echo "✓ All services passed final verification."
    
    # Verify memory usage after services are running
    echo "Checking memory usage..."
    memory_used=$(free -m | awk '/^Mem:/ {print int($3/$2 * 100)}')
    if [ "$memory_used" -gt 85 ]; then
        echo -e "${YELLOW}⚠️  Warning: High memory usage ($memory_used%). Consider reducing service memory limits.${NC}"
    else
        echo "✓ Memory usage acceptable ($memory_used%)"
    fi
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
# print_completion
# Displays final info about credentials and endpoints.
##############################################################################
print_completion() {
    clear
    source "$ENV_FILE"
    
    echo "======= MeteoScientific Demo Dashboard ========"
    echo
    echo "Installation completed successfully!"
    echo
    echo "1. Node-RED Credentials"
    echo "   - Username: $NODERED_USERNAME"
    echo "   - Password: $NODERED_PASSWORD"
    echo
    echo "2. InfluxDB Credentials"
    echo "   - Username: $INFLUXDB_USERNAME"
    echo "   - Password: $INFLUXDB_PASSWORD"
    echo "   - Organization: $INFLUXDB_ORG"
    echo "   - Bucket: sensors"
    echo "   - Token: $INFLUXDB_TOKEN"
    echo
    echo "3. Grafana Credentials"
    echo "   - Username: $GRAFANA_USERNAME"
    echo "   - Password: $GRAFANA_PASSWORD"
    echo
    echo "⚠️  IMPORTANT: Save these credentials and delete the credentials file!"
    echo "   ($CREDS_FILE)"
    echo
    echo "Services are accessible at:"
    PI_IP=$(hostname -I | awk '{print $1}')
    echo "   Node-RED: http://$PI_IP:1880"
    echo "   InfluxDB: http://$PI_IP:8086"
    echo "   Grafana:  http://$PI_IP:3000"
    echo
    echo "For troubleshooting, check the log at: $LOG_FILE"
    echo "=============================================="
    
    show_install_log
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
