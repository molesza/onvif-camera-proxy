# ONVIF Server System Patterns

## Architecture Patterns

### 1. Proxy Design Pattern
The entire system implements a proxy pattern where the ONVIF server acts as an intermediary between:
- **Client**: Network Video Recorder (NVR) like UniFi Protect
- **Service**: IP Camera with RTSP stream capability

The proxy intercepts ONVIF protocol requests, handles them appropriately, and forwards video stream requests.

### 2. Service-Oriented Architecture (SOA)
The system exposes SOAP web services that implement ONVIF protocols:
- **Device Service**: Handles device management functionality
- **Media Service**: Manages media streaming configuration

Each service exposes specific endpoints defined by the ONVIF WSDL specifications.

### 3. Factory Pattern
The `createServer` function in `onvif-server.js` acts as a factory, creating and configuring `OnvifServer` instances based on configuration parameters.

### 4. Configuration Builder Pattern
The `config-builder.js` implements a builder pattern that:
1. Queries actual cameras for their capabilities
2. Transforms this information into a structured configuration
3. Generates both individual and combined configurations

## Data Flow Patterns

### 1. Configuration Flow
```mermaid
graph TD
    A[User Input] --> B[createConfig]
    B --> C[Query Camera]
    C --> D[Generate Config]
    D --> E[Write YAML]
    D --> F[Generate Network Scripts]
```

### 2. Server Startup Flow
```mermaid
graph TD
    A[Read Config] --> B[Parse YAML]
    B --> C[Calculate Static IPs]
    C --> D[Assign Proxy Ports]
    D --> E[Create Server Instances]
    E --> F[Start SOAP Services]
    F --> G[Start TCP Proxies]
```

### 3. Request Handling Flow
```mermaid
graph TD
    A[NVR Request] --> B[SOAP Server]
    B --> C{Request Type}
    C -->|Device Info| D[Return Device Info]
    C -->|Media Info| E[Return Media Info]
    C -->|Stream URI| F[Return Proxied URI]
    NVR[NVR] --> |Connect to Stream| G[TCP Proxy]
    G --> |Forward Stream| H[Camera]
```

## Key Technical Decisions

### 1. Static IP Assignment
- Decision: Use static IP addresses for virtual interfaces
- Rationale: Ensures consistent addressing for NVR to connect to
- Implementation: Generated shell scripts with static IP calculations

### 2. Dynamic Port Assignment
- Decision: Dynamically assign proxy ports to avoid conflicts
- Rationale: Enables multiple NVRs to connect without port collisions
- Implementation: Runtime port assignment in main.js with NVR tracking

#### Implementation Details
The dynamic port assignment is implemented in main.js using the following approach:
1. Initialize base ports (RTSP=8554, Snapshot=8580)
2. Track NVRs and their assigned ports in a map during runtime
3. When a new NVR is encountered:
   - Assign current base ports to the NVR
   - Increment base ports for the next NVR (RTSP +2, Snapshot +1)
4. Update the configuration in memory with the assigned ports
5. Use these updated ports when setting up TCP proxies

This approach follows the required pattern:
- First NVR: RTSP=8554, Snapshot=8580
- Second NVR: RTSP=8556, Snapshot=8581
- Third NVR: RTSP=8558, Snapshot=8582

The solution maintains the original configuration files while dynamically adjusting ports at runtime to avoid conflicts.

### 3. MAC Address Generation
- Decision: Generate consistent MAC addresses based on NVR IP and camera ID
- Rationale: Ensures virtual interfaces have unique but deterministic MAC addresses
- Implementation: Hash-based generation in config-builder.js

### 4. WSDL Vendoring
- Decision: Vendor/include WSDL/XSD files locally instead of fetching remotely
- Rationale: Avoids dependency on external resources, prevents blocking by Cloudflare
- Implementation: Local copies in wsdl/vendor/ with corrected relative paths

## Error Handling Patterns

### 1. Graceful Degradation
- System attempts to continue operation when parts fail
- Example: UDP discovery errors don't prevent core ONVIF functionality

### 2. Structured Logging
- Consistent logging pattern for troubleshooting
- Debug mode toggles verbose logging

## Implementation Challenges (Resolved)

### 1. OnvifServer Reference Issue - FIXED
- The issue was related to class definition and export in `src/onvif-server.js`
- Fixed by properly exporting both class and factory function
- Updated syntax and code structure to eliminate errors

### 2. Network Interface Management
- Network interfaces require root access and may need recreation after system restart
- Current pattern requires manual intervention to run setup scripts
- Enhanced with IP verification and robust retry logic

### 3. Multi-NVR Port Conflicts - FIXED
- Implemented runtime port assignment in main.js
- Added NVR tracking and dynamic port allocation
- Resolved EADDRINUSE errors when using multiple NVRs
