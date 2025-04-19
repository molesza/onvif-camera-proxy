# Progress: ONVIF Proxy GUI Application

## Current Status

The project has completed the implementation of the **privileged setup script** and the **core backend API**. The backend service is running and provides the necessary endpoints for managing the system. The next major phase is **GUI development**.

## What Works / Completed

*   **Architecture & Planning:**
    *   Detailed architecture (GUI, Backend, DB, Setup Script) defined (`gui-implementation.md`, `systemPatterns.md`).
    *   Technology stack selected (Tauri, Fastify, SQLite) (`techContext.md`).
    *   Implementation plan and task breakdown created (`gui-implementation.md`, `projectmap.md`).
*   **Database:**
    *   SQLite database schema designed and implemented (`db_schema.sql`).
*   **Privileged Setup Script (`setup/setup_interfaces.sh`):**
    *   Creates persistent MACVLAN interfaces using `ip link` and `systemd-networkd`.
    *   Supports static IP and DHCP configuration modes.
    *   Registers interfaces in the database.
    *   Includes cleanup functionality (`--cleanup`).
    *   Includes basic verification and delays during creation.
*   **Backend API (`backend/index.js`):**
    *   Fastify server setup with logging.
    *   NVR CRUD endpoints implemented (`/api/nvrs`).
    *   NVR scanning endpoint (`/api/nvrs/:id/scan`) implemented using adapted ONVIF logic (`backend/onvif-scanner.js`) and transactional DB updates for camera/interface assignment.
    *   Virtual Camera CRUD endpoints implemented (`/api/cameras`, `/api/cameras/:id`).
    *   Virtual Camera Start/Stop endpoints implemented (`/api/cameras/:id/start`, `/api/cameras/:id/stop`) using adapted server logic (`backend/virtual-camera-manager.js`) and runtime instance management.
    *   Auto-start functionality for cameras marked 'running' implemented.
    *   Available interfaces endpoint implemented (`/api/interfaces/available`).
    *   Network discovery endpoint implemented (`/api/discover/nvrs`) using WS-Discovery (`backend/ws-discovery.js`).
    *   Snapshot proxy endpoint implemented (`/api/cameras/:id/snapshot`) using `axios`.
*   **Code Refactoring:**
    *   Original ONVIF logic adapted into `backend/onvif-scanner.js` and `backend/virtual-camera-manager.js`.
*   **Backend Testing & Debugging:**
    *   Successfully added a test NVR (ID 2) via API.
    *   Successfully scanned NVR ID 2, creating 32 virtual cameras after fixing SQLite data type binding issues in `backend/index.js`.

## What's Left to Build / In Progress

*   **GUI Application (Tauri):** Needs full implementation. **(Not Started)**
    *   Set up Tauri project structure.
    *   Develop all views and components (NVR list/edit, Camera list/edit, etc.).
    *   Implement communication with the backend API.
    *   Choose frontend JS framework (React, Vue, Svelte, etc.) and state management approach.
*   **Backend Refinement:** **(Not Started)**
    *   Improve error handling and API response consistency.
    *   Enhance logging detail and structure.
    *   Consider adding NVR verification to discovery results.
*   **Code Cleanup:**
    *   Remove obsolete code/dependencies from `main.js` and root `package.json` (`argparse`, `yaml`, potentially `node-uuid`, `simple-node-logger` if backend logging is sufficient). **(Not Started)**
*   **Packaging & Deployment:** Define and implement packaging for all components (script, backend service, GUI installer). **(Not Started)**
*   **Testing:** Implement unit/integration tests for backend and potentially E2E tests for GUI. **(Not Started)**

## Known Issues / Blockers

*   **Virtual Camera Start Failure:** Attempting to start virtual camera ID 1 failed due to the backend being unable to resolve an IPv4 address for the assigned MAC address (`a2:00:00:00:00:01` / `onvif-1`). The interface exists but lacks an IPv4 address. **(Current Blocker)**
*   **Concurrency in Interface Assignment:** The `findAvailableInterfaceId` helper function in `backend/index.js` is noted as not being concurrency-safe if multiple scan requests happened simultaneously *before* the transaction logic was fully implemented in the scan route. The current transaction logic in the scan route mitigates this for scanning, but direct use of the helper elsewhere could be problematic.
*   **Setup Script Robustness:** MAC/IP increment logic is basic; error handling in setup script could be more comprehensive (e.g., rollback on failure). Requires restart of `systemd-networkd` after execution for changes to take effect.
*   **Snapshot Authentication:** Snapshot proxy does not currently handle NVR authentication if required.
