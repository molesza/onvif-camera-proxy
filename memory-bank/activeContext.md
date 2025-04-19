# Active Context: ONVIF Proxy GUI Application

## Current Work Focus

The immediate focus is **debugging the virtual camera start process**. Specifically, resolving the failure to obtain an IPv4 address for the virtual network interface (`onvif-1`) assigned to the first virtual camera (ID 1). This is blocking the testing of the camera start/stop functionality. Once resolved, focus can shift back to GUI development or further backend testing/refinement.

## Recent Changes & Decisions

*   **Architecture Defined:** The multi-component architecture (GUI, Backend API, SQLite DB, Privileged Setup Script) has been finalized and documented (`gui-implementation.md`, `systemPatterns.md`).
*   **Technology Stack Chosen:** Tauri (GUI), Fastify (Backend), SQLite (DB), Shell (Setup Script) (`techContext.md`).
*   **Database Schema Implemented:** The schema defining tables for interfaces, NVRs, and virtual cameras is complete (`db_schema.sql`).
*   **Privileged Setup Script Implemented:** `setup/setup_interfaces.sh` is functional, creating persistent MACVLAN interfaces (using systemd-networkd) with static or DHCP IP configuration and registering them in the DB. Includes cleanup functionality.
*   **Core Backend API Implemented:** `backend/index.js` provides endpoints for:
    *   NVR CRUD (`/api/nvrs`).
    *   NVR Scanning (`/api/nvrs/:id/scan`) using adapted ONVIF logic (`backend/onvif-scanner.js`) with DB transaction for camera/interface assignment.
    *   Virtual Camera CRUD (`/api/cameras`).
    *   Virtual Camera Start/Stop (`/api/cameras/:id/start`, `/api/cameras/:id/stop`) managing runtime instances (`backend/virtual-camera-manager.js`).
    *   Listing available interfaces (`/api/interfaces/available`).
    *   Network Discovery (`/api/discover/nvrs`) using WS-Discovery (`backend/ws-discovery.js`).
    *   Snapshot Proxy (`/api/cameras/:id/snapshot`).
    *   Auto-start of cameras marked 'running' on backend launch.
*   **NVR Added & Scanned:** Successfully added a test NVR (ID 2, 192.168.6.201) via the API.
*   **Scan Debugging:** Encountered and fixed an SQLite binding error (`SQLite3 can only bind numbers strings bigints buffers and null`) in `backend/index.js` during the NVR scan process by ensuring correct data types (integer for `nvr_id`, integer 0/1 for boolean `discovery_enabled`) are passed to the database. Scan for NVR ID 2 is now successful, creating 32 virtual cameras.
*   **Camera Start Failure:** Attempting to start virtual camera ID 1 failed because the backend could not resolve an IPv4 address for its assigned MAC address (`a2:00:00:00:00:01` on interface `onvif-1`). System check (`ip addr show onvif-1`) confirmed the interface is UP but lacks an IPv4 address.
*   **Password Encryption Deferred:** Decided not to implement NVR password encryption for now.
*   **Project Plan:** A detailed implementation plan (`gui-implementation.md`) and progress tracker (`projectmap.md`) are established.

## Next Steps (Immediate Priorities)

1.  **Resolve IP Address Issue:**
    *   Restart the `systemd-networkd` service (`sudo systemctl restart systemd-networkd`) as suggested by the `setup_interfaces.sh` script's output, as this might trigger IP assignment.
    *   Verify if `onvif-1` obtains an IPv4 address after the restart.
2.  **Retry Camera Start:** Attempt to start virtual camera ID 1 again (`POST /api/cameras/1/start`).
3.  **Test Camera Functionality:** If start is successful, verify discovery (e.g., in UniFi Protect) and potentially snapshot/stream proxying.
4.  **GUI Development (Tauri):** Resume GUI development once backend camera start functionality is confirmed.
5.  **Backend Refinement (Lower Priority):** Improve general error handling, logging, and consider NVR verification during discovery.

## Open Decisions & Considerations

*   **Frontend Framework:** The specific JS framework (React, Vue, Svelte, Vanilla) for the GUI's webview part needs to be chosen.
*   **GUI State Management:** How will application state be managed within the Tauri frontend?
*   **Packaging/Deployment:** Define specific steps for packaging the backend service and the Tauri application.
