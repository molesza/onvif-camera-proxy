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