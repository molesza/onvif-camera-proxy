# ONVIF Server Implementation Guide

This document provides a comprehensive guide to the implementation and operation of the Virtual ONVIF Server for Unifi Protect integration. It details the technical aspects, configuration process, and operational procedures.

## Table of Contents

1. [Overview](#overview)
2. [Technical Architecture](#technical-architecture)
3. [Network Configuration](#network-configuration)
4. [Installation and Setup](#installation-and-setup)
5. [Running the ONVIF Server](#running-the-onvif-server)
6. [Troubleshooting](#troubleshooting)
7. [Advanced Configuration](#advanced-configuration)

## Overview

The Virtual ONVIF Server creates virtual ONVIF-compatible devices that proxy RTSP streams from existing cameras or NVRs. This allows systems like Unifi Protect to integrate with multi-channel NVRs or cameras that aren't directly supported.

Key features:
- Creates virtual network interfaces with unique MAC addresses
- Implements ONVIF Profile S for live streaming
- Supports both high and low-quality streams
- Proxies RTSP streams and snapshot requests

## Technical Architecture

### Components

1. **Node.js Application**: The core server that implements the ONVIF protocol
2. **MacVLAN Interfaces**: Virtual network interfaces that allow multiple MAC addresses on a single physical interface
3. **TCP Proxy**: Forwards RTSP and snapshot requests to the actual camera/NVR
4. **SOAP Protocol**: Used for ONVIF communication
5. **DHCP Client**: Obtains IP addresses for the virtual interfaces

### Technologies Used

- **Node.js**: Runtime environment for the server
- **SOAP**: Protocol for ONVIF communication
- **MacVLAN**: Linux kernel feature for creating virtual network interfaces
- **DHCP**: Dynamic Host Configuration Protocol for IP address assignment
- **YAML**: Configuration file format
- **RTSP**: Real-Time Streaming Protocol for video streams

## Network Configuration

### MacVLAN Interfaces

The system uses MacVLAN interfaces to create virtual network interfaces with unique MAC addresses. This is crucial for Unifi Protect to recognize each virtual camera as a separate device.

MacVLAN interfaces are created as follows:
```bash
ip link add [NAME] link [PHYSICAL_INTERFACE] address [MAC_ADDRESS] type macvlan mode bridge
```

### ARP Configuration

To prevent ARP conflicts with multiple interfaces on the same subnet, we configure ARP settings for each interface:
```bash
echo 1 > /proc/sys/net/ipv4/conf/[INTERFACE]/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/[INTERFACE]/arp_announce
```

### IP Address Assignment

IP addresses can be assigned either via DHCP or statically:
- **DHCP**: The system uses `dhclient` to request IP addresses from the DHCP server
- **Static**: IP addresses can be manually assigned with the `--static` flag

## Installation and Setup

### Prerequisites

- Node.js v16 or higher
- Linux system with support for MacVLAN interfaces
- DHCP server on the network (optional, for dynamic IP assignment)

### Configuration Generation

The system can automatically generate configuration by connecting to an existing ONVIF camera or NVR:

```bash
node main.js --create-config
```

This will:
1. Connect to the specified ONVIF device
2. Retrieve all available video profiles
3. Generate a YAML configuration file
4. Create network setup scripts

### Configuration Files

The system generates several configuration files:
- `config-[IP].yaml`: Configuration for a specific NVR
- `config-test-[IP].yaml`: Test configuration with a single camera
- `config-combined.yaml`: Combined configuration for multiple NVRs
- `setup-network-[IP].sh`: Network setup script for a specific NVR
- `setup-network-test-[IP].sh`: Test network setup script with a single camera
- `setup-network-combined.sh`: Combined network setup script for multiple NVRs

## Running the ONVIF Server

### Testing with a Single Camera

For initial testing, it's recommended to start with a single camera:

```bash
# Generate test configuration
node extract-test-config.js 192.168.6.219

# Set up the network interface
sudo ./setup-network-test-192.168.6.219.sh

# Run the ONVIF server
node main.js config-test-192.168.6.219.yaml
```

### Running the Full Configuration

Once testing is successful, you can run the full configuration:

```bash
# Set up all network interfaces
sudo ./setup-network-192.168.6.219.sh

# Run the ONVIF server
node main.js config-192.168.6.219.yaml
```

### Running in Background

To run the server in the background, you can use one of these methods:

#### Using nohup

```bash
# Kill any existing processes first
pkill -f "node main.js config"

# Set up the network interfaces
sudo ./setup-network-192.168.6.219.sh

# Run the server detached with nohup
nohup node main.js config-192.168.6.219.yaml > onvif-server.log 2>&1 &
```

#### Using screen

```bash
# Install screen if not already installed
sudo apt-get install screen

# Create a named screen session
screen -S onvif-server

# Inside the screen session, run:
sudo ./setup-network-192.168.6.219.sh
node main.js config-192.168.6.219.yaml

# Detach from the screen session with Ctrl+A followed by D
# You can later reattach with:
screen -r onvif-server
```

#### Using systemd

Create a systemd service file:

```bash
sudo nano /etc/systemd/system/onvif-server.service
```

Add the following content:

```
[Unit]
Description=ONVIF Virtual Server
After=network.target

[Service]
Type=simple
User=molesza
WorkingDirectory=/home/molesza/onvif-server
ExecStartPre=/bin/bash -c '/home/molesza/onvif-server/setup-network-192.168.6.219.sh'
ExecStart=/usr/bin/node /home/molesza/onvif-server/main.js /home/molesza/onvif-server/config-192.168.6.219.yaml
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Then enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable onvif-server
sudo systemctl start onvif-server
```

## Troubleshooting

### Interface Detection Issues

If the system has trouble detecting the physical interface, it now uses a more robust method:

```bash
HOST_IP=$(hostname -I | awk '{print $1}')
PHYS_IFACE=$(ip -o addr show | grep "$HOST_IP" | grep -v macvlan | awk '{print $2}' | cut -d':' -f1)
```

This looks for the interface with the host's IP address, excluding macvlan interfaces.

### Port Conflicts

If you see errors like `EADDRINUSE: address already in use`, ensure you're not running multiple instances of the server. Use:

```bash
pkill -f "node main.js config"
```

to stop any existing instances.

### ARP Conflicts

If cameras are showing the same video stream in Unifi Protect, ensure the ARP settings are properly configured:

```bash
echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce
```

### ONVIF Authentication Issues

If you see "Wsse authorized time check failed" errors, ensure your system time is synchronized with the camera/NVR.

### Slow ONVIF Discovery

ONVIF discovery can be slow, and it may take time for all devices to appear in Unifi Protect or other ONVIF-compatible systems. This is normal behavior as ONVIF discovery relies on multicast/broadcast messages that can sometimes be delayed in the network.

If not all cameras appear immediately:
1. Wait 5-10 minutes for the discovery process to complete
2. Restart the Unifi Protect service or refresh the discovery page
3. Ensure that multicast traffic is allowed on your network
4. Check that the ONVIF server is running for all interfaces (use the test-camera-ips.sh script)

You can also manually add cameras by IP address if they don't appear in the discovery list.

## Advanced Configuration

### Custom MAC Addresses

You can customize the MAC addresses in the configuration files. Ensure they follow the locally administered MAC address format (first byte has bit 1 set).

### Stream Selection

The system automatically selects the best streams based on quality and resolution. You can manually adjust this in the configuration files.

### Multiple NVRs

To combine cameras from multiple NVRs:

1. Generate configurations for each NVR
2. Use the combined configuration and network script
3. Run the server with the combined configuration

```bash
node main.js config-combined.yaml
```

### Custom RTSP Paths

For cameras with non-standard RTSP paths, you can manually edit the configuration file to specify the correct paths.