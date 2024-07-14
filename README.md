### README.md

# RTSP to HLS Conversion Service

This script automates the installation and configuration of a service that converts RTSP streams to HLS using FFmpeg and Nginx. It also provides an option to edit the RTSP camera information.

## Features

- Installs necessary dependencies (FFmpeg, Nginx, sqlite3).
- Configures Nginx to serve HLS streams.
- Encrypts and stores RTSP camera credentials.
- Creates a service script to manage the RTSP to HLS conversion.
- Provides a command-line option to edit the RTSP camera information.

## Prerequisites

- Ubuntu-based system.
- Root privileges.

## Installation

1. **Save the script**: Save the provided script to a file, e.g., `install_rtsp_to_hls.sh`.

2. **Make the script executable**:

    ```bash
    chmod +x install_rtsp_to_hls.sh
    ```

3. **Run the script**:

    ```bash
    sudo ./install_rtsp_to_hls.sh
    ```

4. **Follow the prompts**: Provide the necessary information (RTSP camera IP, username, and password).

## Command-Line Options

- `-e`: Edit the current camera information in the `rtsp_to_hls` service script.

    ```bash
    sudo ./install_rtsp_to_hls.sh -e
    ```

## Service Management

The service script provides options to start, stop, restart, and check the status of the RTSP to HLS conversion service:

```bash
sudo /etc/init.d/rtsp_to_hls {start|stop|restart|status}
```

## Usage

To access the camera stream, open your web browser and navigate to:

```http
http://{server_ip}:8888/hls/stream.m3u8
```

Replace `{server_ip}` with the IP address of the server where the service is installed.

## Configuration on Mainsail/Moonraker

1. Click the gears icon on the top right corner of the Mainsail interface.
2. Click on "Webcams".
3. Click on "Add Webcam".
4. Define a name for your webcam.
5. Under "URL Stream", paste the following URL:

    ```http
    http://{server_ip}:8888/hls/stream.m3u8
    ```

    Replace `{server_ip}` with the IP address of the server where the service is installed.

6. Leave "URL Snapshot" with default values.
7. Under "Service", choose "HLS Stream".
8. Click "Save Webcam".

## Detailed Description of the Script

### Logging Function

- **log()**: Logs messages to both the console and a log file (`/var/log/rtsp_to_hls_install.log`). Each log message is timestamped for easy tracking.

### Dependency Installation

- **install_dependencies()**: Updates package lists and installs FFmpeg, Nginx, and sqlite3. Logs success or failure of the installation process.

### User Input

- **request_user_input()**: Prompts the user to enter the RTSP camera IP address, username, and password. The password input is hidden for security.

### Machine's IP Address

- **get_hls_ip()**: Retrieves the IP address of the machine where the service is being installed. Logs the IP address or an error if it fails to retrieve it.

### Storing Credentials

- **store_credentials()**: Encrypts the RTSP camera credentials (username and password) using `openssl` and stores them securely in `/etc/nginx/rtsp_credentials.enc`. Logs success or failure.

### Nginx Configuration

- **configure_nginx()**: Configures Nginx to serve HLS streams. Creates a new Nginx site configuration file `/etc/nginx/sites-available/rtsp_to_hls` and links it to the enabled sites directory. Restarts Nginx to apply the configuration. Logs success or failure.

### Firewall Configuration

- **configure_firewall()**: Configures the firewall to allow traffic on port 8888. Uses `ufw` to allow the port and logs success or failure.

### Communication Check

- **check_communication()**: Verifies if the HLS server is accessible by checking if the port 8888 is open and if the HLS stream can be accessed via `curl`. Logs the results of the communication check.

### Service Script Creation

- **create_service_script()**: Creates the `rtsp_to_hls` service script at `/etc/init.d/rtsp_to_hls`. The script manages the RTSP to HLS conversion process using FFmpeg. The service script includes commands to start, stop, and check the status of the conversion process. Logs success or failure.

### Enabling Boot Service

- **enable_on_boot()**: Enables the `rtsp_to_hls` service script to run on system boot using `update-rc.d`. Logs success or failure.

### Starting the Service

- **start_service()**: Starts the `rtsp_to_hls` service and verifies if it started successfully by checking the process ID. Logs the result.

### Editing Camera Information

- **edit_camera_info()**: Provides an option to stop the service, prompt the user for new RTSP camera information, update the service script with the new information, and restart the service. Logs each step's success or failure.

### Main Function

- **main()**: Checks if the `-e` option is provided to edit the camera information. If `-e` is provided, it runs `edit_camera_info()`. Otherwise, it proceeds with the full installation process, including all the steps from installing dependencies to starting the service.

## Log File

The installation and service logs are stored in `/var/log/rtsp_to_hls_install.log`. This log file contains detailed information about each step of the installation and configuration process, which can be useful for troubleshooting.

## Service Script

The `rtsp_to_hls` service script is created at `/etc/init.d/rtsp_to_hls` and is responsible for starting, stopping, and checking the status of the RTSP to HLS conversion process. It uses FFmpeg to convert RTSP streams to HLS format and serves them via Nginx.

## Troubleshooting

If the script fails at any step, check the log file (`/var/log/rtsp_to_hls_install.log`) for detailed error messages. This log file will provide insights into what went wrong and help in diagnosing the issue.

## License

This project is licensed under the MIT License.

## Author

Created by Pedro Caribe. For any questions or suggestions, feel free to contact me at dev.pcaribe@gmail.com.