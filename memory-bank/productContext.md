# ONVIF Server Product Context

## Purpose
The ONVIF server proxy exists to solve compatibility issues between Network Video Recorders (NVRs) like UniFi Protect and IP cameras that:
1. Don't support the ONVIF protocol natively
2. Have incomplete ONVIF implementations that prevent proper discovery/adoption
3. Need specific configuration to work with particular NVR systems

## Problem Space
- Many IP cameras use proprietary protocols instead of standard ONVIF
- NVRs like UniFi Protect expect standards-compliant ONVIF protocol support
- Direct camera-to-NVR communication often fails due to protocol mismatches
- Manual camera configuration is complex and time-consuming
- Multiple NVRs can cause port conflicts when trying to adopt cameras

## Solution Approach
The server acts as a middleware that:
1. Presents itself to the NVR as an ONVIF-compliant camera
2. Creates virtual network interfaces (macvlan) with unique MAC addresses for each camera
3. Handles ONVIF discovery, authentication, and service requests
4. Proxies RTSP video streams and snapshot requests to the actual cameras
5. Dynamically assigns ports to avoid conflicts when supporting multiple NVRs

## User Experience Goals
- Seamless camera adoption in UniFi Protect without manual configuration
- Reliable video streaming through the proxy
- Simple configuration generation through command-line tools
- Support for both high and low-quality video streams
- Multi-NVR support with a single server instance

## Limitations & Constraints
- Requires root access to create network interfaces
- Static IP assignment needed for reliable operation
- Network configuration must be re-applied after each system reboot
- Limited to cameras that support RTSP streaming
