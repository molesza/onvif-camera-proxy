# Product Context: ONVIF Proxy GUI Application

## Problem Statement

Many users utilize Network Video Recorders (NVRs) or cameras that output multiple video streams (channels) through a single device interface. However, some popular video management systems, notably UniFi Protect (specifically older versions mentioned in the original README), have limitations in handling these multi-channel devices. They often only recognize or properly support devices presenting a single high-quality and low-quality stream via ONVIF. This prevents users from integrating all their camera channels from multi-channel NVRs or multi-lens cameras into such systems.

Furthermore, managing the original command-line tool requires manual configuration file editing (YAML), command-line execution, and manual setup of virtual network interfaces (MacVLAN) for each channel to ensure unique MAC addresses, which is complex and error-prone for less technical users.

## Solution

This application provides a user-friendly graphical interface (GUI) built with Tauri, backed by a Node.js/Fastify API and an SQLite database, to solve these problems.

1.  **Bridging Compatibility:** It acts as a proxy, taking channels from a real NVR (or individual RTSP streams) and presenting each one as a separate, standard, single-channel virtual ONVIF device. This makes them compatible with systems like UniFi Protect.
2.  **Simplified Management:** It replaces manual configuration files and command-line operations with a GUI for:
    *   Adding and managing connections to real NVRs.
    *   Scanning NVRs to discover available camera channels.
    *   Assigning discovered channels to pre-configured virtual network interfaces (created by a separate setup script).
    *   Naming virtual cameras.
    *   Starting and stopping the virtual camera proxies individually.
    *   Toggling network discovery (WS-Discovery) for each virtual camera.
3.  **Improved Network Setup:** While still requiring MacVLAN interfaces for unique MAC addresses (essential for UniFi Protect), it isolates the privileged network setup into a dedicated script. This script handles the creation and persistence of these interfaces and registers them in the database, separating complex, privileged operations from the main user application.

## User Experience Goals

*   **Ease of Use:** Provide an intuitive GUI that simplifies the process of adding NVRs, discovering channels, and creating/managing virtual cameras. Minimize the need for command-line interaction or manual file editing for core operations.
*   **Clear Status:** Clearly display the status of NVR connections, virtual cameras (running, stopped, error), and assigned network interfaces/IP addresses.
*   **Simplified Configuration:** Automate the configuration process as much as possible (e.g., scanning channels, assigning ports). Allow easy customization where needed (e.g., custom names).
*   **Security:** Separate privileged operations (network setup) from the main application. Securely handle NVR credentials within the backend.
*   **Resource Efficiency:** Utilize Tauri and Fastify to minimize the application's resource footprint, making it suitable for running on lower-powered devices (like Raspberry Pi, as mentioned in the original README) alongside other services.
