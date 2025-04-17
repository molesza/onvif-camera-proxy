# ONVIF Server Project Brief

## Project Overview
This project implements a virtual ONVIF server that acts as a proxy between Network Video Recorders (NVRs) like UniFi Protect and IP cameras. The server simulates ONVIF protocol support for cameras that may not natively have it, allowing NVRs to discover and adopt these cameras.

## Core Objectives
1. Enable UniFi Protect and other NVRs to discover and adopt IP cameras through ONVIF protocol
2. Support multiple NVRs with unique configurations
3. Provide a reliable proxy mechanism for video streams (RTSP)
4. Enable consistent camera access through static IP configuration

## Key Components
- ONVIF protocol implementation using SOAP/WSDL
- Network interface configuration management (macvlan interfaces)
- Configuration generation for camera and server settings
- RTSP and snapshot stream proxying

## Success Criteria
- Successful camera discovery and adoption by UniFi Protect
- Stable video streaming through the proxy server
- Support for multiple NVRs without conflicts
- Proper static IP assignment and network interface setup

## Current Status
The server has been through multiple troubleshooting phases and many issues have been resolved, but there is a current critical issue preventing startup (ReferenceError with OnvifServer class).
