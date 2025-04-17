# ONVIF Server Active Context

## Current Focus
The project is fully operational after fixing both the critical startup issues:

1. First issue (resolved): `ReferenceError: OnvifServer is not defined`
2. Second issue (resolved): `Error: listen EADDRNOTAVAIL: address not available 192.168.6.48:8094`

The successful workflow sequence is:
1. Run enhanced network setup script (`setup-network-combined.sh`)
2. Start the ONVIF server (`node main.js config-combined.yaml`)

The server now starts without errors and all virtual cameras are operational.

## Recent Code Changes

### 1. WS-Discovery Disabling
- Modified `main.js` to disable WS-Discovery entirely
- Added error handling to UDP socket code in `src/onvif-server.js`
- Reason: Server crashed due to multiple instances binding to UDP port 3702

### 2. WSDL/XSD Vendoring
- Vendored WSDL/XSD files into `wsdl/vendor/`
- Corrected `schemaLocation` and `location` attributes in WSDL/XSD files
- Added `uri` option to `soap.listen` calls
- Corrected file extensions for schemas
- Reason: Cloudflare was blocking WSDL/XSD downloads

### 3. Dynamic Proxy Port Assignment
- Modified `main.js` to assign unique proxy ports per NVR
- Starts from base ports (8554/8580) and increments
- Reason: Port conflicts when running with multiple NVRs

### 4. IP Address Assignment Changes
- Modified code to use pre-calculated static IPs instead of MAC lookup
- Modified `OnvifServer` constructor to accept IP directly
- Removed `getIpAddressFromMac` function
- Reason: `os.networkInterfaces()` didn't report IPs immediately after script execution

### 5. Network Script Improvements
- Modified `generateNetworkScript` and `generateCombinedNetworkScript` to default to static IPs
- Removed `--dhcp` option from combined script
- Reason: Static IPs are more reliable for this use case

## Issues Resolved

### 1. ReferenceError in OnvifServer
The `ReferenceError: OnvifServer is not defined` has been fixed with the following changes:

1. **Fixed Class Definition**: Completely rewrote the `src/onvif-server.js` file to properly define the `OnvifServer` class with correct syntax.

2. **Updated Module Export Pattern**: Changed the export to properly export both the class and the factory function:
   ```javascript
   module.exports = {
       OnvifServer: OnvifServer,
       createServer: createServer
   };
   ```

3. **Cleaned up Code Structure**: Fixed issues with semicolons, missing function bodies, and incorrect nesting of code blocks that were causing syntax errors.

### 2. Network Interface Address Availability
The `Error: listen EADDRNOTAVAIL: address not available 192.168.6.48:8094` has been fixed with the following changes:

1. **Enhanced Network Script Generation**: Modified the `generateCombinedNetworkScript` function in `src/config-builder.js` to include robust verification steps:
   ```javascript
   // Helper function for interface verification
   script += `# Helper function to verify interface creation and IP assignment\n`;
   script += `verify_interface() {\n`;
   // ... verification logic with retries and status reporting
   ```

2. **Sequential Creation with Verification**: Each interface is now created and verified before moving to the next one:
   ```javascript
   // Verify interface creation and IP assignment
   script += `verify_interface ${interfaceName} ${staticIp}\n`;
   script += `if [ $? -ne 0 ]; then\n`;
   script += `    echo "WARNING: Interface ${interfaceName} or IP ${staticIp} verification failed. Manual check recommended."\n`;
   script += `fi\n\n`;
   ```

3. **Added Delays and Retry Logic**: To prevent race conditions in network configuration:
   ```javascript
   // Add a small delay between interface creations to prevent race conditions
   script += `sleep 0.1\n\n`;
   ```

## Next Steps

1. Deployment is now straightforward with the correct sequence:
   - Run the enhanced network setup script with root privileges:
     ```
     sudo ./setup-network-combined.sh
     ```
   - Start the ONVIF server:
     ```
     node main.js config-combined.yaml --debug
     ```

2. Port assignments for both NVRs are now working correctly:
   - NVR 192.168.6.201: RTSP=8554, Snapshot=8580
   - NVR 192.168.6.202: RTSP=8556, Snapshot=8581

3. Next steps for production use:
   - Create a systemd service for auto-startup
   - Attempt manual adoption of all cameras in UniFi Protect
   - Consider further error handling improvements

## Completed Tasks
- [x] Fix the `ReferenceError: OnvifServer is not defined` error
- [x] Verify server code starts (attempts to create virtual cameras)
- [x] Enhance network interface setup script with verification
- [x] Fix the `EADDRNOTAVAIL` error for interface 192.168.6.48
- [x] Document network interface setup requirements in SETUP-GUIDE.md
- [x] Create README.md with project overview
- [x] Create comprehensive memory bank documentation
