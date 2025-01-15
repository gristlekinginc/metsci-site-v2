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
VERSION="1.5.8"

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

    # Check for Raspberry Pi
    if ! grep -q "Raspberry Pi" /proc/cpuinfo; then
        error_exit "This script must be run on a Raspberry Pi"
    fi

    # Check memory
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_mem" -lt 1024 ]; then
        error_exit "Insufficient memory. 1GB minimum required, 4GB recommended."
    fi

    # Check disk space
    free_space=$(df -m / | awk 'NR==2 {print $4}')
    if [ "$free_space" -lt 5120 ]; then
        error_exit "Insufficient disk space. 5GB minimum free space required."
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

    # Initial checks
    show_progress 1 "Checking system requirements"
    check_requirements
    check_ports
    
    # Install prerequisites
    show_progress 2 "Installing prerequisites"
    install_prerequisites
    
    # Generate credentials
    show_progress 3 "Setting up credentials"
    generate_credentials
    
    # Core installations
    show_progress 4 "Installing core services"
    install_nodejs_and_npm
    install_nodered
    install_influxdb
    install_grafana
    
    # Start and verify services
    show_progress 5 "Starting services"
    start_services
    verify_services
    
    # Complete installation
    show_progress 6 "Finalizing installation"
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
    source "$ENV_FILE"
    
    # Install Node-RED and required packages
    sudo npm install -g --unsafe-perm node-red bcryptjs || error_exit "Failed to install Node-RED"
    
    # Create systemd service file for metsci-service user
    sudo tee /etc/systemd/system/nodered.service > /dev/null << EOL
[Unit]
Description=Node-RED
After=syslog.target network.target

[Service]
ExecStart=/usr/bin/node-red
Restart=on-failure
KillSignal=SIGINT
User=metsci-service
Environment=NODE_RED_OPTIONS=
WorkingDirectory=/home/metsci-service

[Install]
WantedBy=multi-user.target
EOL

    # Create Node-RED directory and set ownership
    sudo mkdir -p /home/metsci-service/.node-red
    cd /home/metsci-service/.node-red || error_exit "Failed to access Node-RED directory"
    
    # Install required nodes
    sudo -u metsci-service npm install bcryptjs node-red-contrib-influxdb || error_exit "Failed to install required nodes"
    
    # Generate password hash
    NODERED_HASH=$(node -e "console.log(require('bcryptjs').hashSync(process.argv[1], 8))" "$NODERED_PASSWORD")
    
    # Create settings.js with proper configuration
    sudo -u metsci-service tee settings.js > /dev/null << EOL
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
        bucket: "sensors"
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

    # Set proper permissions
    sudo chown -R metsci-service:metsci-service /home/metsci-service/.node-red
    sudo chmod 750 /home/metsci-service/.node-red
    
    echo "✓ Node-RED installed and configured with user: $NODERED_USERNAME"
}

install_influxdb() {
    echo "Installing InfluxDB..."
    
    # Import InfluxDB GPG key
    curl -s https://repos.influxdata.com/influxdata-archive_compat.key > /tmp/influxdb.key
    echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c /tmp/influxdb.key' | sha256sum -c || {
        error_exit "InfluxDB GPG key verification failed" "rollback"
    }
    cat /tmp/influxdb.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
    
    # Add InfluxDB repository
    echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | \
        sudo tee /etc/apt/sources.list.d/influxdata.list > /dev/null
    
    # Install InfluxDB
    sudo apt-get update && sudo apt-get install -y influxdb2 || {
        error_exit "Failed to install InfluxDB" "rollback"
    }
    
    # Start InfluxDB service
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
    
    # Initialize InfluxDB
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
    
    # Import Grafana GPG key
    curl -s https://apt.grafana.com/gpg.key | gpg --dearmor | \
        sudo tee /etc/apt/trusted.gpg.d/grafana.gpg > /dev/null
    
    # Add Grafana repository
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/grafana.gpg] https://apt.grafana.com stable main" | \
        sudo tee /etc/apt/sources.list.d/grafana.list > /dev/null
    
    # Install Grafana
    sudo apt-get update && sudo apt-get install -y grafana || {
        error_exit "Failed to install Grafana" "rollback"
    }
    
    # Configure Grafana
    sudo tee /etc/grafana/grafana.ini > /dev/null << EOL
[security]
admin_user = ${GRAFANA_USERNAME}
admin_password = ${GRAFANA_PASSWORD}
disable_gravatar = true
cookie_secure = true
strict_transport_security = true

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

[server]
root_url = %(protocol)s://%(domain)s:%(http_port)s/
serve_from_sub_path = true
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
    
    # Wait for service to be ready
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
    
    echo "✓ Grafana installed and configured with user: $GRAFANA_USERNAME"
}

verify_services() {
    echo "Verifying all services..."
    
    # Check each service status
    for service in nodered influxdb grafana-server; do
        if ! systemctl is-active --quiet $service; then
            error_exit "Service $service failed verification" "rollback"
        fi
    done
    
    # Verify service endpoints
    local -A endpoints=(
        ["Node-RED"]="http://localhost:1880"
        ["InfluxDB"]="http://localhost:8086/health"
        ["Grafana"]="http://localhost:3000/api/health"
    )
    
    for service in "${!endpoints[@]}"; do
        echo "Verifying $service..."
        if ! curl -s "${endpoints[$service]}" > /dev/null; then
            error_exit "$service endpoint verification failed" "rollback"
        fi
        echo "✓ $service verified"
    done
    
    echo "✓ All services verified and running"
}

#----------------------------------------------------------------------
# Completion and Cleanup Functions
#----------------------------------------------------------------------
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
   - URL: http://${PI_IP}:1880

2. InfluxDB Credentials
   - Username: ${INFLUXDB_USERNAME}
   - Password: ${INFLUXDB_PASSWORD}
   - Organization: ${INFLUXDB_ORG}
   - Bucket: sensors
   - Token: ${INFLUXDB_TOKEN}
   - URL: http://${PI_IP}:8086

3. Grafana Credentials
   - Username: ${GRAFANA_USERNAME}
   - Password: ${GRAFANA_PASSWORD}
   - URL: http://${PI_IP}:3000

⚠️  IMPORTANT: Save these credentials and delete this file!
   (${CREDS_FILE})

For troubleshooting, check the log at: ${LOG_FILE}
==============================================
EOL

    # Set proper permissions on credentials file
    chmod 600 "${CREDS_FILE}"
    chown "${SUDO_USER}:${SUDO_USER}" "${CREDS_FILE}"
}

print_completion() {
    clear
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
    echo
    echo "Mark my words, you'll need these credentials later."
    echo "If you forget or you're just rolling rawdawg, find em later"
    echo "at: ${CREDS_FILE}"
    echo
    echo "Check out your shiny new services at:"
    PI_IP=$(hostname -I | awk '{print $1}')
    echo "   Node-RED: http://${PI_IP}:1880"
    echo "   InfluxDB: http://${PI_IP}:8086"
    echo "   Grafana:  http://${PI_IP}:3000"
    echo
    echo "For troubleshooting, check the log at: ${LOG_FILE}"
    echo "=============================================="
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

show_install_log() {
    echo
    read -p "Would you like to view the installation log? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        less "${LOG_FILE}"
    fi
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
