# ONVIF Server Technical Context

## Technology Stack
- **Node.js**: Core runtime environment
- **SOAP/WSDL**: Protocol implementation for ONVIF
- **node-tcp-proxy**: For proxying TCP streams (RTSP)
- **YAML**: Configuration file format
- **Linux networking**: For virtual network interface creation (macvlan)

## Core Dependencies
- `soap`: SOAP protocol implementation
- `node-tcp-proxy`: TCP proxying
- `argparse`: Command-line argument parsing
- `yaml`: YAML parsing and generation
- `simple-node-logger`: Logging functionality
- `node-uuid`: UUID generation for device identifiers
- `xml2js`: XML parsing for ONVIF messages

## System Requirements
- Linux operating system (macvlan support)
- Root privileges for network interface creation
- Node.js runtime
- Network connectivity between proxy server, cameras, and NVRs

## Development Setup
- Standard Node.js development environment
- Access to ONVIF WSDL/XSD specifications (vendored in project)
- Testing requires actual camera and NVR hardware

## Technical Constraints
- ONVIF compatibility limited to core features (Device and Media services)
- Requires static IP addressing for reliable operation
- Network interface creation requires root access
- TCP proxy connections may experience higher latency than direct connections

## Architecture Overview
1. **Configuration Layer**: Handles config file generation and parsing
   - `src/config-builder.js`: Creates configuration from ONVIF camera responses
   - YAML files store configuration for cameras and NVRs

2. **Network Layer**: Manages virtual network interfaces
   - Generated shell scripts create macvlan interfaces
   - Static IP assignment for predictable addressing

3. **ONVIF Protocol Layer**: Implements camera simulation
   - `src/onvif-server.js`: Core ONVIF protocol implementation
   - Handles device service and media service SOAP requests

4. **Proxy Layer**: Routes video traffic
   - TCP proxy for RTSP and HTTP (snapshot) traffic
   - Dynamic port assignment to avoid conflicts

## External Integration Points
- **UniFi Protect NVR**: Primary consumer of ONVIF services
- **IP Cameras**: Source of RTSP streams being proxied
- **Network Infrastructure**: Required for routing between components
