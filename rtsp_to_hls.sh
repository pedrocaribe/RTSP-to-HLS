#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
WHITE='\033[0;37m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

LOG_FILE="/var/log/rtsp_to_hls_install.log"
SERVICE_SCRIPT_PATH="/etc/init.d/rtsp_to_hls"

# Function to log messages
log() {
    echo -e "$1" | tee -a $LOG_FILE
}

# Function to install dependencies
install_dependencies() {
    log "${WHITE}Updating package lists and installing dependencies...${NC}"
    sudo apt update &>> $LOG_FILE && sudo apt install -y ffmpeg nginx sqlite3 &>> $LOG_FILE
    if [ $? -eq 0 ]; then
        log "${WHITE}Dependencies installed successfully. ${GREEN}[OK]${NC}"
    else
        log "${WHITE}Failed to install dependencies. ${RED}[FAILED]${NC}"
        exit 1
    fi
}

# Function to request user input
request_user_input() {
    read -p "Enter RTSP camera IP address: " rtsp_ip
    read -p "Enter RTSP camera username: " rtsp_user
    read -s -p "Enter RTSP camera password: " rtsp_password
    echo
}

# Function to get the machine's IP address
get_hls_ip() {
    hls_ip=$(hostname -I | awk '{print $1}')
    if [ -z "$hls_ip" ]; then
        log "${WHITE}Failed to get HLS server IP address. ${RED}[FAILED]${NC}"
        exit 1
    fi
    log "${WHITE}HLS server IP address: $hls_ip${NC}"
}

# Function to encrypt and store RTSP camera credentials
store_credentials() {
    log "${WHITE}Encrypting and storing RTSP camera credentials...${NC}"
    encrypted_user=$(echo "$rtsp_user" | openssl enc -aes-256-cbc -a -salt -pass pass:your_secret_key)
    encrypted_password=$(echo "$rtsp_password" | openssl enc -aes-256-cbc -a -salt -pass pass:your_secret_key)
    echo "$rtsp_ip:$encrypted_user:$encrypted_password" | sudo tee /etc/nginx/rtsp_credentials.enc > /dev/null
    if [ $? -eq 0 ]; then
        log "${WHITE}Credentials stored successfully. ${GREEN}[OK]${NC}"
    else
        log "${WHITE}Failed to store credentials. ${RED}[FAILED]${NC}"
        exit 1
    fi
}

# Function to configure Nginx server
configure_nginx() {
    log "${WHITE}Configuring Nginx server...${NC}"
    sudo tee /etc/nginx/sites-available/rtsp_to_hls > /dev/null <<EOL
server {
    listen 8888;
    server_name $hls_ip;

    location /hls/ {
        types {
            application/vnd.apple.mpegurl m3u8;
            video/mp2t ts;
        }
        root /usr/share/nginx/html;
        add_header Cache-Control no-cache;
        add_header Access-Control-Allow-Origin *;
    }
}
EOL

    sudo ln -s /etc/nginx/sites-available/rtsp_to_hls /etc/nginx/sites-enabled/ &>> $LOG_FILE
    sudo systemctl reload nginx &>> $LOG_FILE
    sudo systemctl restart nginx &>> $LOG_FILE
    if [ $? -eq 0 ]; then
        log "${WHITE}Nginx configured successfully. ${GREEN}[OK]${NC}"
    else
        log "${WHITE}Failed to configure Nginx. ${RED}[FAILED]${NC}"
        exit 1
    fi
}

# Function to configure firewall
configure_firewall() {
    log "${WHITE}Configuring firewall...${NC}"
    sudo ufw allow 8888/tcp &>> $LOG_FILE
    sudo ufw status &>> $LOG_FILE
    if [ $? -eq 0 ]; then
        log "${WHITE}Firewall configured successfully. ${GREEN}[OK]${NC}"
    else
        log "${WHITE}Failed to configure firewall. ${RED}[FAILED]${NC}"
        exit 1
    fi
}

# Function to check communication
check_communication() {
    log "${WHITE}Checking communication on HLS server IP: $hls_ip${NC}"
    netstat_output=$(sudo netstat -tuln | grep 8888)
    curl_output=$(curl -I http://$hls_ip:8888/hls/stream.m3u8 2>>$LOG_FILE)

    if [[ $netstat_output == *"8888"* ]] && [[ $curl_output == *"HTTP/1.1 200 OK"* ]]; then
        log "${WHITE}Communication check successful. ${GREEN}[OK]${NC}"
    else
        log "${WHITE}Communication check failed. ${RED}[FAILED]${NC}"
        log "${WHITE}Netstat output:${NC} $netstat_output"
        log "${WHITE}Curl output:${NC} $curl_output"
        exit 1
    fi
}

# Function to create the service script
create_service_script() {
    log "${WHITE}Creating the rtsp_to_hls service script...${NC}"
    sudo tee /etc/init.d/rtsp_to_hls > /dev/null <<EOL
#!/bin/bash
### BEGIN INIT INFO
# Provides:             rtsp_to_hls
# Required-Start:       \$remote_fs \$syslog
# Required-Stop:        \$remote_fs \$syslog
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Short-Description:    Convert RTSP stream to HLS
# Description:          This script starts FFmpeg to convert RTSP stream to HLS
#                       One must have ffmpeg and nginx installed and configured
#                       prior to running this script.
### END INIT INFO

# Define the RTSP stream URL and the output directory
RTSP_URL="rtsp://$rtsp_user:$rtsp_password@$rtsp_ip:554/cam/realmonitor?channel=1&subtype=0"
OUTPUT_DIR="/usr/share/nginx/html/hls"
LOG_FILE="/var/log/rtsp_to_hls.log" # Log File
PID_FILE="/var/run/rtsp_to_hls.pid" # PID File to keep track if process is running

start() {
        echo "Starting RTSP to HLS conversion..."
        echo "\$(date): Starting RTSP to HLS conversion..." >> \$LOG_FILE

        # Ensure the output directory exists
        sudo mkdir -p \$OUTPUT_DIR

        # Set the correct permissions for the output directory
        sudo chown -R \$(whoami):\$(whoami) \$OUTPUT_DIR
        chmod 755 \$OUTPUT_DIR

        # Run FFmpeg to convert RTSP to HLS with verbose logging and keyframe adjustments
        ffmpeg -loglevel verbose -fflags nobuffer -flags low_delay -strict experimental \
                -i "\$RTSP_URL" -c:v copy -c:a aac -b:a 128k -f hls -hls_time 1 -hls_list_size 5 \
                -hls_flags delete_segments+append_list -hls_segment_type mpegts \
                -hls_segment_filename "\$OUTPUT_DIR/segment_%03d.ts" "\$OUTPUT_DIR/stream.m3u8" \
                >> \$LOG_FILE 2>&1 &

        echo \$! > \$PID_FILE
}

stop() {
        echo "Stopping RTSP to HLS conversion..."
        echo "\$(date): Stopping RTSP to HLS conversion..." >> \$LOG_FILE
        if [ -f \$PID_FILE ]; then
                kill \$(cat \$PID_FILE)
                rm -f \$PID_FILE
        fi
}

status() {
        if [ -f \$PID_FILE ]; then
                if ps -p \$(cat \$PID_FILE) > /dev/null; then
                        echo "RTSP to HLS conversion is running."
                else
                        echo "RTSP to HLS conversion is not running."
                fi
        else
                echo "RTSP to HLS conversion is not running."
        fi
}

case "\$1" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        restart)
                stop
                start
                ;;
        status)
                status
                ;;
        *)
                echo "Usage: \$0 {start|stop|restart|status}"
                exit 1
esac

exit 0
EOL

    sudo chmod +x /etc/init.d/rtsp_to_hls &>> $LOG_FILE
    if [ $? -eq 0 ]; then
        log "${WHITE}Service script created and made executable. ${GREEN}[OK]${NC}"
    else
        log "${WHITE}Failed to create and make executable the service script. ${RED}[FAILED]${NC}"
        exit 1
    fi
}

# Function to enable script to run on boot
enable_on_boot() {
    log "${WHITE}Enabling script to run on boot...${NC}"
    sudo update-rc.d rtsp_to_hls defaults &>> $LOG_FILE
    if [ $? -eq 0 ]; then
        log "${WHITE}Script enabled to run on boot. ${GREEN}[OK]${NC}"
    else
        log "${WHITE}Failed to enable script to run on boot. ${RED}[FAILED]${NC}"
        exit 1
    fi
}

# Function to start the hls_to_rtsp service
start_service() {
    PID_FILE="/var/run/rtsp_to_hls.pid" # PID File to keep track if process is running

    log "${WHITE}Starting hls_to_rtsp service...${NC}"
    sudo /etc/init.d/rtsp_to_hls start &>> $LOG_FILE


    if [ -f $PID_FILE ]; then

        PID_pid=$(cat $PID_FILE)
        PS_OUTPUT=$(ps -p $PID_pid) > /dev/null
        if [[ $PS_OUTPUT == *"$PID_pid"* ]] ; then

            log "${WHITE}hls_to_rtsp service started successfully. ${GREEN}[OK]${NC}"
        else
            log "${WHITE}Failed to start hls_to_rtsp service. ${RED}[FAILED]${NC}"
        fi

    else
        log "${WHITE}Failed to start hls_to_rtsp service. ${RED}[FAILED]${NC}"
        exit 1
    fi
}

# Function to edit the camera information
edit_camera_info() {
    log "${WHITE}Editing camera information...${NC}"
    sudo /etc/init.d/rtsp_to_hls stop &>> $LOG_FILE
    if [ $? -eq 0 ]; then
        log "${WHITE}Service stopped successfully. ${GREEN}[OK]${NC}"
    else
        log "${WHITE}Failed to stop the service. ${RED}[FAILED]${NC}"
        exit 1
    fi

    request_user_input

    create_service_script

    start_service
}

# Main installation function
main() {
    if [ "$1" == "-e" ]; then
        edit_camera_info
    else
        install_dependencies
        request_user_input
        get_hls_ip
        store_credentials
        configure_nginx
        configure_firewall
        check_communication
        create_service_script
        enable_on_boot
        start_service
    fi
}

main "$@"