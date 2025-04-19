const fastify = require('fastify')({ logger: true });
const Database = require('better-sqlite3');

// Database setup
const db = new Database('db/onvif-proxy.db');

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

// POST /api/nvrs/:id/scan - Scan NVR for channels
fastify.post('/api/nvrs/:id/scan', async (request, reply) => {
    const { id } = request.params;
    try {
        const nvr = db.prepare('SELECT hostname, port, username, password FROM nvrs WHERE id = ?').get(id);
        if (!nvr) {
            return reply.status(404).send({ error: 'NVR not found' });
        }

        const cameraConfigs = await createConfig(nvr.hostname, nvr.port, nvr.username, nvr.password);
        
        // Insert cameraConfigs into virtual_cameras table
        const insertStmt = db.prepare(`
            INSERT INTO virtual_cameras (
                nvr_id, custom_name, original_name, profile_token, video_source_token,
                uuid, server_port, rtsp_proxy_port, snapshot_proxy_port,
                hq_rtsp_path, hq_snapshot_path, hq_width, hq_height, hq_framerate, hq_bitrate,
                lq_rtsp_path, lq_snapshot_path, lq_width, lq_height, lq_framerate, lq_bitrate,
                target_nvr_rtsp_port, target_nvr_snapshot_port
            ) VALUES (
                ?, ?, ?, ?, ?,
                uuid(), ?, ?, ?,
                ?, ?, ?, ?, ?, ?,
                ?, ?, ?, ?, ?, ?,
                ?, ?
            )
        `);

        let portCounter = 9000; // Starting port for virtual servers, proxies
        cameraConfigs.forEach(config => {
            const ports = {
                server_port: portCounter++,
                rtsp_proxy_port: portCounter++,
                snapshot_proxy_port: portCounter++
            };
            insertStmt.run(
                id, config.original_name, config.original_name, config.profile_token, config.video_source_token,
                ports.server_port, ports.rtsp_proxy_port, ports.snapshot_proxy_port,
                config.hq_rtsp_path, config.hq_snapshot_path, config.hq_width, config.hq_height, config.hq_framerate, config.hq_bitrate,
                config.lq_rtsp_path, config.lq_snapshot_path, config.lq_width, config.lq_height, config.lq_framerate, config.lq_bitrate,
                config.target_nvr_rtsp_port, config.target_nvr_snapshot_port
            );
        });

        reply.send({ message: 'NVR scan initiated and virtual cameras created', cameraConfigs });
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

// Start the server
const start = async () => {
    try {
        await fastify.listen({ port: 3000, host: '0.0.0.0' });
        console.log('Backend server listening on port 3000');
    } catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
}
start();