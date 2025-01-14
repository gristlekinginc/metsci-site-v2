#!/bin/bash
# This script is designed to be run on a Raspberry Pi with a fresh install of Raspberry Pi OS Lite (64-bit).
# It will install Node-RED, InfluxDB, and Grafana, and configure them to work together. 
# Use at your own risk, and be ready to wipe your Pi and start over if it doesn't work.  Yeehaw!

# Add colors for warnings
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Add version info at top
VERSION="1.2.3"  # Updated version
echo "MeteoScientific Dashboard Installer v$VERSION"
echo
echo "Hardware Requirements:"
echo "- Raspberry Pi 4 (4GB+ RAM recommended)"
echo "- 32GB+ SD card recommended"

# Set up environment variables
CREDS_FILE="/home/$SUDO_USER/metsci-credentials.txt"
ENV_FILE="/etc/metsci-dashboard/.env"
STATUS_FILE="/tmp/dashboard-install-status"
LOG_FILE="/tmp/dashboard-install-$(date +%Y%m%d-%H%M%S).log"

# Set up logging
exec 1> >(tee -a "$LOG_FILE") 2>&1

##############################################################################
# Function: show_progress
# Shows a "step X of Y" progress banner.
##############################################################################
show_progress() {
    local step="$1"
    local total="8"  # Adjust total steps as needed
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
# Function: error_exit
# Prints an error, optionally calls rollback, and exits.
##############################################################################
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    echo "Check $LOG_FILE for details"
    if [ "$2" = "rollback" ]; then
        perform_rollback
    fi
    exit 1
}

##############################################################################
# Function: perform_rollback
# Attempts to remove all installed packages/files if the script fails mid-way.
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
# Function: install_prerequisites
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
# Arrays for random username generation
##############################################################################
NODERED_NAMES=("vulcan" "klingon" "romulan" "ferengi" "cardassian" "bajoran")
INFLUXDB_NAMES=("ewok" "wookiee" "jawa" "tusken" "gungan" "hutt")
GRAFANA_NAMES=("drysine" "nexus" "matrix" "cipher" "neural" "quantum")

##############################################################################
# Function: generate_credentials
# Asks the user for org/usernames, generates random passwords, and writes them
# to both the credentials file and the .env file.
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
        # Remove spaces and special characters, convert to lowercase
        INFLUXDB_ORG=$(echo "$INFLUXDB_ORG" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
        if [ -z "$INFLUXDB_ORG" ]; then
            INFLUXDB_ORG=$DEFAULT_ORG
            echo "Using default organization: $DEFAULT_ORG"
        fi
    else
        INFLUXDB_ORG=$DEFAULT_ORG
    fi
    
    # Function to get random name from array
    get_random_name() {
        local arr=("$@")
        echo "${arr[RANDOM % ${#arr[@]}]}"
    }
    
    # Generate default usernames
    DEFAULT_NODERED_USER=$(get_random_name "${NODERED_NAMES[@]}")
    DEFAULT_INFLUXDB_USER=$(get_random_name "${INFLUXDB_NAMES[@]}")
    DEFAULT_GRAFANA_USER=$(get_random_name "${GRAFANA_NAMES[@]}")
    
    # Ask about Node-RED username
    echo "The default username for Node-RED is '${DEFAULT_NODERED_USER}'"
    read -p "Do you need to change it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        while true; do
            read -p "Enter new Node-RED username (anything but 'admin'): " NODERED_USERNAME
            if [ "$NODERED_USERNAME" != "admin" ]; then
                break
            else
                echo "Please choose a different username"
            fi
        done
    else
        NODERED_USERNAME=$DEFAULT_NODERED_USER
    fi
    
    # Repeat for InfluxDB
    echo "The default username for InfluxDB is '${DEFAULT_INFLUXDB_USER}'"
    read -p "Do you need to change it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        while true; do
            read -p "Enter new InfluxDB username (anything but 'admin'): " INFLUXDB_USERNAME
            if [ "$INFLUXDB_USERNAME" != "admin" ]; then
                break
            else
                echo "Please choose a different username"
            fi
        done
    else
        INFLUXDB_USERNAME=$DEFAULT_INFLUXDB_USER
    fi
    
    # And for Grafana
    echo "The default username for Grafana is '${DEFAULT_GRAFANA_USER}'"
    read -p "Do you need to change it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        while true; do
            read -p "Enter new Grafana username (anything but 'admin'): " GRAFANA_USERNAME
            if [ "$GRAFANA_USERNAME" != "admin" ]; then
                break
            else
                echo "Please choose a different username"
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
    
    # Create credentials file
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

    # Create environment file
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

    # After generating all credentials, show summary
    print_install_summary
}

##############################################################################
# Function: print_install_summary
# Quick summary of what's going to be installed, then user can confirm/abort.
##############################################################################
print_install_summary() {
    echo
    echo "Installation Summary"
    echo "-------------------"
    echo
    echo "The following services will be installed:"
    echo "1. Node-RED"
    echo "2. InfluxDB"
    echo "3. Grafana"
    echo
    echo "Credentials will be displayed after successful installation."
    echo
    read -p "Continue with installation? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 1
    fi
}

##############################################################################
# Function: check_requirements
# Check if we are on a Raspberry Pi (64-bit), memory, disk space, free ports,
# and internet connectivity.
##############################################################################
check_requirements() {
    echo "Performing system checks..."

    # Check if running on Pi
    if ! grep -q "Raspberry Pi" /proc/cpuinfo; then
        error_exit "This script must be run on a Raspberry Pi"
    fi

    # Check for 64-bit OS
    if [ "$(uname -m)" != "aarch64" ]; then
        error_exit "This script requires a 64-bit OS (aarch64)"
    fi

    # Check RAM
    total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 1800 ]; then
        error_exit "Insufficient memory. 2GB RAM minimum required"
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
            error_exit "Port $port is already in use. Please free this port before continuing."
        fi
    done

    # Check internet connectivity
    if ! ping -c 1 -W 5 google.com &> /dev/null; then
        error_exit "Internet connection required. Check your network connection."
    fi

    echo "✓ System requirements met"
}

##############################################################################
# Function: install_nodejs
# Installs Node.js from NodeSource, cleans up any partial installs first.
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
# Function: install_nodered
# Installs Node-RED globally and sets up a systemd service under $SUDO_USER.
##############################################################################
install_nodered() {
    echo "Installing Node-RED..."
    source "$ENV_FILE"
    
    # Install Node-RED and bcryptjs
    sudo npm install -g --unsafe-perm node-red bcryptjs || error_exit "Failed to install Node-RED"
    
    # Create systemd service file
    sudo tee /etc/systemd/system/nodered.service > /dev/null << EOL
[Unit]
Description=Node-RED
After=syslog.target network.target

[Service]
ExecStart=/usr/bin/node-red
Restart=on-failure
KillSignal=SIGINT
User=$SUDO_USER
Environment=NODE_RED_OPTIONS=

[Install]
WantedBy=multi-user.target
EOL

    # Create the ~/.node-red folder under $SUDO_USER’s home
    sudo -u "$SUDO_USER" mkdir -p /home/"$SUDO_USER"/.node-red
    cd /home/"$SUDO_USER"/.node-red || error_exit "Failed to access Node-RED directory"
    
    # Install required nodes in that .node-red folder
    sudo -u "$SUDO_USER" npm install bcryptjs node-red-contrib-influxdb || error_exit "Failed to install required nodes"
    
    # Generate password hash
    NODERED_HASH=$(node -e "console.log(require('bcryptjs').hashSync(process.argv[1], 8))" "$NODERED_PASSWORD")
    
    # Create a settings.js file with authentication
    cat > settings.js << EOL
module.exports = {
    uiPort: process.env.PORT || 1880,
    
    // Security settings
    adminAuth: {
        type: "credentials",
        users: [{
            username: "$NODERED_USERNAME",
            password: "$NODERED_HASH",
            permissions: "*"
        }]
    },
    
    // Node-RED settings
    flowFile: 'flows.json',
    credentialSecret: "$(openssl rand -base64 24)",
    
    // Editor settings
    editorTheme: {
        projects: {
            enabled: false
        }
    },
    
    // InfluxDB connection
    influxdb: {
        version: 2,
        url: "http://localhost:8086",
        token: "$INFLUXDB_TOKEN",
        org: "$INFLUXDB_ORG",
        bucket: "$INFLUXDB_BUCKET"
    },
    
    // Runtime settings
    functionGlobalContext: { },
    
    // Node settings
    nodeMessageBufferMaxLength: 2000,
    
    // Logging settings
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        }
    }
}
EOL
    # Fix permissions so that $SUDO_USER can own and run Node-RED
    sudo chown -R "$SUDO_USER":"$SUDO_USER" /home/"$SUDO_USER"/.node-red
}

##############################################################################
# Function: install_influxdb
# Installs InfluxDB 2.x, initializes a user/org/bucket, and sets up a token.
##############################################################################
install_influxdb() {
    echo "Installing InfluxDB..."
    source "$ENV_FILE"
    
    # Stop and remove any existing installation
    if systemctl is-active --quiet influxdb; then
        sudo systemctl stop influxdb
    fi
    
    # Add InfluxDB repository and key
    curl -s https://repos.influxdata.com/influxdata-archive_compat.key | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.asc > /dev/null
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.asc] https://repos.influxdata.com/debian stable main" | sudo tee /etc/apt/sources.list.d/influxdata.list
    
    # Update package list after adding repo
    sudo apt-get update || error_exit "Failed to update package list"
    
    # Install InfluxDB
    sudo apt-get install -y influxdb2 || error_exit "Failed to install InfluxDB"
    
    # Start service
    echo "Starting InfluxDB service..."
    sudo systemctl daemon-reload
    sudo systemctl enable influxdb
    sudo systemctl start influxdb
    
    # Wait for service to be ready
    echo "Waiting for InfluxDB to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:8086/health > /dev/null; then
            echo "InfluxDB is responding to health checks"
            break
        fi
        echo "Waiting for InfluxDB to be ready... ($i/30)"
        sleep 2
        if [ $i -eq 30 ]; then
            journalctl -u influxdb --no-pager -n 50
            error_exit "InfluxDB failed to respond to health checks" "rollback"
        fi
    done
    
    # Initialize InfluxDB using the CLI with 1-year retention
    echo "Setting up InfluxDB..."
    influx setup \
        --username "$INFLUXDB_USERNAME" \
        --password "$INFLUXDB_PASSWORD" \
        --org "$INFLUXDB_ORG" \
        --bucket "sensors" \
        --retention 365d \
        --token "$INFLUXDB_TOKEN" \
        --force 2>/dev/null || error_exit "Failed to initialize InfluxDB"
    
    # Create an all-access token for Node-RED
    echo "Creating Node-RED access token..."
    NODERED_TOKEN=$(influx auth create \
        --org "$INFLUXDB_ORG" \
        --all-access \
        --description "Node-RED Integration" \
        --json | jq -r '.token')
    
    # Update environment file with Node-RED token
    sudo sed -i "s/INFLUXDB_TOKEN=.*/INFLUXDB_TOKEN=$NODERED_TOKEN/" "$ENV_FILE"
    
    # Verify the setup worked
    if ! influx auth ls --user "$INFLUXDB_USERNAME" &>/dev/null; then
        error_exit "Failed to verify InfluxDB setup"
    fi
    
    echo "✓ InfluxDB installed and configured with user: $INFLUXDB_USERNAME"
}

##############################################################################
# Function: configure_grafana
# Called from install_grafana to set admin credentials, etc.
##############################################################################
configure_grafana() {
    source "$ENV_FILE"
    echo "Configuring Grafana security..."
    
    # Update Grafana configuration file first
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
    
    # Verify configuration took effect
    for i in {1..30}; do
        if curl -s -u "${GRAFANA_USERNAME}:${GRAFANA_PASSWORD}" http://localhost:3000/api/health > /dev/null; then
            echo "✓ Grafana security configured"
            return 0
        fi
        echo "Waiting for Grafana... ($i/30)"
        sleep 2
    done
    
    echo "Grafana failed to start with new configuration. Check logs with: journalctl -u grafana-server"
    return 1
}

##############################################################################
# Function: install_grafana
# Installs Grafana OSS from the official repo, updates config, calls configure_grafana.
##############################################################################
install_grafana() {
    echo "Installing Grafana..."
    source "$ENV_FILE"
    
    # Add Grafana repository and key
    curl -fsSL https://packages.grafana.com/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/grafana.gpg
    echo "deb [signed-by=/usr/share/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
    
    sudo apt-get update
    sudo apt-get install -y grafana || error_exit "Failed to install Grafana"
    
    # Create Grafana config directory if it doesn't exist
    sudo mkdir -p /etc/grafana
    
    # Update Grafana configuration
    sudo tee /etc/grafana/grafana.ini > /dev/null << EOL
[auth]
disable_login_form = false

[auth.anonymous]
enabled = true
org_name = ${INFLUXDB_ORG}
org_role = Viewer

[feature_toggles]
publicDashboards = true
EOL
    
    # Set permissions
    sudo chown -R grafana:grafana /etc/grafana
    
    # Enable and start Grafana
    sudo systemctl daemon-reload
    sudo systemctl enable grafana-server
    sudo systemctl restart grafana-server
    
    # Wait for Grafana to be ready
    echo "Waiting for Grafana to start..."
    for i in {1..30}; do
        if curl -s http://localhost:3000/api/health > /dev/null; then
            echo "Grafana is responding to health checks"
            break
        fi
        echo "Waiting for Grafana to be ready... ($i/30)"
        sleep 2
        if [ $i -eq 30 ]; then
            journalctl -u grafana-server --no-pager -n 50
            error_exit "Grafana failed to respond to health checks" "rollback"
        fi
    done
    
    # Configure security before starting service
    configure_grafana || error_exit "Failed to configure Grafana security" "rollback"
    
    # Start service after configuration
    sudo systemctl restart grafana-server
    
    echo "✓ Grafana installed and configured with user: $GRAFANA_USERNAME"
}

##############################################################################
# Function: start_services
# Enables and starts the systemd services, then waits a bit for them to come up.
##############################################################################
start_services() {
    echo "Starting services..."
    
    for service in nodered influxdb grafana-server; do
        echo "Starting $service..."
        sudo systemctl enable $service
        sudo systemctl start $service || error_exit "Failed to start $service" "rollback"
        echo "✓ $service started"
    done
    
    # Wait for services to be fully up
    echo "Waiting for services to initialize..."
    sleep 10
}

##############################################################################
# Function: verify_services
# Double-check that each service is actually responding on its port.
##############################################################################
verify_services() {
    echo "Waiting for services to initialize..."
    sleep 10  # Increase from current value
    
    echo "Verifying services..."
    
    # Check Node-RED
    echo "Checking nodered (port 1880)..."
    for i in {1..30}; do
        if curl -s http://localhost:1880 > /dev/null; then
            echo "✓ nodered verified"
            break
        fi
        sleep 2
        if [ $i -eq 30 ]; then
            error_exit "Service nodered is not responding" "rollback"
        fi
    done
    
    # Check InfluxDB
    echo "Checking influxdb (port 8086)..."
    for i in {1..30}; do
        if curl -s http://localhost:8086/health > /dev/null; then
            echo "✓ influxdb verified"
            break
        fi
        sleep 2
        if [ $i -eq 30 ]; then
            error_exit "Service influxdb is not responding" "rollback"
        fi
    done
    
    # Check Grafana (port 3000)
    echo "Checking grafana-server (port 3000)..."
    for i in {1..45}; do
        if curl -s http://localhost:3000/api/health > /dev/null; then
            echo "✓ grafana-server verified"
            break
        fi
        echo "Waiting for Grafana... ($i/45)"
        sleep 2
        if [ $i -eq 45 ]; then
            journalctl -u grafana-server --no-pager -n 50
            error_exit "Service grafana-server is not responding" "rollback"
        fi
    done
}

##############################################################################
# Function: print_completion
# Displays the credentials and endpoints at the end of the install.
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
    echo
    echo "Mark my words, you'll need these credentials later."
    echo "If you forget or you're just rolling rawdawg, find em later" 
    echo "at: $CREDS_FILE"
    echo
    echo "Check out your shiny new services at:"
    PI_IP=$(hostname -I | awk '{print $1}')
    echo "   Node-RED: http://$PI_IP:1880"
    echo "   InfluxDB: http://$PI_IP:8086"
    echo "   Grafana: http://$PI_IP:3000"
    echo
    echo "For troubleshooting, check the log at: $LOG_FILE"
    echo "=============================================="
}

##############################################################################
# Function: main
# Orchestrates the entire install process in step-by-step order.
##############################################################################
main() {
    show_progress 1 "Checking system requirements"
    check_requirements
    
    show_progress 2 "Installing prerequisites"
    install_prerequisites
    
    show_progress 3 "Gathering user preferences"
    generate_credentials
    
    echo
    echo "All required information collected. Beginning installation..."
    echo "This may take several minutes. You can monitor detailed progress in: $LOG_FILE"
    echo
    
    show_progress 4 "Installing Node.js"
    install_nodejs
    
    show_progress 5 "Installing Node-RED"
    install_nodered
    
    show_progress 6 "Installing InfluxDB"
    install_influxdb
    
    show_progress 7 "Installing Grafana"
    install_grafana
    
    show_progress 8 "Starting and verifying services"
    start_services
    verify_services
    
    print_completion
}

##############################################################################
# Run the main installation
##############################################################################
main
