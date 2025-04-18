# Recent Fixes

## Port Conflict in Multi-NVR Setup - FIXED
The issue with port conflicts when using multiple NVRs has been resolved. Previously, each NVR was being assigned the same proxy ports (8554 for RTSP and 8580 for snapshot), causing the following error:
```
Error: listen EADDRINUSE: address already in use :::8554
```

### Implemented Solution
The fix was implemented in main.js by adding dynamic port assignment logic that increments the proxy ports for each additional NVR:
- First NVR: RTSP=8554, Snapshot=8580
- Second NVR: RTSP=8556, Snapshot=8581
- Third NVR: RTSP=8558, Snapshot=8582

The solution works by:
1. Tracking which NVRs have been seen during server startup
2. Assigning unique base ports to each new NVR
3. Updating the configuration in memory with the assigned ports
4. Using these updated ports when setting up the TCP proxies

This approach allows the server to handle multiple NVRs without port conflicts, while maintaining the original configuration files.

# Current Status
All identified issues have been fixed. The server is now able to:
1. Start successfully with all interfaces
2. Properly assign ports to different NVRs
3. Create all virtual interfaces with correct IPs
4. Set up TCP proxies without port conflicts

The system is ready for testing with UniFi Protect.
