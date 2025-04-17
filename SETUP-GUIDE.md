# ONVIF Server Setup Guide

This guide provides step-by-step instructions for setting up and running the ONVIF server to proxy IP cameras to UniFi Protect or other NVRs.

## Prerequisites

- **Operating System**: Linux (with macvlan support)
- **Node.js**: Installed and working
- **Root Access**: Required for network configuration
- **IP Cameras**: Accessible via RTSP streams
- **NVR**: UniFi Protect or other compatible NVR system

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/molesza/onvif-camera-proxy.git
   cd onvif-camera-proxy
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

## Configuration

### 1. Create Configuration

Create a configuration file by using the `--create-config` option:

```bash
node main.js --create-config
```

You'll be prompted to enter:
- NVR/Camera Server IP or hostname
- Onvif Username
- Onvif Password

This will:
1. Generate a YAML configuration file (`config-<ip>.yaml`)
2. Create a network setup script (`setup-network-<ip>.sh`)
3. Update the combined configuration and setup script

### 2. Multiple NVRs (Optional)

To add cameras from additional NVRs, run the same command for each NVR:

```bash
node main.js --create-config
```

The script will automatically:
- Create individual config files for each NVR
- Update the combined configuration (`config-combined.yaml`)
- Update the combined network script (`setup-network-combined.sh`)

## Deployment

### 1. Set Up Network Interfaces

The most crucial step is to create the virtual network interfaces. This **must** be done before starting the server.

```bash
sudo ./setup-network-combined.sh
```

After running the script, verify that the interfaces were created successfully:

```bash
ip -4 addr show | grep 192.168.6
```

You should see all the expected IP addresses (192.168.6.3 through 192.168.6.50) associated with interfaces named `onv1_` through `onv48_`.

**Troubleshooting Interface Creation:**

If some interfaces are missing:
- Ensure you ran the script with `sudo` (root privileges)
- Check for any error messages during script execution
- Try running the script again

> **Note**: The error message `Error: listen EADDRNOTAVAIL: address not available 192.168.6.xx` indicates that the particular virtual interface for that IP address was not created successfully.
> 
> **Important**: These virtual interfaces don't persist across system reboots. You'll need to run this script again after each reboot.

### 2. Start the ONVIF Server

After setting up the network interfaces, start the server:

```bash
node main.js config-combined.yaml --debug
```

The `--debug` flag enables detailed logging, which is helpful for troubleshooting.

You should see output showing:
- Port assignments for each NVR
- Startup of virtual ONVIF servers for each camera
- TCP proxy setups for RTSP and snapshot ports

### 3. Add Cameras to Your NVR

Now you can add the cameras to your NVR:

#### For UniFi Protect:
1. Go to the UniFi Protect interface
2. Select "Add Devices" or "Adopt" 
3. Use the "Manual Add" option if automatic discovery doesn't work
4. Enter the static IP addresses shown in the server logs
5. Use the default ONVIF username/password you specified during configuration

## Troubleshooting

### Network Interface Issues

- **Error: `listen EADDRNOTAVAIL: address not available`**: Indicates the virtual network interfaces haven't been created or were created incompletely. This specific error points to exactly which IP address is missing. Run the setup script with root privileges and verify all interfaces exist.

- **Interfaces disappear after reboot**: Normal behavior. Run the setup script again after each system reboot.

- **Interface creation fails**: Ensure you're running with sudo/root privileges and your system supports macvlan. Check the output of the setup script for any error messages.

- **Interface exists but IP binding fails**: Sometimes the interfaces might exist but not have the proper IP configuration. You can verify with:
  ```bash
  ip addr show | grep 192.168.6
  ```

### Camera Discovery Issues

- **Cameras not discovered by NVR**: Try manual addition using the static IPs.

- **Discovery port conflicts**: The server disables UDP discovery by default. This is intentional to avoid port conflicts.

### Port Conflicts

- **RTSP/Snapshot port conflicts**: The server automatically assigns unique ports for each NVR. Check the logs for the assigned ports.

## Advanced Usage

### Testing with a Single Camera

For initial testing, you can create a test configuration with just one camera:

```bash
node create-test-config.js
```

### Running as a Service

To run the server automatically at startup, create a systemd service:

1. Create a service file:
   ```bash
   sudo nano /etc/systemd/system/onvif-server.service
   ```

2. Add the following content (adjust paths as needed):
   ```
   [Unit]
   Description=ONVIF Server Proxy
   After=network.target

   [Service]
   Type=simple
   User=root
   WorkingDirectory=/path/to/onvif-server
   ExecStartPre=/path/to/onvif-server/setup-network-combined.sh
   ExecStart=/usr/bin/node /path/to/onvif-server/main.js config-combined.yaml
   Restart=on-failure

   [Install]
   WantedBy=multi-user.target
   ```

3. Enable and start the service:
   ```bash
   sudo systemctl enable onvif-server
   sudo systemctl start onvif-server
   ```

## Common Issues & Solutions

1. **Missing WSDL Files**: The project includes vendored WSDL/XSD files. If you encounter issues, ensure the `wsdl` directory is intact.

2. **UniFi Protect Adoption Timeout**: Try manually adding cameras with the static IPs assigned by the setup script.

3. **Camera Stream Quality**: The configuration extracts both high and low-quality streams if available. Check the generated configuration file.

4. **Resource Limitations**: Running many virtual cameras can consume significant system resources. Consider limiting the number of cameras if you encounter performance issues.
