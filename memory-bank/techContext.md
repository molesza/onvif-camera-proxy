# Tech Context: ONVIF Proxy GUI Application

This document outlines the technologies used in the different components of the application.

## Core Technologies

*   **Language:** JavaScript (Node.js for backend and original core logic), Shell (for setup script), HTML/CSS/JS (for GUI frontend within Tauri).
*   **Runtime:** Node.js (v16+ recommended based on original README).
*   **Package Manager:** npm (implied by `package.json`).

## Components & Libraries

1.  **Privileged Setup Script (`setup_interfaces.sh`)**
    *   **Language:** Shell (Bash recommended for Linux compatibility).
    *   **OS Tools:** `ip` (from `iproute2` package) for MACVLAN creation/management, `systemd-networkd` utilities (e.g., `networkctl`, file creation in `/etc/systemd/network/`) for persistence (example implementation).
    *   **Database Client:** `sqlite3` command-line tool (or equivalent) for writing interface details to the database.

2.  **Database**
    *   **Type:** SQLite.
    *   **Schema:** Defined in `db_schema.sql`.
    *   **Access:** Via `better-sqlite3` library from the Node.js backend.

3.  **Backend Application (`backend/index.js` and adapted `src/`)**
    *   **Framework:** Fastify (chosen over Express for performance).
    *   **ONVIF Communication:** `soap` library (version `1.1.5` specified in `package.json`) for creating SOAP clients (config building) and servers (virtual device). Requires WSDL files (`wsdl/`).
    *   **XML Parsing:** `xml2js` (version `0.4.23`) used by `soap` and potentially for WS-Discovery parsing.
    *   **TCP Proxying:** `node-tcp-proxy` (version `0.0.28`) for forwarding RTSP and snapshot requests.
    *   **Database Driver:** `better-sqlite3` (present in `backend/package.json`).
    *   **UUID Generation:** `uuid` (present in `backend/package.json`) for creating unique IDs (v4) for virtual devices.
    *   **Logging:** `simple-node-logger` (present in `backend/package.json`).
    *   **HTTP Client:** `axios` (to be added to `backend/package.json`) for snapshot proxy requests.
    *   **Networking:** Node.js built-in `http`, `dgram`, `os`, `path`, `stream` modules.
    *   **(Potential):** `node-onvif` or similar dedicated WS-Discovery client library (alternative to manual implementation).

4.  **GUI Application (Frontend)**
    *   **Framework:** Tauri (chosen for resource efficiency).
        *   Uses system's native webview.
        *   Backend process written in Rust (managed by Tauri tooling, no direct Rust coding required for standard web tech usage).
    *   **Frontend Technologies:** Standard HTML, CSS, JavaScript (potentially using a UI framework like React, Vue, Svelte, or vanilla JS within the Tauri webview).
    *   **Communication:** Standard Web APIs (`fetch` or libraries like `axios`) to interact with the Backend REST API.

## Development Environment

*   **Node.js:** Required for running the backend and potentially building the GUI frontend assets.
*   **npm:** For managing Node.js dependencies.
*   **Rust Toolchain:** Required by Tauri for building the application shell.
*   **OS:** Linux environment assumed for the privileged setup script (MacVLAN, systemd-networkd). Backend and GUI could potentially run on other OSes, but setup script is Linux-specific.
*   **Code Editor:** VS Code (implied by user environment).

## Dependencies (from root `package.json`)

*   `soap`: 1.1.5
*   `xml2js`: 0.4.23
*   `node-tcp-proxy`: 0.0.28
*   `node-uuid`: 1.4.8 (Note: Backend uses the `uuid` package instead)
*   `argparse`: 2.0.1 (Likely removable now).
*   `yaml`: 2.5.1 (Likely removable now).
*   `simple-node-logger`: ^21.8.12 (Note: Also present in `backend/package.json`)

## Dependencies (Present in `backend/package.json`)
*   `fastify`
*   `better-sqlite3`
*   `soap`
*   `uuid`
*   `xml2js`
*   `node-tcp-proxy`
*   `simple-node-logger`
*   `express` (Present but unused, Fastify is used instead)

## Dependencies (To be added to `backend/package.json`)
*   `axios`
