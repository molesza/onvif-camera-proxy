const fastify = require('fastify')({ logger: true });
const Database = require('better-sqlite3');
const { scanOnvifDevice } = require('./onvif-scanner');
const { VirtualCamera, getIpAddressFromMac } = require('./virtual-camera-manager'); // Import camera manager
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const tcpProxy = require('node-tcp-proxy');
const axios = require('axios'); // For snapshot proxy request
const stream = require('stream'); // For streaming snapshot response
const fs = require('fs'); // Needed for placeholder snapshot

// Runtime state for running cameras
const runningCameras = new Map(); // Map<cameraId, VirtualCameraInstance>

// Database setup - use absolute path for reliability
const dbPath = path.join(__dirname, '../db/onvif-proxy.db');
const db = new Database(dbPath);
fastify.log.info(`Database connected at ${dbPath}`);

// Health check endpoint
fastify.get('/api/health', async (request, reply) => {
    return { status: 'ok' };
});

// --- NVR Endpoints ---

// GET /api/nvrs - List all NVRs
fastify.get('/api/nvrs', async (request, reply) => {
    try {
        const nvrs = db.prepare('SELECT * FROM nvrs').all();
        reply.send(nvrs);
    } catch (error) {
        fastify.log.error('Error fetching NVRs:', error);
        reply.status(500).send({ error: 'Failed to fetch NVRs' });
    }
});

// POST /api/nvrs - Create a new NVR
fastify.post('/api/nvrs', async (request, reply) => {
    const { hostname, port, username, password } = request.body;
    if (!hostname) {
        return reply.status(400).send({ error: 'Hostname is required' });
    }
    try {
        const stmt = db.prepare('INSERT INTO nvrs (hostname, port, username, password) VALUES (?, ?, ?, ?)');
        const result = stmt.run(hostname, port, username, password);
        reply.status(201).send({ id: result.lastInsertRowid, message: 'NVR created successfully' });
    } catch (error) {
        fastify.log.error('Error creating NVR:', error);
        reply.status(500).send({ error: 'Failed to create NVR' });
    }
});

// GET /api/nvrs/:id - Get NVR by ID
fastify.get('/api/nvrs/:id', async (request, reply) => {
    const { id } = request.params;
    try {
        const nvr = db.prepare('SELECT * FROM nvrs WHERE id = ?').get(id);
        if (nvr) {
            reply.send(nvr);
        } else {
            reply.status(404).send({ error: 'NVR not found' });
        }
    } catch (error) {
        fastify.log.error('Error fetching NVR:', error);
        reply.status(500).send({ error: 'Failed to fetch NVR' });
    }
});

// PUT /api/nvrs/:id - Update NVR by ID
fastify.put('/api/nvrs/:id', async (request, reply) => {
    const { id } = request.params;
    const { hostname, port, username, password } = request.body;
    try {
        const stmt = db.prepare('UPDATE nvrs SET hostname = ?, port = ?, username = ?, password = ? WHERE id = ?');
        const result = stmt.run(hostname, port, username, password, id);
        if (result.changes > 0) {
            reply.send({ message: 'NVR updated successfully' });
        } else {
            reply.status(404).send({ error: 'NVR not found' });
        }
    } catch (error) {
        fastify.log.error('Error updating NVR: %o', error);
        reply.status(500).send({ error: 'Failed to update NVR', details: error.message });
    }
});

// DELETE /api/nvrs/:id - Delete NVR by ID
fastify.delete('/api/nvrs/:id', async (request, reply) => {
    const { id } = request.params;
    try {
        const stmt = db.prepare('DELETE FROM nvrs WHERE id = ?');
        const result = stmt.run(id);
        if (result.changes > 0) {
            reply.send({ message: 'NVR deleted successfully' });
        } else {
            reply.status(404).send({ error: 'NVR not found' });
        }
    } catch (error) {
        fastify.log.error('Error deleting NVR:', error);
        reply.status(500).send({ error: 'Failed to delete NVR' });
    }
});

// Helper function to find the next available starting port
function findNextAvailablePorts(startPort = 9000) {
    const stmt = db.prepare(`
        SELECT MAX(p) as max_port FROM (
            SELECT server_port as p FROM virtual_cameras WHERE server_port IS NOT NULL
            UNION
            SELECT rtsp_proxy_port as p FROM virtual_cameras WHERE rtsp_proxy_port IS NOT NULL
            UNION
            SELECT snapshot_proxy_port as p FROM virtual_cameras WHERE snapshot_proxy_port IS NOT NULL
        )
    `);
    const result = stmt.get();
    const maxUsedPort = result?.max_port || (startPort - 1); // Handle case where table is empty
    // Return the next 3 ports needed
    return {
        server_port: maxUsedPort + 1,
        rtsp_proxy_port: maxUsedPort + 2,
        snapshot_proxy_port: maxUsedPort + 3
    };
}

// Helper function to find and assign an available interface
// NOTE: This simple version doesn't handle concurrency well.
// A transaction is needed in the main route logic.
function findAvailableInterfaceId() {
     const availableInterface = db.prepare(`
            SELECT id FROM virtual_interfaces
            WHERE status = 'available'
            ORDER BY id ASC
            LIMIT 1
        `).get();
    return availableInterface ? availableInterface.id : null;
}


// POST /api/nvrs/:id/scan - Scan NVR for channels
fastify.post('/api/nvrs/:id/scan', async (request, reply) => {
    // --- FIX 1: Parse nvrId to integer ---
    const nvrId = parseInt(request.params.id, 10);
    if (isNaN(nvrId)) {
        return reply.status(400).send({ error: 'Invalid NVR ID format.' });
    }
    // --- End FIX 1 ---

    try {
        const nvr = db.prepare('SELECT hostname, port, username, password FROM nvrs WHERE id = ?').get(nvrId);
        if (!nvr) {
            return reply.status(404).send({ error: 'NVR not found' });
        }

        fastify.log.info(`Scanning NVR ${nvrId} (${nvr.hostname})...`);
        // Use the imported scanner function
        const cameraConfigs = await scanOnvifDevice(nvr.hostname, nvr.port, nvr.username, nvr.password);
        fastify.log.info(`Scan found ${cameraConfigs.length} potential camera configurations.`);

        if (cameraConfigs.length === 0) {
            // Update last_scanned even if no cameras found
             db.prepare('UPDATE nvrs SET last_scanned = CURRENT_TIMESTAMP WHERE id = ?').run(nvrId);
            return reply.send({ message: 'NVR scan complete. No new camera configurations found.' });
        }

        // Prepare statements outside the transaction
        const insertCameraStmt = db.prepare(`
            INSERT INTO virtual_cameras (
                nvr_id, assigned_interface_id, custom_name, original_name, profile_token, video_source_token,
                uuid, server_port, rtsp_proxy_port, snapshot_proxy_port, discovery_enabled,
                hq_rtsp_path, hq_snapshot_path, hq_width, hq_height, hq_framerate, hq_bitrate,
                lq_rtsp_path, lq_snapshot_path, lq_width, lq_height, lq_framerate, lq_bitrate,
                target_nvr_rtsp_port, target_nvr_snapshot_port, status
            ) VALUES (
                ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'stopped'
            ) RETURNING id
        `); // Added RETURNING id

        const updateInterfaceStmt = db.prepare(`
            UPDATE virtual_interfaces
            SET status = 'in_use', assigned_camera_id = ?
            WHERE id = ? AND status = 'available'
        `);

        const findAvailableInterfaceStmt = db.prepare(`
            SELECT id FROM virtual_interfaces
            WHERE status = 'available'
            ORDER BY id ASC
            LIMIT 1
        `);

        // Define the transaction
        const transaction = db.transaction((configs) => {
            const createdCameras = [];
            let nextPorts = findNextAvailablePorts(); // Find starting ports once

            for (const config of configs) {
                 fastify.log.info(`Processing config for: ${config.original_name || 'Unknown Name'}`);

                 // 1. Find an available interface within the transaction
                 const availableInterface = findAvailableInterfaceStmt.get();
                 if (!availableInterface) {
                     throw new Error('No available virtual interfaces found to assign.'); // Rolls back transaction
                 }
                 fastify.log.info(`Found available interface ID: ${availableInterface.id}`);

                 // 2. Insert the virtual camera record
                 const newUuid = uuidv4();
                 const snapshotPort = config.hq_snapshot_path ? nextPorts.snapshot_proxy_port : null;

                 // Helper function to ensure null for undefined/empty values
                 const nullIfUndefined = (val) => (val === undefined || val === '') ? null : val;
                 const numNullIfUndefined = (val) => (val === undefined || val === '' || isNaN(parseInt(val))) ? null : parseInt(val); // Ensure numeric or null

                 // Prepare parameters with sanitization
                 const paramsToInsert = [
                     nvrId, // Already parsed to integer above
                     availableInterface.id,
                     nullIfUndefined(config.original_name) || 'Unnamed Camera', // Default custom_name
                     nullIfUndefined(config.original_name),
                     nullIfUndefined(config.profile_token),
                     nullIfUndefined(config.video_source_token),
                     newUuid,
                     nextPorts.server_port,
                     nextPorts.rtsp_proxy_port,
                     snapshotPort, // Already handles null based on hq_snapshot_path
                     // --- FIX 2: Convert boolean to integer ---
                     true ? 1 : 0, // discovery_enabled default (always true here, so 1)
                     // --- End FIX 2 ---
                     nullIfUndefined(config.hq_rtsp_path),
                     nullIfUndefined(config.hq_snapshot_path),
                     numNullIfUndefined(config.hq_width),
                     numNullIfUndefined(config.hq_height),
                     numNullIfUndefined(config.hq_framerate),
                     numNullIfUndefined(config.hq_bitrate),
                     nullIfUndefined(config.lq_rtsp_path),
                     nullIfUndefined(config.lq_snapshot_path),
                     numNullIfUndefined(config.lq_width),
                     numNullIfUndefined(config.lq_height),
                     numNullIfUndefined(config.lq_framerate),
                     numNullIfUndefined(config.lq_bitrate),
                     numNullIfUndefined(config.target_nvr_rtsp_port),
                     numNullIfUndefined(config.target_nvr_snapshot_port)
                 ];

                 // Log the parameters right before insertion for debugging
                 fastify.log.info({ msg: 'Attempting to insert camera with params:', params: paramsToInsert });

                 const insertResult = insertCameraStmt.get(...paramsToInsert); // Use spread syntax

                 const newCameraId = insertResult.id;
                 fastify.log.info(`Inserted virtual camera with ID: ${newCameraId}, UUID: ${newUuid}`);

                 // 3. Update the interface status (still within transaction)
                 const updateResult = updateInterfaceStmt.run(newCameraId, availableInterface.id);
                 if (updateResult.changes === 0) {
                     // This check ensures the interface wasn't assigned between the SELECT and UPDATE
                     throw new Error(`Failed to assign interface ${availableInterface.id}; it might have been taken concurrently.`);
                 }
                 fastify.log.info(`Assigned interface ID ${availableInterface.id} to camera ID ${newCameraId}`);

                 createdCameras.push({ id: newCameraId, name: config.original_name, interface_id: availableInterface.id });

                 // Increment ports for the next camera
                 const portIncrement = snapshotPort ? 3 : 2;
                 nextPorts = {
                     server_port: nextPorts.server_port + portIncrement,
                     rtsp_proxy_port: nextPorts.rtsp_proxy_port + portIncrement,
                     snapshot_proxy_port: nextPorts.snapshot_proxy_port + portIncrement
                 };
            }
            // Update NVR last_scanned timestamp (only if transaction succeeds)
            db.prepare('UPDATE nvrs SET last_scanned = CURRENT_TIMESTAMP WHERE id = ?').run(nvrId);
            return createdCameras;
        });

        // Execute the transaction
        const createdItems = transaction(cameraConfigs);

        reply.send({ message: `NVR scan complete. ${createdItems.length} virtual cameras created/updated.`, created: createdItems });
    } catch (error) {
        fastify.log.error('Error scanning NVR:', error);
        reply.status(500).send({ error: 'Failed to scan NVR', details: error.message });
    }
});

// --- Virtual Camera Endpoints ---

// GET /api/cameras - List all virtual cameras
fastify.get('/api/cameras', async (request, reply) => {
    try {
        const cameras = db.prepare('SELECT * FROM virtual_cameras').all();
        reply.send(cameras);
    } catch (error) {
        fastify.log.error('Error fetching virtual cameras:', error);
        reply.status(500).send({ error: 'Failed to fetch virtual cameras' });
    }
});

// GET /api/cameras/:id - Get a specific virtual camera
fastify.get('/api/cameras/:id', async (request, reply) => {
    const { id } = request.params;
    try {
        // Join with virtual_interfaces to include MAC address and interface name
        const camera = db.prepare(`
            SELECT vc.*, vi.mac_address, vi.interface_name
            FROM virtual_cameras vc
            LEFT JOIN virtual_interfaces vi ON vc.assigned_interface_id = vi.id
            WHERE vc.id = ?
        `).get(id);

        if (camera) {
            reply.send(camera);
        } else {
            reply.status(404).send({ error: 'Virtual camera not found' });
        }
    } catch (error) {
        fastify.log.error('Error fetching virtual camera:', error);
        reply.status(500).send({ error: 'Failed to fetch virtual camera' });
    }
});

// PATCH /api/cameras/:id - Update a virtual camera (e.g., name, discovery)
fastify.patch('/api/cameras/:id', async (request, reply) => {
    const { id } = request.params;
    const { custom_name, discovery_enabled } = request.body;

    // Basic validation: ensure at least one field is being updated
    if (custom_name === undefined && discovery_enabled === undefined) {
        return reply.status(400).send({ error: 'No update fields provided (custom_name or discovery_enabled)' });
    }

    // Build the SET part of the query dynamically
    let setClauses = [];
    let params = [];
    if (custom_name !== undefined) {
        setClauses.push('custom_name = ?');
        params.push(custom_name);
    }
    if (discovery_enabled !== undefined) {
        // Ensure boolean conversion
        setClauses.push('discovery_enabled = ?');
        params.push(discovery_enabled ? 1 : 0);
    }
    setClauses.push('updated_at = CURRENT_TIMESTAMP'); // Always update timestamp

    params.push(id); // Add the ID for the WHERE clause

    const sql = `UPDATE virtual_cameras SET ${setClauses.join(', ')} WHERE id = ?`;

    try {
        const stmt = db.prepare(sql);
        const result = stmt.run(...params); // Spread parameters

        if (result.changes > 0) {
            // Fetch the updated camera to return it
             const updatedCamera = db.prepare(`
                SELECT vc.*, vi.mac_address, vi.interface_name
                FROM virtual_cameras vc
                LEFT JOIN virtual_interfaces vi ON vc.assigned_interface_id = vi.id
                WHERE vc.id = ?
            `).get(id);
            reply.send(updatedCamera);
        } else {
            reply.status(404).send({ error: 'Virtual camera not found' });
        }
    } catch (error) {
        fastify.log.error('Error updating virtual camera:', error);
        reply.status(500).send({ error: 'Failed to update virtual camera' });
    }
});


// DELETE /api/cameras/:id - Delete a virtual camera
fastify.delete('/api/cameras/:id', async (request, reply) => {
    const { id } = request.params;

    // Use a transaction to delete camera and update interface status
    const deleteTx = db.transaction((cameraId) => {
        // 1. Get the assigned interface ID before deleting the camera
        const cameraData = db.prepare('SELECT assigned_interface_id, status FROM virtual_cameras WHERE id = ?').get(cameraId);
        if (!cameraData) {
            return { changes: 0, error: 'Virtual camera not found' }; // Indicate not found for transaction result
        }

        // Check if camera is running - prevent deletion if so? (For now, allow deletion)
        // if (cameraData.status === 'running') {
        //     throw new Error('Cannot delete a running virtual camera. Stop it first.');
        // }

        const assignedInterfaceId = cameraData.assigned_interface_id;

        // 2. Delete the camera
        const deleteCamResult = db.prepare('DELETE FROM virtual_cameras WHERE id = ?').run(cameraId);
        if (deleteCamResult.changes === 0) {
             // Should not happen if the SELECT worked, but check anyway
             throw new Error('Failed to delete virtual camera record.');
        }

        // 3. Update the corresponding interface status back to 'available'
        if (assignedInterfaceId) {
            const updateInterfaceResult = db.prepare(`
                UPDATE virtual_interfaces
                SET status = 'available', assigned_camera_id = NULL
                WHERE id = ?
            `).run(assignedInterfaceId);
             if (updateInterfaceResult.changes === 0) {
                 // Log a warning, but don't fail the transaction - the camera is already deleted.
                 fastify.log.warn(`Could not update status for interface ID ${assignedInterfaceId} after deleting camera ${cameraId}. Manual check needed.`);
             } else {
                 fastify.log.info(`Interface ID ${assignedInterfaceId} marked as available after deleting camera ${cameraId}.`);
             }
        } else {
             fastify.log.warn(`Camera ID ${cameraId} did not have an assigned_interface_id.`);
        }

        return { changes: deleteCamResult.changes }; // Indicate success
    });

    try {
        const result = deleteTx(id); // Execute transaction

        if (result.changes > 0) {
            reply.send({ message: 'Virtual camera deleted successfully' });
        } else {
            reply.status(404).send({ error: result.error || 'Virtual camera not found' });
        }
    } catch (error) {
        fastify.log.error('Error deleting virtual camera:', error);
        // If the transaction threw an error (e.g., interface assignment failed)
        reply.status(500).send({ error: 'Failed to delete virtual camera', details: error.message });
    }
});

// POST /api/cameras/:id/start - Start a virtual camera
fastify.post('/api/cameras/:id/start', async (request, reply) => {
    const { id } = request.params;
    const cameraId = parseInt(id, 10); // Ensure ID is integer

    if (runningCameras.has(cameraId)) {
        return reply.status(409).send({ error: 'Camera is already running.' });
    }

    try {
        // Fetch camera config JOINED with NVR details and Interface details
        const cameraConfig = db.prepare(`
            SELECT
                vc.*,
                vi.mac_address,
                vi.interface_name,
                n.hostname as target_nvr_hostname -- Alias NVR hostname
            FROM virtual_cameras vc
            JOIN virtual_interfaces vi ON vc.assigned_interface_id = vi.id
            JOIN nvrs n ON vc.nvr_id = n.id
            WHERE vc.id = ?
        `).get(cameraId);

        if (!cameraConfig) {
            return reply.status(404).send({ error: 'Virtual camera not found' });
        }

        if (!cameraConfig.mac_address) {
             return reply.status(400).send({ error: 'Virtual camera is not assigned to a network interface (MAC address missing).' });
        }
         if (!cameraConfig.target_nvr_hostname) {
             return reply.status(400).send({ error: 'Target NVR hostname is missing for this camera.' });
        }

        // Create and start the camera instance
        const cameraInstance = new VirtualCamera(cameraConfig, fastify.log);
        await cameraInstance.start(); // This will throw if IP resolution fails

        // Store the running instance
        runningCameras.set(cameraId, cameraInstance);

        // Update DB status
        db.prepare(`UPDATE virtual_cameras SET status = 'running', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).run(cameraId);

        reply.send({ message: `Virtual camera ${cameraId} started successfully.` });

    } catch (error) {
        fastify.log.error(`Error starting camera ${cameraId}:`, error);
        // Ensure instance is cleaned up if start failed partially
        if (runningCameras.has(cameraId)) {
            await runningCameras.get(cameraId).stop().catch(stopErr => fastify.log.error(`Error stopping camera ${cameraId} after failed start:`, stopErr));
            runningCameras.delete(cameraId);
        }
        // Update DB status to error
        db.prepare(`UPDATE virtual_cameras SET status = 'error', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).run(cameraId);
        reply.status(500).send({ error: 'Failed to start virtual camera', details: error.message });
    }
});

// POST /api/cameras/:id/stop - Stop a virtual camera
fastify.post('/api/cameras/:id/stop', async (request, reply) => {
    const { id } = request.params;
     const cameraId = parseInt(id, 10);

    if (!runningCameras.has(cameraId)) {
        // Check DB status - maybe it should be running but isn't?
        const dbStatus = db.prepare('SELECT status FROM virtual_cameras WHERE id = ?').get(cameraId);
        if (dbStatus && dbStatus.status === 'running') {
             fastify.log.warn(`Camera ${cameraId} has status 'running' in DB but no active instance found. Updating DB status to 'stopped'.`);
             db.prepare(`UPDATE virtual_cameras SET status = 'stopped', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).run(cameraId);
             return reply.send({ message: 'Camera was marked as running but instance not found. Status updated to stopped.' });
        }
        return reply.status(404).send({ error: 'Camera not found or not running.' });
    }

    try {
        const cameraInstance = runningCameras.get(cameraId);
        await cameraInstance.stop();

        // Remove from running map
        runningCameras.delete(cameraId);

        // Update DB status
        db.prepare(`UPDATE virtual_cameras SET status = 'stopped', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).run(cameraId);

        reply.send({ message: `Virtual camera ${cameraId} stopped successfully.` });

    } catch (error) {
        fastify.log.error(`Error stopping camera ${cameraId}:`, error);
        // Attempt to update DB status even on error? Or leave as 'running'? Let's set to error.
         db.prepare(`UPDATE virtual_cameras SET status = 'error', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).run(cameraId);
        reply.status(500).send({ error: 'Failed to stop virtual camera', details: error.message });
    }
});

// --- Discovery Endpoint ---
const { discoverOnvifDevices } = require('./ws-discovery'); // Ensure this is imported

fastify.post('/api/discover/nvrs', async (request, reply) => {
    try {
        fastify.log.info('Starting ONVIF WS-Discovery scan...');
        const devices = await discoverOnvifDevices(fastify.log);
        fastify.log.info(`WS-Discovery scan finished, found ${devices.length} potential devices.`);
        // TODO: Optionally try to connect to each device's GetDeviceInformation to verify?
        // TODO: Optionally filter out devices already added?
        reply.send(devices);
    } catch (error) {
        fastify.log.error('Error during NVR discovery:', error);
        reply.status(500).send({ error: 'Failed to perform network discovery', details: error.message });
    }
});


// --- Interface Endpoints ---

// GET /api/interfaces/available - List available virtual interfaces
fastify.get('/api/interfaces/available', async (request, reply) => {
    try {
        const interfaces = db.prepare(`
            SELECT id, mac_address, interface_name
            FROM virtual_interfaces
            WHERE status = 'available'
            ORDER BY id ASC
        `).all();
        reply.send(interfaces);
    } catch (error) {
        fastify.log.error('Error fetching available interfaces:', error);
        reply.status(500).send({ error: 'Failed to fetch available interfaces' });
    }
});

// GET /api/cameras/:id/snapshot - Proxy snapshot request
fastify.get('/api/cameras/:id/snapshot', async (request, reply) => {
    const { id } = request.params;
    const cameraId = parseInt(id, 10);

    if (!runningCameras.has(cameraId)) {
        return reply.status(404).send({ error: 'Camera not found or not running.' });
    }

    const cameraInstance = runningCameras.get(cameraId);
    const config = cameraInstance.config; // Get config from the instance

    // Check if snapshot proxy is configured and expected to be running
    if (!config.snapshot_proxy_port || !config.target_nvr_hostname || !config.target_nvr_snapshot_port || !config.hq_snapshot_path) {
        fastify.log.warn(`[${cameraId}] Snapshot requested, but snapshot proxy/path not configured.`);
        // Option 1: Return placeholder
        try {
            const placeholderPath = path.join(__dirname, '../resources/snapshot.png');
            const placeholderStream = fs.createReadStream(placeholderPath);
            return reply.type('image/png').send(placeholderStream);
        } catch (err) {
            fastify.log.error(`[${cameraId}] Error reading placeholder snapshot: ${err}`);
            return reply.status(500).send({ error: 'Snapshot not configured and placeholder unavailable.' });
        }
        // Option 2: Return error
        // return reply.status(404).send({ error: 'Snapshot functionality not configured for this camera.' });
    }

    // Construct the target URL using the NVR's actual hostname/port and path
    const targetUrl = `http://${config.target_nvr_hostname}:${config.target_nvr_snapshot_port}${config.hq_snapshot_path}`;
    fastify.log.info(`[${cameraId}] Proxying snapshot request to: ${targetUrl}`);

    try {
        // Make request to the target NVR via HTTP GET
        const response = await axios({
            method: 'get',
            url: targetUrl,
            responseType: 'stream', // Get the response as a stream
            timeout: 5000 // Add a timeout
            // TODO: Add NVR authentication if needed (might require storing credentials securely)
        });

        // Stream the response back to the client
        reply.type(response.headers['content-type'] || 'image/jpeg'); // Set content type from target response
        // Use pipeline for efficient streaming and error handling
        stream.pipeline(response.data, reply.raw, (err) => {
             if (err) {
                 fastify.log.error(`[${cameraId}] Error piping snapshot stream: ${err.message}`);
                 // Avoid sending another reply if headers already sent
                 if (!reply.raw.headersSent) {
                    reply.status(500).send({ error: 'Failed to stream snapshot' });
                 } else {
                     reply.raw.end(); // End the response if possible
                 }
             } else {
                  fastify.log.debug(`[${cameraId}] Snapshot stream finished successfully.`);
             }
        });
        // Indicate that the reply will be sent asynchronously by the stream pipeline
         await reply;


    } catch (error) {
        fastify.log.error(`[${cameraId}] Error proxying snapshot request to ${targetUrl}: ${error.message}`);
        if (error.response) {
            // The request was made and the server responded with a status code
            // that falls out of the range of 2xx
             reply.status(error.response.status).send({ error: `Snapshot target error: ${error.response.statusText}` });
        } else if (error.request) {
            // The request was made but no response was received
             reply.status(504).send({ error: 'Snapshot target did not respond (Gateway Timeout)' });
        } else {
            // Something happened in setting up the request that triggered an Error
             reply.status(500).send({ error: 'Failed to make snapshot request', details: error.message });
        }
    }
});


// Function to attempt starting a camera instance
async function tryStartCamera(cameraConfig) {
    const cameraId = cameraConfig.id;
    if (runningCameras.has(cameraId)) {
        fastify.log.info(`[Startup] Camera ${cameraId} is already marked as running.`);
        return;
    }
     if (!cameraConfig.mac_address || !cameraConfig.target_nvr_hostname) {
         fastify.log.warn(`[Startup] Cannot start camera ${cameraId}: Missing MAC address or target NVR hostname.`);
         db.prepare(`UPDATE virtual_cameras SET status = 'error', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).run(cameraId);
         return;
     }

    try {
        fastify.log.info(`[Startup] Attempting to start camera ${cameraId} (${cameraConfig.custom_name})...`);
        const cameraInstance = new VirtualCamera(cameraConfig, fastify.log);
        await cameraInstance.start();
        runningCameras.set(cameraId, cameraInstance);
        // Ensure DB status is 'running' (might be starting from 'error' or 'stopped')
        db.prepare(`UPDATE virtual_cameras SET status = 'running', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).run(cameraId);
        fastify.log.info(`[Startup] Camera ${cameraId} started successfully.`);
    } catch (error) {
        fastify.log.error(`[Startup] Error starting camera ${cameraId}:`, error);
        db.prepare(`UPDATE virtual_cameras SET status = 'error', updated_at = CURRENT_TIMESTAMP WHERE id = ?`).run(cameraId);
    }
}

// Start the server and attempt to start persisted running cameras
const start = async () => {
    try {
        // 1. Start the Fastify server
        await fastify.listen({ port: 3000, host: '0.0.0.0' });
        fastify.log.info(`Backend server listening on port 3000`); // Use logger

        // 2. Query DB for cameras that should be running
        fastify.log.info('Checking for cameras to auto-start...');
        const camerasToStart = db.prepare(`
             SELECT
                vc.*,
                vi.mac_address,
                vi.interface_name,
                n.hostname as target_nvr_hostname
            FROM virtual_cameras vc
            LEFT JOIN virtual_interfaces vi ON vc.assigned_interface_id = vi.id
            LEFT JOIN nvrs n ON vc.nvr_id = n.id
            WHERE vc.status = 'running'
        `).all();

        fastify.log.info(`Found ${camerasToStart.length} cameras marked as running in DB.`);

        // 3. Attempt to start each one
        for (const cameraConfig of camerasToStart) {
            await tryStartCamera(cameraConfig); // Start sequentially for potentially clearer logs
        }
        fastify.log.info('Auto-start process complete.');

    } catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
}
start();
