Okay, this sounds like a solid plan. Separating the privileged network setup from the main application significantly improves security and simplifies the core application logic.

Here is a detailed plan for implementation, referencing the existing codebase where applicable and outlining necessary changes and new components.

## Project Plan: ONVIF Proxy GUI Application

**Progress Update:**

*   **Overall Architecture:** Defined and documented (see below).
*   **Technology Choices:**
    *   Database: SQLite (documented).
    *   Backend: Node.js with Fastify (documented, Fastify chosen for performance).
    *   GUI: Tauri (documented, Tauri chosen for resource efficiency).
*   **Database Schema:** Designed and implemented in `db_schema.sql` (see below).
*   **Backend API - Basic Structure:**  Initial setup with Fastify in `backend/index.js` (in progress, see `backend/index.js`). Password encryption using bcrypt is planned for NVR credentials.

## Project Plan: ONVIF Proxy GUI Application

**1. Overall Architecture**

The system will consist of four main components:

1.  **Privileged Setup Script:** A command-line script (e.g., Shell) responsible for creating persistent MACVLAN network interfaces and populating the database with their details. Requires \`sudo\` execution.
2.  **Database:** A central store (SQLite) for all configuration data, including NVR details, virtual camera settings, assigned ports, MAC addresses, interface status, and custom names. SQLite is chosen for its resource efficiency, suitable for environments with potentially many cameras. We can re-evaluate and consider PostgreSQL later if needed for very high concurrency.
3.  **Backend Application:** A Node.js server (using Fastify) providing a RESTful API. Fastify is chosen for its performance and low overhead, making it resource-efficient for handling potentially many cameras. It handles communication with the database, interacts with ONVIF devices (discovery, configuration fetching), manages the lifecycle of virtual ONVIF servers and TCP proxies, and serves requests from the GUI. Runs as a standard user.
4.  **GUI Application:** A desktop application (using Tauri) providing the user interface for managing NVRs and virtual cameras. Tauri is selected for its resource efficiency, utilizing the system's webview and resulting in a smaller footprint compared to options like Electron. Interacts exclusively with the Backend Application's API. Runs as a standard user.

\`\`\`mermaid
graph LR
    User --> GUIA(GUI Application);
    User -- Runs --> SetupScript(Privileged Setup Script);

    subgraph Unprivileged Environment
        GUIA -- API Calls --> Backend(Backend API - Node.js);
        Backend -- DB Access --> DB[(Database)];
    end

    subgraph Privileged Environment
        SetupScript -- Modifies System --> Network(Network Interfaces - MACVLAN);
        SetupScript -- DB Access --> DB;
    end

    Backend -- Interacts --> NVRs(Real ONVIF NVRs);
    Backend -- Manages --> VirtualServers(Virtual ONVIF Servers);
    Backend -- Manages --> TCPProxies(TCP Proxies);
    ClientSoftware(ONVIF Client Software e.g., UniFi Protect) -- Connects --> VirtualServers;
    ClientSoftware -- Connects --> TCPProxies;

    style SetupScript fill:#f9d,stroke:#333,stroke-width:2px;
    style Network fill:#ccf,stroke:#333,stroke-width:1px;
\`\`\`

**2. Database Schema (Example: SQLite)**

Implemented in `db_schema.sql`:

\`\`\`sql
CREATE TABLE virtual_interfaces (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    mac_address TEXT UNIQUE NOT NULL,
    interface_name TEXT UNIQUE NOT NULL,
    parent_interface TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'available',
    assigned_camera_id INTEGER NULL REFERENCES virtual_cameras(id),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE nvrs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    hostname TEXT NOT NULL,
    port INTEGER DEFAULT 80,
    username TEXT,
    password TEXT,
    last_scanned DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE virtual_cameras (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nvr_id INTEGER NOT NULL REFERENCES nvrs(id),
    assigned_interface_id INTEGER UNIQUE NOT NULL REFERENCES virtual_interfaces(id),
    custom_name TEXT NOT NULL,
    original_name TEXT,
    profile_token TEXT,
    video_source_token TEXT,
    uuid TEXT UNIQUE NOT NULL,
    server_port INTEGER UNIQUE NOT NULL,
    rtsp_proxy_port INTEGER UNIQUE NOT NULL,
    snapshot_proxy_port INTEGER UNIQUE NULL,
    discovery_enabled BOOLEAN NOT NULL DEFAULT true,
    hq_rtsp_path TEXT,
    hq_snapshot_path TEXT,
    hq_width INTEGER,
    hq_height INTEGER,
    hq_framerate INTEGER,
    hq_bitrate INTEGER,
    lq_rtsp_path TEXT,
    lq_snapshot_path TEXT,
    lq_width INTEGER,
    lq_height INTEGER,
    lq_framerate INTEGER,
    lq_bitrate INTEGER,
    target_nvr_rtsp_port INTEGER DEFAULT 554,
    target_nvr_snapshot_port INTEGER DEFAULT 80,
    status TEXT DEFAULT 'stopped',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
\`\`\`

**2. Database Schema (Example: SQLite)**

*   **\`virtual_interfaces\`**: Stores details about the MACVLAN interfaces created by the setup script.
    *   \`id\` (INTEGER PRIMARY KEY AUTOINCREMENT)
    *   \`mac_address\` (TEXT UNIQUE NOT NULL)
    *   \`interface_name\` (TEXT UNIQUE NOT NULL) - e.g., \`onvif-proxy-1\`
    *   \`parent_interface\` (TEXT NOT NULL) - e.g., \`eth0\`
    *   \`status\` (TEXT NOT NULL DEFAULT 'available') - 'available', 'in_use'
    *   \`assigned_camera_id\` (INTEGER NULL REFERENCES virtual_cameras(id))
    *   \`created_at\` (DATETIME DEFAULT CURRENT_TIMESTAMP)

*   **\`nvrs\`**: Stores connection details for the real NVR devices.
    *   \`id\` (INTEGER PRIMARY KEY AUTOINCREMENT)
    *   \`hostname\` (TEXT NOT NULL) - IP address or hostname
    *   \`port\` (INTEGER DEFAULT 80) - HTTP/ONVIF port
    *   \`username\` (TEXT)
    *   \`password\` (TEXT) - **Note:** Store securely (using bcrypt for efficient password encryption)!
    *   \`last_scanned\` (DATETIME NULL)
    *   \`created_at\` (DATETIME DEFAULT CURRENT_TIMESTAMP)

*   **\`virtual_cameras\`**: The core table holding configuration for each proxied camera channel.
    *   \`id\` (INTEGER PRIMARY KEY AUTOINCREMENT)
    *   \`nvr_id\` (INTEGER NOT NULL REFERENCES nvrs(id))
    *   \`assigned_interface_id\` (INTEGER UNIQUE NOT NULL REFERENCES virtual_interfaces(id))
    *   \`custom_name\` (TEXT NOT NULL) - User-defined name
    *   \`original_name\` (TEXT) - Name retrieved from NVR profile
    *   \`profile_token\` (TEXT) - ONVIF profile token from the NVR
    *   \`video_source_token\` (TEXT) - ONVIF video source token from the NVR
    *   \`uuid\` (TEXT UNIQUE NOT NULL) - Generated UUID for the virtual device
    *   \`server_port\` (INTEGER UNIQUE NOT NULL) - Port for the virtual ONVIF server
    *   \`rtsp_proxy_port\` (INTEGER UNIQUE NOT NULL) - Port for the RTSP TCP proxy
    *   \`snapshot_proxy_port\` (INTEGER UNIQUE NULL) - Port for the Snapshot TCP proxy (if applicable)
    *   \`discovery_enabled\` (BOOLEAN NOT NULL DEFAULT true)
    *   \`hq_rtsp_path\` (TEXT)
    *   \`hq_snapshot_path\` (TEXT)
    *   \`hq_width\` (INTEGER)
    *   \`hq_height\` (INTEGER)
    *   \`hq_framerate\` (INTEGER)
    *   \`hq_bitrate\` (INTEGER)
    *   \`lq_rtsp_path\` (TEXT)
    *   \`lq_snapshot_path\` (TEXT)
    *   \`lq_width\` (INTEGER)
    *   \`lq_height\` (INTEGER)
    *   \`lq_framerate\` (INTEGER)
    *   \`lq_bitrate\` (INTEGER)
    *   \`target_nvr_rtsp_port\` (INTEGER DEFAULT 554)
    *   \`target_nvr_snapshot_port\` (INTEGER DEFAULT 80)
    *   \`status\` (TEXT DEFAULT 'stopped') - 'stopped', 'running', 'error'
    *   \`created_at\` (DATETIME DEFAULT CURRENT_TIMESTAMP)
    *   \`updated_at\` (DATETIME DEFAULT CURRENT_TIMESTAMP)

**3. Privileged Setup Script (\`setup_interfaces.sh\`)**

*   **Purpose:** Create persistent MACVLAN interfaces and register them in the DB.
*   **Execution:** Must be run with \`sudo\`.
*   **Functionality:**
    1.  Check for necessary commands (\`ip\`, \`sqlite3\` or DB client).
    2.  Prompt user for:
        *   Parent interface name (e.g., \`eth0\`).
        *   Starting MAC address (locally administered).
        *   Number of interfaces to create OR ending MAC address.
        *   Database file path.
    3.  Generate unique interface names (e.g., \`onvif-proxy-X\`) and MAC addresses sequentially.
    4.  For each interface:
        *   Execute \`ip link add <interface_name> link <parent_interface> address <mac_address> type macvlan mode bridge\`.
        *   Execute \`ip link set <interface_name> up\`.
        *   **Persistence (Example using systemd-networkd):**
            *   Create \`/etc/systemd/network/90-<interface_name>.link\`:
                \`\`\`ini
                [Match]
                MACAddress=<mac_address>

                [Link]
                Name=<interface_name>
                \`\`\`
            *   Create \`/etc/systemd/network/90-<interface_name>.network\`:
                \`\`\`ini
                [Match]
                Name=<interface_name>

                [Network]
                DHCP=ipv4
                # Or configure static IP if needed, but DHCP reservation is preferred
                # Address=...
                # Gateway=...
                # DNS=...
                MACVLAN=
                \`\`\`
            *   Inform user to run \`sudo systemctl restart systemd-networkd\` or reboot. *Note: Directly restarting the service might disrupt existing connections.*
        *   Insert a record into the \`virtual_interfaces\` table in the database (\`mac_address\`, \`interface_name\`, \`parent_interface\`, \`status='available'\`).
    5.  Provide feedback to the user on success/failure.

**4. GUI Application (Frontend)**

*   **Technology:** Tauri (focus on resource efficiency and smaller footprint). Alternatives considered: Electron, NW.js.
*   **Views/Components:**
    *   NVR List View: Display discovered/added NVRs. Buttons: Add NVR, Scan Network.
    *   Add/Edit NVR Dialog: Fields for Hostname/IP, Port, Username, Password.
    *   NVR Detail View: Display NVR info. Button: Scan Channels. List of associated Virtual Cameras.
    *   Virtual Camera List (within NVR Detail or separate): Shows Name, Status (Running/Stopped/Error), Assigned IP (fetched from backend), Discovery (On/Off). Buttons/Actions: Start, Stop, Edit Name, Toggle Discovery, View Snapshot, Delete.
    *   Virtual Camera Detail/Edit View: Allows editing \`custom_name\`. Displays all configuration details. Shows assigned MAC/Interface. Allows assigning an available interface if not already assigned.
    *   Snapshot Viewer: Simple modal/dialog to display the snapshot image.
    *   Settings View: Database path, potentially other app settings.
*   **Logic:** All actions trigger API calls to the Backend. Handles displaying data received from the backend and managing UI state.

**5. Backend Application (Node.js)**

*   **Technology:** Node.js, Fastify, SQLite library (\`better-sqlite3\`), \`node-onvif\` (or similar for discovery), adapted code from \`onvif-proxy\`. Express.js is replaced with Fastify for improved performance.
*   **API Endpoints (Examples):**
    *   \`POST /api/discover/nvrs\`: Trigger WS-Discovery scan, return found devices.
    *   \`GET /api/nvrs\`, \`POST /api/nvrs\`, \`GET /api/nvrs/:id\`, \`PUT /api/nvrs/:id\`, \`DELETE /api/nvrs/:id\`: CRUD for NVRs.
    *   \`POST /api/nvrs/:id/scan\`: Trigger channel scan for an NVR using adapted \`config-builder\`. Create \`virtual_cameras\` entries in DB with status 'stopped'. Requires assigning available interfaces.
    *   \`GET /api/cameras\`, \`GET /api/cameras/:id\`: Get virtual camera details (including resolved IP address via \`os.networkInterfaces()\`).
    *   \`PATCH /api/cameras/:id\`: Update camera settings (e.g., \`custom_name\`, \`discovery_enabled\`).
    *   \`POST /api/cameras/:id/start\`: Start the ONVIF server & TCP proxies for this camera. Update status in DB.
    *   \`POST /api/cameras/:id/stop\`: Stop the server & proxies. Update status in DB.
    *   \`DELETE /api/cameras/:id\`: Stop processes and delete the camera config from DB (mark associated interface as 'available').
    *   \`GET /api/cameras/:id/snapshot\`: Fetch snapshot via the running TCP proxy and stream back to GUI.
    *   \`GET /api/interfaces/available\`: Get list of interfaces with status 'available'.
*   **Core Logic:**
    *   **Startup:** Read all \`virtual_cameras\` from DB. For those intended to be running (perhaps based on last state or a setting), start their \`OnvifServer\` and \`tcpProxy\` instances.
    *   **Runtime Management:** Maintain a map or object storing references to running \`OnvifServer\` and \`tcpProxy\` instances, keyed by \`virtual_camera.id\`. This allows starting/stopping/controlling individual cameras via API calls.
    *   **Port Management:** When creating a new \`virtual_camera\` record (after scanning NVR channels), query the DB for the highest used \`server_port\`, \`rtsp_proxy_port\`, \`snapshot_proxy_port\` and assign the next available ones. Ensure uniqueness constraints in the DB schema.
    *   **IP Address Resolution:** When requested (\`GET /api/cameras/:id\`), query the DB for the camera's assigned \`mac_address\`, then use \`os.networkInterfaces()\` to find the current IPv4 address associated with that MAC.
    *   **WS-Discovery (Client):** Implement sending UDP Probe messages and parsing ProbeMatches responses.
    *   **Graceful Shutdown:** On process exit (SIGINT, SIGTERM), iterate through running servers/proxies and stop them cleanly. Close DB connection.

**6. Code Refactoring and Adaptation**

*   **\`src/config-builder.js\` (\`createConfig\` function):**
    *   **Input:** Accept NVR \`hostname\`, \`port\`, \`username\`, \`password\` as arguments.
    *   **Output:** Return a structured JavaScript array of camera configuration objects (suitable for inserting into \`virtual_cameras\` DB table), *without* assigning ports or UUIDs here. Do not return the full \`config.onvif\` structure.
    *   **Remove:** Hardcoded port suggestions (\`serverPort\`, \`ports.rtsp: 8554\`, etc.). Remove YAML generation (\`yaml.stringify\`).
    *   **Remove:** The retry logic for \`time check failed\` might be better handled explicitly in the backend API call with user feedback.
    *   **Keep:** Logic for fetching profiles, URIs, resolutions, etc., using \`soap\`.
    *   **Adapt:** Ensure it correctly extracts \`target_nvr_rtsp_port\` (usually 554) and \`target_nvr_snapshot_port\` (usually NVR's HTTP port, potentially 80) from the discovered device/URIs if possible, or use defaults.

*   **\`src/onvif-server.js\` (\`OnvifServer\` class):**
    *   **Input:** Constructor should accept a single configuration object mirroring the structure fetched from the \`virtual_cameras\` DB table (including \`custom_name\`, assigned ports, UUID, stream paths, resolution, target ports, etc.).
    *   **Adapt:** \`GetSystemDateAndTime\`, \`GetCapabilities\`, \`GetServices\`: Should generally remain the same but use assigned ports/IP in XAddrs.
    *   **Adapt:** \`GetDeviceInformation\`: Use \`config.custom_name\` for Model/SerialNumber generation or potentially a dedicated field. Ensure Manufacturer is distinct (e.g., "ONVIF Proxy").
    *   **Adapt:** \`GetProfiles\`: Build profiles based on the \`hq_\` and \`lq_\` data passed in the config object.
    *   **Adapt:** \`GetSnapshotUri\`, \`GetStreamUri\`: Construct URIs using the assigned *proxy* ports (\`config.rtsp_proxy_port\`, \`config.snapshot_proxy_port\`) and the resolved IP address of the assigned interface.
    *   **Modify:** \`startDiscovery()\` should only bind the socket if \`config.discovery_enabled\` is true. Add \`enableDiscovery()\` and \`disableDiscovery()\` methods that bind/unbind the UDP socket (\`this.discoverySocket\`) respectively, allowing runtime control via API. Update the DB state accordingly.
    *   **Adapt:** \`startServer()\` should listen on the specific \`config.server_port\` and resolved IP address for the assigned MAC. The simple \`/snapshot.png\` fallback might be removed or adapted if proxying is always used.
    *   **Remove:** \`getIpAddressFromMac\` dependency within the class; the resolved IP should be determined by the backend *before* starting the server and passed in the config or determined during \`startServer\`.

*   **\`main.js\`:** This file will be largely replaced by the backend API server logic (e.g., using Express). The core concepts of creating \`OnvifServer\` instances and \`tcpProxy\` instances will move into the API handlers (\`POST /api/cameras/:id/start\`).

*   **Dependencies:** Remove \`yaml\`, \`argparse\`. Add database driver (\`better-sqlite3\`), web framework (\`express\`), potentially \`node-onvif\` or WS-Discovery library. Keep \`soap\`, \`node-tcp-proxy\`, \`node-uuid\`, \`xml2js\`, \`simple-node-logger\`.

**7. Error Handling and Logging**

*   Implement robust error handling in the backend for API requests, database operations, ONVIF interactions, and proxy/server management.
*   Use \`simple-node-logger\` (or chosen alternative) consistently across the backend for different log levels (info, warn, error, debug).
*   Provide meaningful error messages back to the GUI.

**8. Packaging and Deployment**

*   **Setup Script:** Distribute as a \`.sh\` file. Requires \`iproute2\` and \`sqlite3\` (or relevant DB client) on the target Linux system.
*   **Backend:** Can be run directly with Node.js. Consider packaging as a systemd service for auto-starting on boot. Docker containerization is also an option, but network setup (especially MACVLAN access) needs careful consideration.
*   **GUI:** Package using Electron Builder, Tauri, etc., for platform-specific installers/executables.

This detailed plan provides a roadmap for development. Key challenges include the secure handling of NVR credentials, robust management of server/proxy processes, and the implementation of the privileged setup script for network interface persistence.