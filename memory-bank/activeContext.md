# Current Issues

## Port Conflict in Multi-NVR Setup
An error has been identified when adding multiple NVRs to the system:
```
Error: listen EADDRINUSE: address already in use :::8554
```

This occurs because each NVR is being assigned the same proxy ports (8554 for RTSP and 8580 for snapshot). When the second NVR is added, it attempts to use ports that are already in use by the first NVR.

### Required Fix
The proxy ports need to be incremented for each additional NVR:
- First NVR: RTSP=8554, Snapshot=8580
- Second NVR: RTSP=8556, Snapshot=8581
- Third NVR: RTSP=8558, Snapshot=8582
And so on...

This change needs to be implemented in the port assignment logic in config-builder.js.
