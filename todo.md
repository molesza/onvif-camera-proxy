# ONVIF Server Troubleshooting Summary & TODO

This document summarizes the troubleshooting steps taken for the virtual ONVIF server and outlines the remaining issues.

## Completed Steps & Fixes

1.  **EADDRINUSE Crash:**
    *   **Problem:** Server crashed after 10-20 minutes due to `Error: bind EADDRINUSE 0.0.0.0`.
    *   **Cause:** Multiple virtual server instances were attempting to bind to the same UDP port (3702) for WS-Discovery.
    *   **Fix:**
        *   Modified `main.js` to ensure only the first server instance calls `startDiscovery()`.
        *   Added error handling to the UDP discovery socket in `src/onvif-server.js` to prevent unhandled errors.

2.  **Dynamic IP Configuration:**
    *   **Problem:** When using DHCP, the server config didn't reflect the actual IPs assigned to virtual interfaces, preventing cameras from being found.
    *   **Fix:**
        *   Created `generate-dynamic-config.js` script. This script reads the actual IPs assigned to `onv*` interfaces (using `ip addr show`) and updates a specified YAML config file (e.g., `config-combined.yaml`), writing the result with correct `hostname` fields to an output file (e.g., `config-dynamic-combined.yaml`).
        *   Modified `src/config-builder.js` (specifically `generateCombinedNetworkScript`) to generate network setup scripts (`setup-network-*.sh`) that request DHCP addresses sequentially for each interface, preventing router flooding and improving reliability.

3.  **Static IP Configuration:**
    *   **Clarification:** Confirmed that when using static IPs (`setup-network-*.sh --static`), the `generate-dynamic-config.js` script is *not* needed, provided the main config file (e.g., `config-combined.yaml`) has the correct static IPs manually entered in the `hostname` field for each camera.

## Current Issue: Manual Adoption Failure for Specific Cameras (Static IP)

*   **Problem:** Despite using static IPs and confirming interfaces/servers are running correctly, specific cameras cannot be manually adopted in UniFi Protect. The non-working IPs are those ending in: `.19`, `.22`, `.25`, `.27`, `.28`, `.33`. Other cameras (e.g., 192.168.6.3) adopt successfully.
*   **Troubleshooting Performed:**
    *   Confirmed all `onv*` interfaces are UP with correct static IPs via `ifconfig` / `ip addr show`.
    *   Confirmed interfaces are pingable.
    *   Confirmed Node.js server process is `LISTEN`ing on the correct static IP and ONVIF port for all cameras via `netstat`.
    *   Confirmed direct RTSP stream from the source DVR works for affected channels (e.g., Ch 26 for IP .28) via `ffprobe`.
    *   Confirmed basic HTTP connectivity to the virtual ONVIF server endpoint works for affected cameras (e.g., IP .28) via `curl`.
    *   Extracted and compared high-quality resolutions; confirmed that resolutions used by non-working cameras (960x1080, 1280x720) are also used by *working* cameras. Resolution incompatibility is unlikely the primary cause.
    *   Restarted interfaces and the ONVIF server with `--debug` logging enabled.

*   **Current Status:** Manual adoption of 192.168.6.28 still fails even after interface restart and with debug logging enabled on the server. The root cause seems specific to the UniFi adoption process for these cameras, despite the virtual servers appearing functional.

## Next Steps (TODO)

1.  **Analyze Debug Logs:**
    *   User needs to confirm they attempted manual adoption of 192.168.6.28 while the server was running with `--debug`.
    *   Examine the detailed ONVIF SOAP messages logged to the terminal/log file during the failed adoption attempt. Look for specific errors, malformed requests/responses, or differences compared to successful adoptions.
2.  **Investigate UniFi Side:**
    *   Check UniFi Protect logs for errors related to adopting these specific IPs.
    *   Try restarting the UniFi Protect application or the controller hardware.
    *   Verify UniFi network/firewall settings aren't blocking these specific IPs differently.
    *   Double-check credentials used during manual adoption.
3.  **Compare ONVIF Profiles:** If debug logs don't reveal errors, consider programmatically comparing the full ONVIF `GetProfiles` response between a working and non-working virtual camera instance to identify subtle differences UniFi might be sensitive to.