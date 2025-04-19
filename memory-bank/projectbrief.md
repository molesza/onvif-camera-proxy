# Project Brief: ONVIF Proxy GUI Application

## Core Goal

To evolve the original command-line ONVIF proxy tool into a full-fledged GUI application. This application will allow users to easily manage and create virtual ONVIF-compliant devices from real NVRs or RTSP streams, primarily to integrate multi-channel sources with systems like UniFi Protect. The new architecture separates concerns for better security, usability, and maintainability.

## Key Requirements

1.  **GUI Management:** Provide a desktop GUI (Tauri) for managing NVR connections, scanning channels, configuring virtual cameras, and controlling their status (start/stop/discovery).
2.  **Backend API:** Implement a Node.js/Fastify backend service providing a REST API for the GUI. This backend handles:
    *   Database interactions (SQLite).
    *   NVR discovery (WS-Discovery) and channel scanning (using adapted ONVIF logic).
    *   Lifecycle management of virtual ONVIF servers and TCP proxies based on database configuration.
    *   Secure storage of NVR credentials (using bcrypt).
    *   Serving API requests from the GUI.
3.  **Database Storage:** Utilize an SQLite database (`db_schema.sql` defined) to store all configuration, including:
    *   Virtual network interface details (MAC, name, status).
    *   NVR connection details.
    *   Virtual camera configurations (names, ports, stream details, UUIDs, status).
4.  **Privileged Network Setup:** Provide a separate, privileged script (`setup_interfaces.sh`) to:
    *   Create persistent MACVLAN network interfaces.
    *   Register these interfaces in the database for assignment to virtual cameras.
    *   Requires `sudo` execution, keeping the main backend/GUI unprivileged.
5.  **Core ONVIF Proxy Logic:** Adapt the existing ONVIF server (`src/onvif-server.js`) and configuration fetching (`src/config-builder.js`) logic to function within the backend service, driven by database configurations rather than a single YAML file.
6.  **Compatibility:** Maintain the core goal of enabling compatibility with ONVIF clients like UniFi Protect.
7.  **Deployment:** Package the GUI (Tauri), provide the backend (Node.js service/Docker), and distribute the setup script (`.sh`).

## Scope

*   **In Scope:** GUI for NVR/camera management, Backend API, SQLite database integration, Privileged setup script for MACVLAN, Refactoring existing ONVIF logic, WS-Discovery (client & server), TCP Proxying, Basic NVR credential encryption.
*   **Out of Scope (Currently):** Advanced ONVIF features beyond Profile S streaming (PTZ, Events, etc.), Cloud integration, Multi-user support, Advanced security features beyond basic credential handling.
