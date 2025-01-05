#!/bin/bash
# This script is designed to be run on a Raspberry Pi with a fresh install of Raspberry Pi OS Lite (64-bit).
# It will install Node-RED, InfluxDB, and Grafana, and configure them to work together. 
# Use at your own risk, and be ready to wipe your Pi and start over if it doesn't work.  Yeehaw!

# Add colors for warnings
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Add version info at top
VERSION="1.1.6"
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

# Add required packages
command -v netstat >/dev/null 2>&1 || {
    echo "Installing net-tools..."
    sudo apt-get update && sudo apt-get install -y net-tools
}

command -v curl >/dev/null 2>&1 || {
    echo "Installing curl..."
    sudo apt-get update && sudo apt-get install -y curl
}

# Progress indicator function
show_progress() {
    local step="$1"
    local total="7"  # Updated to 7 steps
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
    echo -e "${RED}Error: $1${NC}" >&2
    echo "Check $LOG_FILE for details"
    if [ "$2" = "rollback" ]; then
        perform_rollback
    fi
    exit 1
}

# Rollback function
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
    sudo rm -rf ~/.node-red
    sudo rm -f "$ENV_FILE"
    sudo rm -f "$CREDS_FILE"

    echo "Rollback complete. Please check the error message above and try again."
}

# Generate credentials function
generate_credentials() {
    echo "Generating secure credentials..."
    
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
Username: admin
Password: $NODERED_PASSWORD

InfluxDB:
Username: admin
Password: $INFLUXDB_PASSWORD
Organization: metsci
Bucket: weather
Token: $INFLUXDB_TOKEN

Grafana:
Username: admin
Password: $GRAFANA_PASSWORD

Save these credentials and delete this file!
EOL

    # Create environment file
    sudo mkdir -p /etc/metsci-dashboard
    sudo chmod 700 /etc/metsci-dashboard
    
    sudo tee "$ENV_FILE" > /dev/null << EOL
# MeteoScientific Dashboard Environment
NODERED_USERNAME=admin
NODERED_PASSWORD=$NODERED_PASSWORD
INFLUXDB_USERNAME=admin
INFLUXDB_PASSWORD=$INFLUXDB_PASSWORD
INFLUXDB_TOKEN=$INFLUXDB_TOKEN
INFLUXDB_ORG=metsci
INFLUXDB_BUCKET=weather
GRAFANA_USERNAME=admin
GRAFANA_PASSWORD=$GRAFANA_PASSWORD
EOL

    sudo chmod 600 "$ENV_FILE"
    sudo chown root:root "$ENV_FILE"
    
    echo "✓ Credentials generated and stored"
}

# Check system requirements
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

# Install Node.js and verify
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

# Install Node-RED with improved handling
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

    # Create settings file with authentication
    sudo mkdir -p ~/.node-red
    cd ~/.node-red || error_exit "Failed to access Node-RED directory"
    
    # Install bcryptjs locally for password hashing
    npm install bcryptjs || error_exit "Failed to install bcryptjs"
    
    # Generate password hash
    NODERED_HASH=$(node -e "console.log(require('bcryptjs').hashSync(process.argv[1], 8))" "$NODERED_PASSWORD")
    
    # Update settings.js
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
}

# Install InfluxDB
install_influxdb() {
    echo "Installing InfluxDB..."
    source "$ENV_FILE"
    
    # Remove any existing installation
    sudo systemctl stop influxdb || true
    sudo apt-get remove -y influxdb2 || true
    sudo apt-get autoremove -y
    
    # Install fresh
    curl -s https://repos.influxdata.com/influxdata-archive_compat.key | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.asc > /dev/null
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.asc] https://repos.influxdata.com/debian stable main" | sudo tee /etc/apt/sources.list.d/influxdata.list

    sudo apt-get update
    sudo apt-get install -y influxdb2 || error_exit "Failed to install InfluxDB"
    
    # Start service
    echo "Starting InfluxDB service..."
    sudo systemctl daemon-reload
    sudo systemctl enable influxdb
    sudo systemctl start influxdb
    
    # Verify service is running
    if ! systemctl is-active --quiet influxdb; then
        echo "InfluxDB service failed to start. Checking logs..."
        journalctl -u influxdb --no-pager -n 50
        error_exit "InfluxDB service failed to start" "rollback"
    fi
    
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
    
    # Initialize InfluxDB
    echo "Initializing InfluxDB..."
    influx setup \
        --username "$INFLUXDB_USERNAME" \
        --password "$INFLUXDB_PASSWORD" \
        --org "$INFLUXDB_ORG" \
        --bucket "$INFLUXDB_BUCKET" \
        --retention 0 \
        --token "$INFLUXDB_TOKEN" \
        --force || error_exit "Failed to initialize InfluxDB"
        
    echo "✓ InfluxDB installed and configured"
}

# Install Grafana
install_grafana() {
    echo "Installing Grafana..."
    source "$ENV_FILE"
    
    # Use keyring file instead of apt-key
    curl -fsSL https://packages.grafana.com/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/grafana-archive-keyring.gpg
    
    echo "deb [signed-by=/usr/share/keyrings/grafana-archive-keyring.gpg] https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

    sudo apt-get update
    sudo apt-get install -y grafana || error_exit "Failed to install Grafana"
    
    # Update Grafana config
    sudo tee /etc/grafana/grafana.ini > /dev/null << EOL
[security]
admin_user = $GRAFANA_USERNAME
admin_password = $GRAFANA_PASSWORD
EOL
}

# Start services
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

# Verify services
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
        
        if ! systemctl is-active --quiet $service; then
            journalctl -u $service --no-pager -n 50
            error_exit "Service $service failed to start" "rollback"
        fi
        
        if ! curl -s "http://localhost:$port$endpoint" > /dev/null; then
            error_exit "Service $service is not responding" "rollback"
        fi
        
        echo "✓ $service verified"
    done
    
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
1. Save your credentials from $CREDS_FILE
2. Delete the credentials file: rm $CREDS_FILE
3. Set up Cloudflare tunnel for remote access (optional)

For troubleshooting, check the log at: $LOG_FILE
"
}

# Main installation process
main() {
    show_progress 1 "Checking system requirements"
    check_requirements
    
    show_progress 2 "Generating secure credentials"
    generate_credentials
    
    show_progress 3 "Installing Node.js"
    install_nodejs
    
    show_progress 4 "Installing Node-RED"
    install_nodered
    
    show_progress 5 "Installing InfluxDB"
    install_influxdb
    
    show_progress 6 "Installing Grafana"
    install_grafana
    
    show_progress 7 "Starting and verifying services"
    start_services
    verify_services
    
    print_next_steps
}

# Run the main installation
main