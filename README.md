# RTSP-to-HLS
Script that automates the installation and configuration of a service that converts RTSP streams to HLS using FFmpeg and Nginx. Developed for use with Mainsail

# RTSP to HLS Conversion Service

This script automates the installation and configuration of a service that converts RTSP streams to HLS using FFmpeg and Nginx. It provides an option to edit the RTSP camera information as well.

## Features

- Installs necessary dependencies (FFmpeg, Nginx).
- Configures Nginx to serve HLS streams.
- Encrypts and stores RTSP camera credentials.
- Creates a service script to start/stop the RTSP to HLS conversion.
- Provides a command-line option to edit the RTSP camera information.

## Prerequisites

- Ubuntu-based system
- Root privileges

## Installation

1. Save the provided script to a file, e.g., `install_rtsp_to_hls.sh`.
2. Make the script executable:

    ```bash
    chmod +x install_rtsp_to_hls.sh
    ```

3. Run the script:

    ```bash
    sudo ./install_rtsp_to_hls.sh
    ```

4. Follow the on-screen prompts to provide the necessary information (RTSP camera IP, username, password).

## Command-Line Options

- `-e`: Edit the current camera information in the `rtsp_to_hls` service script.

    ```bash
    sudo ./install_rtsp_to_hls.sh -e
    ```

## Service Management

The service script provides options to start, stop, restart, and check the status of the RTSP to HLS conversion service.

```bash
sudo /etc/init.d/rtsp_to_hls {start|stop|restart|status}
```

Detailed Description of the Script
Functions
log()
Logs messages to the console and a log file.

install_dependencies()
Updates package lists and installs FFmpeg, Nginx, and sqlite3.

request_user_input()
Prompts the user to enter RTSP camera IP, username, and password.

get_hls_ip()
Gets the IP address of the machine where the service is being installed.

store_credentials()
Encrypts and stores RTSP camera credentials.

configure_nginx()
Configures Nginx to serve HLS streams.

configure_firewall()
Configures the firewall to allow traffic on port 8888.

check_communication()
Checks if the HLS server is accessible.

create_service_script()
Creates the rtsp_to_hls service script.

enable_on_boot()
Enables the service script to run on boot.

start_service()
Starts the rtsp_to_hls service and checks if it started successfully.

edit_camera_info()
Stops the service, prompts the user for new RTSP camera information, updates the service script, and restarts the service.

Main Installation Function
main()
Checks if the -e option is provided to edit the camera information; otherwise, it proceeds with the full installation process.

Log File
The installation and service logs are stored in /var/log/rtsp_to_hls_install.log.

Service Script
The rtsp_to_hls service script is created at /etc/init.d/rtsp_to_hls and is responsible for starting, stopping, and checking the status of the RTSP to HLS conversion process.

Troubleshooting
If the script fails at any step, check the log file (/var/log/rtsp_to_hls_install.log) for detailed error messages.


