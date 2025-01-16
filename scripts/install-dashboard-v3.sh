#!/bin/bash
# This script installs Node-RED, InfluxDB, and Grafana on a Raspberry Pi OS Lite (64-bit).
# Prior to running this script, run secure-pi.sh to harden the Pi.
# Use at your own risk, and be ready to wipe your Pi and start over if needed. Yeehaw!

#----------------------------------------------------------------------
# Globals and Environment
#----------------------------------------------------------------------
# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Version
VERSION="1.6.1"

# File paths
CREDS_FILE="/home/$SUDO_USER/metsci-credentials.txt"
ENV_FILE="/etc/metsci-dashboard/.env"
STATUS_FILE="/tmp/dashboard-install-status"
LOG_FILE="/var/log/metsci-dashboard-install-$(date +%Y%m%d-%H%M%S).log"

# Arrays for username generation
NODERED_NAMES=("neo" "morpheus" "trinity" "oracle" "tank" "dozer" "switch" "apoc")
INFLUXDB_NAMES=("skywalker" "kenobi" "yoda" "windu" "ewok" "bobafett" "lando")
GRAFANA_NAMES=("muaddib" "chani" "stilgar" "leto" "ghanima" "irulan" "hawat")

# Set up logging
exec 1> >(tee -a "$LOG_FILE") 2>&1

#----------------------------------------------------------------------
# Helper Functions
#----------------------------------------------------------------------
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    echo "Check $LOG_FILE for details."
    if [ "$2" = "rollback" ]; then
        perform_rollback
    fi
    exit 1
}

show_progress() {
    local step="$1"
    local total="6"
    local message="$2"
    
    echo
    echo "==================================================================="
    echo "Progress: Step $step of $total"
    echo "Current: $message"
    echo "Time:    $(date '+%H:%M:%S')"
    echo "==================================================================="
    echo
}

#----------------------------------------------------------------------
# Check Functions
#----------------------------------------------------------------------
check_requirements() {
     
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        error_exit "Please run as root (use sudo)"
    fi

    # Display system information
    echo "System Information:"
    echo "==================="
    echo "CPU:      $(cat /proc/cpuinfo | grep 'Model' | cut -d ':' -f 2 | sed 's/^ *//')"
    echo "Memory:   $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Storage:  $(df -h / | awk 'NR==2 {print $2}')"
    echo "OS:       $(cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f 2)"
    echo "Kernel:   $(uname -r)"
    echo

    # Check for Raspberry Pi
    if ! grep -q "Raspberry Pi" /proc/cpuinfo; then
        error_exit "This script must be run on a Raspberry Pi"
    fi

    # Check memory and provide warnings
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_mem" -lt 1024 ]; then
        error_exit "Insufficient memory. 1GB minimum required, 4GB recommended."
    elif [ "$total_mem" -lt 4096 ]; then
        echo -e "${YELLOW}Warning: Less than 4GB RAM detected.  Fine for most people.  If you're running 50 sensors firing every minute, level up to 8 GB RAM.${NC}"
        echo "Current memory: ${total_mem}MB"
        echo "Recommended: 4096MB"
        echo
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Check disk space and provide warnings
    free_space=$(df -m / | awk 'NR==2 {print $4}')
    if [ "$free_space" -lt 5120 ]; then
        error_exit "Insufficient disk space. 5GB minimum free space required."
    elif [ "$free_space" -lt 10240 ]; then
        echo -e "${YELLOW}Warning: Less than 10GB free space detected. Performance may be impacted.${NC}"
        echo "Current free space: $(($free_space/1024))GB"
        echo "Recommended: 10GB"
        echo
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Check internet connectivity
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        error_exit "No internet connection detected"
    fi

    # Verify security setup
    if ! id metsci-service >/dev/null 2>&1; then
        error_exit "Security setup not detected. Please run secure-pi.sh first"
    fi

    echo "✓ System requirements verified"
}

check_ports() {
    local ports=(1880 8086 3000)
    for port in "${ports[@]}"; do
        if netstat -ln | grep -q ":${port}"; then
            error_exit "Port ${port} is already in use"
        fi
    done
    echo "✓ Required ports are available"
}

#----------------------------------------------------------------------
# Main Installation Function
#----------------------------------------------------------------------
main() {
    # Display banner
    echo "MeteoScientific Dashboard Installer v$VERSION"
    echo "Hardware Requirements:"
    echo "- Raspberry Pi 4 (4GB+ RAM recommended)"
    echo "- 32GB+ SD card recommended"
    echo

    # 1. Check Requirements
    show_progress 1 "Checking system requirements"
    check_requirements
    check_ports
    
    # 2. Install Prerequisites
    show_progress 2 "Installing prerequisites"
    install_prerequisites
    
    # 3. Generate Credentials
    show_progress 3 "Setting up credentials"
    generate_credentials
    
    # 4. Core Services Installation
    show_progress 4 "Installing core services"
    
    echo "Installing Node.js..."
    install_nodejs_and_npm
    
    echo "Installing Node-RED base..."
    install_nodered
    
    echo "Installing InfluxDB..."
    install_influxdb
    
    echo "Installing Node-RED InfluxDB nodes..."
    install_nodered_influx_nodes
    
    echo "Installing Grafana..."
    install_grafana
    
    # 5. Verify Services
    show_progress 5 "Verifying services"
    verify_services
    
    # 6. Print Final Information
    show_progress 6 "Installation complete"
    save_credentials
    print_completion
}

#----------------------------------------------------------------------
# Service Installation Functions
#----------------------------------------------------------------------
install_prerequisites() {
    echo "Installing prerequisites..."
    
    # Update package list
    sudo apt-get update || error_exit "Failed to update package list"
    
    # Install required packages
    sudo apt-get install -y \
        curl \
        net-tools \
        jq \
        gpg \
        apt-transport-https \
        build-essential \
        git || error_exit "Failed to install prerequisites"
        
    echo "✓ Prerequisites installed"
}

install_nodejs_and_npm() {
    echo "Installing Node.js..."
    
    # Clean up any failed installations
    sudo apt-get remove -y nodejs npm || true
    sudo apt-get autoremove -y
    sudo rm -rf /etc/apt/sources.list.d/nodesource.list*
    
    # Add NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || {
        error_exit "Failed to add NodeSource repository" "rollback"
    }
    
    # Install Node.js
    sudo apt-get install -y nodejs || {
        error_exit "Failed to install Node.js" "rollback"
    }
    
    # Update npm to latest version
    sudo npm install -g npm@latest || {
        error_exit "Failed to update npm" "rollback"
    }
    
    node_version=$(node --version)
    npm_version=$(npm --version)
    echo "✓ Node.js $node_version (npm $npm_version) installed"
}

install_nodered() {
    echo "Installing Node-RED..."
    source "$ENV_FILE" || error_exit "Failed to source environment file"
    
    # Clean up any old installations
    sudo apt-get remove -y nodered || true
    sudo apt-get autoremove -y
    
    # Install Node-RED and required packages globally
    sudo npm install -g --unsafe-perm node-red bcryptjs || error_exit "Failed to install Node-RED"
    
    # Create Node-RED service file
    sudo tee /lib/systemd/system/nodered.service > /dev/null << EOL
[Unit]
Description=Node-RED
After=syslog.target network.target

[Service]
ExecStart=/usr/bin/node-red
Restart=on-failure
KillSignal=SIGINT
User=metsci-service
Group=metsci-service
WorkingDirectory=/home/metsci-service
Environment=NODE_RED_OPTIONS=

[Install]
WantedBy=multi-user.target
EOL

    # Set up Node-RED directory and permissions
    sudo mkdir -p /home/metsci-service/.node-red
    cd /home/metsci-service/.node-red || error_exit "Failed to access Node-RED directory"
    
    # Install required nodes as metsci-service
    sudo -u metsci-service npm install bcryptjs node-red-contrib-influxdb || error_exit "Failed to install required nodes"
    
    # Configure settings.js with authentication
    sudo tee /home/metsci-service/.node-red/settings.js > /dev/null << EOL
module.exports = {
    credentialSecret: "$(openssl rand -hex 32)",
    adminAuth: {
        type: "credentials",
        users: [{
            username: "${NODERED_USERNAME}",
            password: "$(echo "${NODERED_PASSWORD}" | node -e 'console.log(require("bcryptjs").hashSync(require("fs").readFileSync(0, "utf-8").trim(), 8))')",
            permissions: "*"
        }]
    },
    uiPort: 1880,
    flowFile: 'flows.json',
    flowFilePretty: true,
    httpAdminRoot: '/'
}
EOL

    # Set proper ownership
    sudo chown -R metsci-service:metsci-service /home/metsci-service/.node-red
    
    # Enable and start Node-RED
    sudo systemctl daemon-reload
    sudo systemctl enable nodered.service
    sudo systemctl start nodered.service
    
    # Wait for Node-RED to start
    echo "Waiting for Node-RED to start..."
    for i in {1..30}; do
        if curl -s http://localhost:1880/ > /dev/null; then
            echo "✓ Node-RED is responding"
            break
        fi
        if [ $i -eq 30 ]; then
            error_exit "Node-RED failed to start"
        fi
        sleep 2
    done
    
    echo "✓ Node-RED installed successfully"
}

install_influxdb() {
    echo "Installing InfluxDB..."
    source "$ENV_FILE" || error_exit "Failed to source environment file"
    
    # Import InfluxDB GPG key
    curl -s https://repos.influxdata.com/influxdata-archive_compat.key > /tmp/influxdb.key
    echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c /tmp/influxdb.key' | sha256sum -c || {
        error_exit "InfluxDB GPG key verification failed" "rollback"
    }
    cat /tmp/influxdb.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
    
    # Add InfluxDB repository and install
    echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | \
        sudo tee /etc/apt/sources.list.d/influxdata.list > /dev/null
    
    # Install InfluxDB
    sudo apt-get update && sudo apt-get install -y influxdb2 || {
        error_exit "Failed to install InfluxDB" "rollback"
    }
    
    # Start service and wait for it
    sudo systemctl enable influxdb
    sudo systemctl start influxdb
    
    # Wait for service to be ready
    echo "Waiting for InfluxDB to start..."
    for i in {1..30}; do
        if curl -s http://localhost:8086/health > /dev/null; then
            break
        fi
        sleep 2
        if [ $i -eq 30 ]; then
            error_exit "InfluxDB failed to start" "rollback"
        fi
    done
    
    # Initialize InfluxDB with explicit credential checks
    if [ -z "$INFLUXDB_USERNAME" ] || [ -z "$INFLUXDB_ORG" ]; then
        error_exit "Missing required InfluxDB credentials" "rollback"
    fi
    
    # Initialize with proper credentials
    influx setup \
        --org "$INFLUXDB_ORG" \
        --bucket "sensors" \
        --username "$INFLUXDB_USERNAME" \
        --password "$INFLUXDB_PASSWORD" \
        --token "$INFLUXDB_TOKEN" \
        --force || {
        error_exit "Failed to initialize InfluxDB" "rollback"
    }
    
    echo "✓ InfluxDB installed and configured with org: $INFLUXDB_ORG"
}

install_grafana() {
    echo "Installing Grafana..."
    source "$ENV_FILE" || error_exit "Failed to source environment file"
    
    # Import Grafana GPG key and add repository
    curl -s https://apt.grafana.com/gpg.key | gpg --dearmor | \
        sudo tee /etc/apt/trusted.gpg.d/grafana.gpg > /dev/null
    
    # Add Grafana repository
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/grafana.gpg] https://apt.grafana.com stable main" | \
        sudo tee /etc/apt/sources.list.d/grafana.list > /dev/null
    
    # Install Grafana
    sudo apt-get update && sudo apt-get install -y grafana || {
        error_exit "Failed to install Grafana" "rollback"
    }
    
    # Remove any existing database to ensure clean first run
    sudo rm -f /var/lib/grafana/grafana.db
    
    # Configure Grafana with corrected security settings
    sudo tee /etc/grafana/grafana.ini > /dev/null << EOL
[paths]
data = /var/lib/grafana
logs = /var/log/grafana
plugins = /var/lib/grafana/plugins

[security]
admin_user = ${GRAFANA_USERNAME}
admin_password = ${GRAFANA_PASSWORD}
disable_gravatar = true
cookie_secure = false
strict_transport_security = false
allow_sign_up = false

[auth]
login_cookie_name = grafana_session
login_maximum_inactive_lifetime_days = 7
login_maximum_lifetime_days = 30
disable_login_form = false
oauth_auto_login = false

[server]
protocol = http
domain = localhost
http_port = 3000
root_url = %(protocol)s://%(domain)s:%(http_port)s/
serve_from_sub_path = true
cookie_samesite = lax

[auth.anonymous]
enabled = true
org_role = Viewer

[feature_toggles]
publicDashboards = true

[dashboards]
versions_to_keep = 5

[analytics]
reporting_enabled = false

[metrics]
enabled = false

EOL
    
    # Set proper permissions
    sudo chown -R grafana:grafana /etc/grafana
    sudo chmod 640 /etc/grafana/grafana.ini
    
    # Configure InfluxDB datasource
    sudo mkdir -p /etc/grafana/provisioning/datasources/
    sudo tee /etc/grafana/provisioning/datasources/influxdb.yaml > /dev/null << EOL
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
    
    # Start Grafana service
    sudo systemctl enable grafana-server
    sudo systemctl start grafana-server
    
    # Wait for service
    echo "Waiting for Grafana to start..."
    for i in {1..45}; do
        if curl -s http://localhost:3000/api/health > /dev/null; then
            break
        fi
        echo "Waiting for Grafana... ($i/45)"
        sleep 2
        if [ $i -eq 45 ]; then
            journalctl -u grafana-server --no-pager -n 50
            error_exit "Grafana failed to start" "rollback"
        fi
    done

    # Verify admin user was created correctly
    if ! curl -s -f -u "${GRAFANA_USERNAME}:${GRAFANA_PASSWORD}" http://localhost:3000/api/user > /dev/null; then
        # If login fails, create the admin user explicitly
        echo "Initial admin user not created properly, creating manually..."
        sudo grafana-cli admin user create \
            --login "${GRAFANA_USERNAME}" \
            --password "${GRAFANA_PASSWORD}" \
            --email "${GRAFANA_USERNAME}@local.host" \
            --role Admin || error_exit "Failed to create admin user" "rollback"
    fi
    
    echo "✓ Grafana installed and configured with user: $GRAFANA_USERNAME"
}

verify_services() {
    echo "Verifying all services..."
    
    # Check each service status
    local services=("nodered" "influxdb" "grafana-server")
    for service in "${services[@]}"; do
        echo "Checking $service..."
        if ! systemctl is-active --quiet $service; then
            journalctl -u $service --no-pager -n 50
            error_exit "Service $service failed verification" "rollback"
        fi
        echo "✓ $service is running"
    done
    
    # Verify service endpoints with timeout
    local -A endpoints=(
        ["Node-RED"]="http://localhost:1880"
        ["InfluxDB"]="http://localhost:8086/health"
        ["Grafana"]="http://localhost:3000/api/health"
    )
    
    for service in "${!endpoints[@]}"; do
        echo "Verifying $service endpoint..."
        if ! timeout 10 curl -s "${endpoints[$service]}" > /dev/null; then
            error_exit "$service endpoint verification failed" "rollback"
        fi
        echo "✓ $service endpoint verified"
    done
    
    # Verify InfluxDB bucket exists
    echo "Verifying InfluxDB configuration..."
    if ! influx bucket list | grep -q "sensors"; then
        error_exit "InfluxDB bucket 'sensors' not found" "rollback"
    fi
    echo "✓ InfluxDB bucket verified"
    
    # Verify Node-RED modules
    echo "Verifying Node-RED modules..."
    if ! ls /home/metsci-service/.node-red/node_modules/node-red-contrib-influxdb > /dev/null 2>&1; then
        error_exit "Required Node-RED modules not found" "rollback"
    fi
    echo "✓ Node-RED modules verified"
    
    echo "✓ All services verified and running"
}

#----------------------------------------------------------------------
# Completion and Cleanup Functions
#----------------------------------------------------------------------
save_credentials() {
    # Get IP address for display
    PI_IP=$(hostname -I | awk '{print $1}')
    
    # Create credentials file with clear formatting
    cat > "${CREDS_FILE}" << EOL
======= MeteoScientific Demo Dashboard ========
Installation completed on: $(date)

ACCESS INFORMATION:
------------------
Your Raspberry Pi IP address is: ${PI_IP}

1. Node-RED
   URL:      http://${PI_IP}:1880
   Username: ${NODERED_USERNAME}
   Password: ${NODERED_PASSWORD}

2. InfluxDB
   URL:      http://${PI_IP}:8086
   Username: ${INFLUXDB_USERNAME}
   Password: ${INFLUXDB_PASSWORD}
   Org:      ${INFLUXDB_ORG}
   Bucket:   sensors
   Token:    ${INFLUXDB_TOKEN}

3. Grafana
   URL:      http://${PI_IP}:3000
   Username: ${GRAFANA_USERNAME}
   Password: ${GRAFANA_PASSWORD}

⚠️  IMPORTANT SECURITY NOTES:
   1. Save these credentials somewhere safe
   2. Delete this file after saving: ${CREDS_FILE}
   3. Consider changing passwords after testing

TROUBLESHOOTING:
   - Installation log: ${LOG_FILE}
   - Service logs: use 'journalctl -u <service-name>'
==============================================
EOL

    # Set proper permissions on credentials file
    chmod 600 "${CREDS_FILE}"
    chown "${SUDO_USER}:${SUDO_USER}" "${CREDS_FILE}"
}

print_completion() {
    # First save to credentials file
    cat > "$CREDS_FILE" << EOL
======= MeteoScientific Demo Dashboard ========
Installation completed on: $(date)

ACCESS INFORMATION:
------------------
Your Raspberry Pi IP address is: $(hostname -I | awk '{print $1}')

1. Node-RED
   URL:      http://$(hostname -I | awk '{print $1}'):1880
   Username: $NODERED_USERNAME
   Password: $NODERED_PASSWORD

2. InfluxDB
   URL:      http://$(hostname -I | awk '{print $1}'):8086
   Username: $INFLUXDB_USERNAME
   Password: $INFLUXDB_PASSWORD
   Org:      $INFLUXDB_ORG
   Bucket:   sensors
   Token:    $INFLUXDB_TOKEN

3. Grafana
   URL:      http://$(hostname -I | awk '{print $1}'):3000
   Username: $GRAFANA_USERNAME
   Password: $GRAFANA_PASSWORD

⚠️  IMPORTANT SECURITY NOTES:
   1. Save these credentials somewhere safe
   2. Delete this file after saving: $CREDS_FILE
   3. Consider changing passwords after testing

TROUBLESHOOTING:
   - Installation log: $LOG_FILE
   - Service logs: use 'journalctl -u <service-name>'
==============================================
EOL

    # Then display the file contents
    cat "$CREDS_FILE"
    
    echo
    read -p "Would you like to view the installation log? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        less "$LOG_FILE"
    fi
    echo "Performing final cleanup..."
    echo "✓ Cleanup completed"
}

show_install_log() {
    echo
    read -p "Would you like to view the installation log? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        less "${LOG_FILE}"
    fi
}

perform_cleanup() {
    echo "Performing final cleanup..."
    
    # Remove temporary files
    rm -f /tmp/influxdb.key
    rm -f /tmp/nodered-install.sh
    
    # Clear apt cache
    apt-get clean
    
    # Remove status file if it exists
    rm -f "${STATUS_FILE}"
    
    echo "✓ Cleanup completed"
}

#------------------------------------------
# Install Node-RED InfluxDB Nodes
install_nodered_influx_nodes() {
    echo "Installing Node-RED InfluxDB nodes..."
    
    # Change to Node-RED directory
    cd /home/metsci-service/.node-red || error_exit "Failed to access Node-RED directory"
    
    # Install InfluxDB nodes
    sudo -u metsci-service npm install node-red-contrib-influxdb || error_exit "Failed to install InfluxDB nodes"
    
    # Restart Node-RED to load new nodes
    sudo systemctl restart nodered
    
    echo "✓ Node-RED InfluxDB nodes installed"
}

#----------------------------------------------------------------------
# Credential Generation Functions
get_random_name() {
    local arr=("$@")
    echo "${arr[RANDOM % ${#arr[@]}]}"
}

generate_credentials() {
    echo "Generating secure credentials..."
    
    # Create directory with proper permissions
    sudo mkdir -p /etc/metsci-dashboard || error_exit "Failed to create metsci-dashboard directory"
    sudo chmod 750 /etc/metsci-dashboard
    
    # Ask for organization name
    DEFAULT_ORG="MeteoScientific"
    echo "What is your organization name? This will be used in Grafana and InfluxDB."
    echo "The default is '${DEFAULT_ORG}'"
    read -p "Would you like to keep the default name? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
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
    
    # Generate random usernames and offer to change
    NODERED_USERNAME=$(get_random_name "${NODERED_NAMES[@]}")
    echo
    echo "Node-RED username will be: $NODERED_USERNAME"
    read -p "Would you like to keep this username? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter Node-RED username (letters and numbers only): " custom_name
        if [[ $custom_name =~ ^[a-zA-Z0-9]+$ ]]; then
            NODERED_USERNAME=$custom_name
        else
            echo "Invalid username format, using random name: $NODERED_USERNAME"
        fi
    fi

    INFLUXDB_USERNAME=$(get_random_name "${INFLUXDB_NAMES[@]}")
    echo
    echo "InfluxDB username will be: $INFLUXDB_USERNAME"
    read -p "Would you like to keep this username? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter InfluxDB username (letters and numbers only): " custom_name
        if [[ $custom_name =~ ^[a-zA-Z0-9]+$ ]]; then
            INFLUXDB_USERNAME=$custom_name
        else
            echo "Invalid username format, using random name: $INFLUXDB_USERNAME"
        fi
    fi

    GRAFANA_USERNAME=$(get_random_name "${GRAFANA_NAMES[@]}")
    echo
    echo "Grafana username will be: $GRAFANA_USERNAME"
    read -p "Would you like to keep this username? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter Grafana username (letters and numbers only): " custom_name
        if [[ $custom_name =~ ^[a-zA-Z0-9]+$ ]]; then
            GRAFANA_USERNAME=$custom_name
        else
            echo "Invalid username format, using random name: $GRAFANA_USERNAME"
        fi
    fi
    
    # Generate secure passwords
    NODERED_PASSWORD=$(openssl rand -base64 12)
    INFLUXDB_PASSWORD=$(openssl rand -base64 12)
    GRAFANA_PASSWORD=$(openssl rand -base64 12)
    
    # Generate InfluxDB token
    INFLUXDB_TOKEN=$(openssl rand -hex 32)
    
    # Write to environment file with explicit error checking
    if ! sudo tee "$ENV_FILE" > /dev/null << EOL
# MeteoScientific Dashboard Environment File
# Generated on $(date)

# Node-RED
NODERED_USERNAME="${NODERED_USERNAME}"
NODERED_PASSWORD="${NODERED_PASSWORD}"

# InfluxDB
INFLUXDB_ORG="${INFLUXDB_ORG}"
INFLUXDB_USERNAME="${INFLUXDB_USERNAME}"
INFLUXDB_PASSWORD="${INFLUXDB_PASSWORD}"
INFLUXDB_TOKEN="${INFLUXDB_TOKEN}"

# Grafana
GRAFANA_USERNAME="${GRAFANA_USERNAME}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD}"
EOL
    then
        error_exit "Failed to write environment file"
    fi

    # Set proper permissions
    sudo chmod 600 "$ENV_FILE" || error_exit "Failed to set environment file permissions"
    sudo chown root:root "$ENV_FILE" || error_exit "Failed to set environment file ownership"
    
    # Verify file exists and is readable
    if [ ! -r "$ENV_FILE" ]; then
        error_exit "Environment file not readable after creation"
    fi
    
    echo "✓ Credentials generated and saved to $ENV_FILE"
}

#----------------------------------------------------------------------
# Final Steps
#----------------------------------------------------------------------
# Trap for cleanup on script exit
trap perform_cleanup EXIT

# Start the installation
main

# If we get here, everything worked
exit 0

#----------------------------------------------------------------------
# Rollback Function
#----------------------------------------------------------------------
perform_rollback() {
    echo "Performing rollback due to installation failure..."
    
    # Stop services if they exist
    for service in nodered influxdb grafana-server; do
        if systemctl is-active --quiet $service; then
            sudo systemctl stop $service
            sudo systemctl disable $service
        fi
    done
    
    # Remove installed packages
    sudo apt-get remove -y nodejs npm influxdb2 grafana || true
    sudo apt-get autoremove -y
    
    # Clean up directories
    sudo rm -rf /home/metsci-service/.node-red
    sudo rm -rf /etc/influxdb
    sudo rm -rf /etc/grafana
    sudo rm -f /etc/apt/sources.list.d/{nodesource,influxdata,grafana}.list
    sudo rm -f /etc/apt/trusted.gpg.d/{influxdata,grafana}.gpg
    
    # Remove environment file
    sudo rm -f "$ENV_FILE"
    
    echo "✓ Rollback completed"
}
