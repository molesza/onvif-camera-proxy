const soap = require('soap');
const http = require('http');
const dgram = require('dgram');
const xml2js = require('xml2js');
const { v1: uuidv1 } = require('uuid'); // Use v1 for discovery messages as in original
const url = require('url');
const fs = require('fs');
const os = require('os');
const path = require('path');
const tcpProxy = require('node-tcp-proxy');

// --- Helper: Get IP from MAC ---
// (Moved outside class for potential reuse, accepts logger)
function getIpAddressFromMac(macAddress, logger) {
    if (!macAddress) {
        logger?.warn('getIpAddressFromMac called with null/empty MAC address.');
        return null;
    }
    try {
        const networkInterfaces = os.networkInterfaces();
        for (const interfaceName in networkInterfaces) {
            const networks = networkInterfaces[interfaceName];
            if (networks) {
                for (const network of networks) {
                    if (network.family === 'IPv4' && network.mac && network.mac.toLowerCase() === macAddress.toLowerCase()) {
                        logger?.debug(`Found IP ${network.address} for MAC ${macAddress} on interface ${interfaceName}`);
                        return network.address;
                    }
                }
            }
        }
        logger?.warn(`No IPv4 address found for MAC address ${macAddress}`);
    } catch (error) {
        logger?.error(`Error getting network interfaces: ${error}`);
    }
    return null;
}

// --- Date Helpers (from original) ---
Date.prototype.stdTimezoneOffset = function() {
    let jan = new Date(this.getFullYear(), 0, 1);
    let jul = new Date(this.getFullYear(), 6, 1);
    return Math.max(jan.getTimezoneOffset(), jul.getTimezoneOffset());
}
Date.prototype.isDstObserved = function() {
    return this.getTimezoneOffset() < this.stdTimezoneOffset();
}
// --- End Date Helpers ---

class VirtualCamera {
    constructor(dbConfig, logger) {
        this.config = dbConfig; // Config object directly from virtual_cameras table + joined interface data
        this.logger = logger || console; // Use provided logger or fallback to console
        this.server = null;
        this.deviceService = null;
        this.mediaService = null;
        this.discoverySocket = null;
        this.rtspProxy = null;
        this.snapshotProxy = null;
        this.ipAddress = null; // Will be resolved before starting

        // --- Build ONVIF structures based on dbConfig ---
        // (Simplified compared to original, uses dbConfig fields directly)
        this.videoSource = {
            attributes: { token: 'video_src_token' }, // Keep token simple for now
            Framerate: this.config.hq_framerate || 15, // Use defaults if null
            Resolution: { Width: this.config.hq_width || 1920, Height: this.config.hq_height || 1080 }
        };

        this.profiles = [{
            Name: 'MainStream',
            attributes: { token: 'main_stream' },
            VideoSourceConfiguration: {
                Name: 'VideoSource', UseCount: 2, attributes: { token: 'video_src_config_token' },
                SourceToken: 'video_src_token',
                Bounds: { attributes: { x: 0, y: 0, width: this.config.hq_width || 1920, height: this.config.hq_height || 1080 } }
            },
            VideoEncoderConfiguration: {
                attributes: { token: 'encoder_hq_config_token' }, Name: 'HqConfig', UseCount: 1, Encoding: 'H264',
                Resolution: { Width: this.config.hq_width || 1920, Height: this.config.hq_height || 1080 },
                Quality: 4, // Keep quality simple for now
                RateControl: { FrameRateLimit: this.config.hq_framerate || 15, EncodingInterval: 1, BitrateLimit: this.config.hq_bitrate || 2048 },
                H264: { GovLength: this.config.hq_framerate || 15, H264Profile: 'Main' }, SessionTimeout: 'PT1000S'
            }
        }];

        // Add Low Quality profile if data exists
        if (this.config.lq_width && this.config.lq_height && this.config.lq_framerate && this.config.lq_bitrate) {
            this.profiles.push({
                Name: 'SubStream',
                attributes: { token: 'sub_stream' },
                VideoSourceConfiguration: { // Re-use the same source config token
                    Name: 'VideoSource', UseCount: 2, attributes: { token: 'video_src_config_token' },
                    SourceToken: 'video_src_token',
                    Bounds: { attributes: { x: 0, y: 0, width: this.config.hq_width || 1920, height: this.config.hq_height || 1080 } } // Bounds still relate to source
                },
                VideoEncoderConfiguration: {
                    attributes: { token: 'encoder_lq_config_token' }, Name: 'LqConfig', UseCount: 1, Encoding: 'H264',
                    Resolution: { Width: this.config.lq_width, Height: this.config.lq_height },
                    Quality: 1, // Lower quality
                    RateControl: { FrameRateLimit: this.config.lq_framerate, EncodingInterval: 1, BitrateLimit: this.config.lq_bitrate },
                    H264: { GovLength: this.config.lq_framerate, H264Profile: 'Main' }, SessionTimeout: 'PT1000S'
                }
            });
        }
        // --- End ONVIF structure build ---

        // --- Define ONVIF Service Implementation ---
        // (Uses 'this' context for config and ipAddress)
        this.onvifServiceImpl = {
            DeviceService: { Device: this._createDeviceService() },
            MediaService: { Media: this._createMediaService() }
        };
        // --- End ONVIF Service ---
    }

    // --- Private methods to create service implementations ---
    _createDeviceService() {
        return {
            GetSystemDateAndTime: (args, cb, headers, req) => {
                 this.logger.debug(`[${this.config.id}] GetSystemDateAndTime request from ${req?.socket?.remoteAddress}`);
                 let now = new Date();
                 let offset = now.getTimezoneOffset();
                 let abs_offset = Math.abs(offset);
                 let hrs_offset = Math.floor(abs_offset / 60);
                 let mins_offset = (abs_offset % 60);
                 let tz = 'UTC' + (offset < 0 ? '-' : '+') + hrs_offset + (mins_offset === 0 ? '' : ':' + mins_offset);
                 return { SystemDateAndTime: { DateTimeType: 'NTP', DaylightSavings: now.isDstObserved(), TimeZone: { TZ: tz },
                     UTCDateTime: { Time: { Hour: now.getUTCHours(), Minute: now.getUTCMinutes(), Second: now.getUTCSeconds() }, Date: { Year: now.getUTCFullYear(), Month: now.getUTCMonth() + 1, Day: now.getUTCDate() } },
                     LocalDateTime: { Time: { Hour: now.getHours(), Minute: now.getMinutes(), Second: now.getSeconds() }, Date: { Year: now.getFullYear(), Month: now.getMonth() + 1, Day: now.getDate() } },
                     Extension: {} } };
            },
            GetCapabilities: (args, cb, headers, req) => {
                 this.logger.debug(`[${this.config.id}] GetCapabilities request from ${req?.socket?.remoteAddress} for Category: ${args?.Category}`);
                 let response = { Capabilities: {} };
                 const deviceXAddr = `http://${this.ipAddress}:${this.config.server_port}/onvif/device_service`;
                 const mediaXAddr = `http://${this.ipAddress}:${this.config.server_port}/onvif/media_service`;

                 if (!args?.Category || args.Category == 'All' || args.Category == 'Device') {
                     response.Capabilities['Device'] = { XAddr: deviceXAddr, /* ... other capabilities ... */ };
                 }
                 if (!args?.Category || args.Category == 'All' || args.Category == 'Media') {
                     response.Capabilities['Media'] = { XAddr: mediaXAddr, StreamingCapabilities: { RTPMulticast: false, RTP_TCP: true, RTP_RTSP_TCP: true, Extension: {} },
                         Extension: { ProfileCapabilities: { MaximumNumberOfProfiles: this.profiles.length } } };
                 }
                 // Add other categories (Events, Imaging, etc.) as needed, returning empty {} if not supported
                 return response;
            },
            GetServices: (args, cb, headers, req) => {
                 this.logger.debug(`[${this.config.id}] GetServices request from ${req?.socket?.remoteAddress}`);
                 const deviceXAddr = `http://${this.ipAddress}:${this.config.server_port}/onvif/device_service`;
                 const mediaXAddr = `http://${this.ipAddress}:${this.config.server_port}/onvif/media_service`;
                 return { Service : [
                     { Namespace : 'http://www.onvif.org/ver10/device/wsdl', XAddr : deviceXAddr, Version : { Major : 2, Minor : 5 } },
                     { Namespace : 'http://www.onvif.org/ver10/media/wsdl', XAddr : mediaXAddr, Version : { Major : 2, Minor : 5 } }
                     // Add other supported services here
                 ]};
            },
            GetDeviceInformation: (args, cb, headers, req) => {
                 this.logger.debug(`[${this.config.id}] GetDeviceInformation request from ${req?.socket?.remoteAddress}`);
                 return { Manufacturer: 'ONVIF Proxy', Model: this.config.custom_name || 'Virtual Camera', FirmwareVersion: '1.0.0',
                     SerialNumber: this.config.uuid || 'N/A', HardwareId: `VIRT-${this.config.id || 'N/A'}` };
            }
            // Add other required DeviceService methods (e.g., GetHostname, GetNetworkInterfaces) returning appropriate defaults or errors
        };
    }

    _createMediaService() {
        return {
            GetProfiles: (args, cb, headers, req) => {
                this.logger.debug(`[${this.config.id}] GetProfiles request from ${req?.socket?.remoteAddress}`);
                return { Profiles: this.profiles };
            },
            GetVideoSources: (args, cb, headers, req) => {
                 this.logger.debug(`[${this.config.id}] GetVideoSources request from ${req?.socket?.remoteAddress}`);
                 return { VideoSources: [ this.videoSource ] };
            },
            GetSnapshotUri: (args, cb, headers, req) => {
                this.logger.debug(`[${this.config.id}] GetSnapshotUri request from ${req?.socket?.remoteAddress} for Profile: ${args?.ProfileToken}`);
                let snapshotPath = null;
                if (args?.ProfileToken === 'sub_stream' && this.config.lq_snapshot_path) {
                    snapshotPath = this.config.lq_snapshot_path;
                } else if (this.config.hq_snapshot_path) {
                    snapshotPath = this.config.hq_snapshot_path;
                }

                if (snapshotPath && this.config.snapshot_proxy_port) {
                    const uri = `http://${this.ipAddress}:${this.config.snapshot_proxy_port}${snapshotPath}`;
                    return { MediaUri : { Uri: uri, InvalidAfterConnect : false, InvalidAfterReboot : false, Timeout : 'PT30S' } };
                } else {
                    // Return default placeholder image served by the main http server? Or error?
                    // For now, return placeholder served by main server if no proxy path/port
                     const uri = `http://${this.ipAddress}:${this.config.server_port}/snapshot.png`;
                     this.logger.warn(`[${this.config.id}] Snapshot requested but no snapshot path/port configured. Returning placeholder URI.`);
                     return { MediaUri : { Uri: uri, InvalidAfterConnect : false, InvalidAfterReboot : false, Timeout : 'PT30S' } };
                    // OR throw soap fault: cb({ Fault: { /* ... */ } });
                }
            },
            GetStreamUri: (args, cb, headers, req) => {
                this.logger.debug(`[${this.config.id}] GetStreamUri request from ${req?.socket?.remoteAddress} for Profile: ${args?.ProfileToken}`);
                let rtspPath = this.config.hq_rtsp_path; // Default to HQ
                if (args?.ProfileToken === 'sub_stream' && this.config.lq_rtsp_path) {
                    rtspPath = this.config.lq_rtsp_path;
                }

                if (!rtspPath) {
                     this.logger.error(`[${this.config.id}] No RTSP path found for profile token: ${args?.ProfileToken}`);
                     // Throwing a SOAP fault is more appropriate here
                     cb({ Fault: { Code: { Value: 'env:Sender', Subcode: { Value: 'ter:InvalidArgVal' } }, Reason: { Text: 'No RTSP stream configured for the requested profile' } } });
                     return; // Important: return after calling cb with fault
                }

                const uri = `rtsp://${this.ipAddress}:${this.config.rtsp_proxy_port}${rtspPath}`;
                return { MediaUri: { Uri: uri, InvalidAfterConnect: false, InvalidAfterReboot: false, Timeout: 'PT30S' } };
            }
            // Add other required MediaService methods (e.g., GetVideoEncoderConfigurations)
        };
    }
    // --- End Service Impl ---


    // --- Public Control Methods ---
    async start() {
        this.ipAddress = getIpAddressFromMac(this.config.mac_address, this.logger);
        if (!this.ipAddress) {
            throw new Error(`Failed to find IP address for MAC ${this.config.mac_address}`);
        }
        this.logger.info(`[${this.config.id}] Starting virtual camera '${this.config.custom_name}' on ${this.ipAddress}:${this.config.server_port}`);

        // 1. Start HTTP Server for ONVIF SOAP requests & placeholder snapshot
        await this._startHttpServer();

        // 2. Start Discovery if enabled
        if (this.config.discovery_enabled) {
            this._startDiscovery();
        }

        // 3. Start TCP Proxies
        this._startProxies();

        this.logger.info(`[${this.config.id}] Virtual camera started successfully.`);
    }

    async stop() {
        this.logger.info(`[${this.config.id}] Stopping virtual camera '${this.config.custom_name}'...`);
        let stopped = false;

        // Stop Discovery
        if (this.discoverySocket) {
            try {
                this.discoverySocket.close(() => {
                     this.logger.debug(`[${this.config.id}] Discovery socket closed.`);
                     this.discoverySocket = null;
                });
                 stopped = true;
            } catch (err) {
                this.logger.error(`[${this.config.id}] Error closing discovery socket: ${err}`);
            }
        }

        // Stop HTTP Server (closes SOAP listeners too)
        if (this.server) {
            try {
                await new Promise((resolve, reject) => {
                    this.server.close((err) => {
                        if (err) {
                            this.logger.error(`[${this.config.id}] Error closing HTTP server: ${err}`);
                            reject(err); // Reject promise on error
                        } else {
                            this.logger.debug(`[${this.config.id}] HTTP server closed.`);
                            this.server = null;
                            this.deviceService = null; // Listeners are closed with server
                            this.mediaService = null;
                            resolve(); // Resolve promise on success
                        }
                    });
                });
                 stopped = true;
            } catch (err) {
                 this.logger.error(`[${this.config.id}] Exception closing HTTP server: ${err}`);
                 // Continue trying to stop other things
            }
        }

        // Stop Proxies
        if (this.rtspProxy) {
            try {
                this.rtspProxy.end(); // Use end() for node-tcp-proxy
                this.logger.debug(`[${this.config.id}] RTSP proxy stopped.`);
                this.rtspProxy = null;
                 stopped = true;
            } catch (err) {
                this.logger.error(`[${this.config.id}] Error stopping RTSP proxy: ${err}`);
            }
        }
        if (this.snapshotProxy) {
             try {
                this.snapshotProxy.end();
                this.logger.debug(`[${this.config.id}] Snapshot proxy stopped.`);
                this.snapshotProxy = null;
                 stopped = true;
            } catch (err) {
                this.logger.error(`[${this.config.id}] Error stopping Snapshot proxy: ${err}`);
            }
        }

        if (stopped) {
            this.logger.info(`[${this.config.id}] Virtual camera stopped.`);
        } else {
             this.logger.warn(`[${this.config.id}] Virtual camera stop requested, but no active components found.`);
        }
    }

    enableDiscovery() {
        if (!this.discoverySocket && this.ipAddress) {
            this.logger.info(`[${this.config.id}] Enabling discovery...`);
            this._startDiscovery();
            this.config.discovery_enabled = true; // Update internal state
        } else if (!this.ipAddress) {
             this.logger.warn(`[${this.config.id}] Cannot enable discovery, IP address not resolved.`);
        } else {
             this.logger.info(`[${this.config.id}] Discovery already enabled.`);
        }
    }

    disableDiscovery() {
        if (this.discoverySocket) {
             this.logger.info(`[${this.config.id}] Disabling discovery...`);
             try {
                this.discoverySocket.close(() => {
                     this.logger.debug(`[${this.config.id}] Discovery socket closed.`);
                     this.discoverySocket = null;
                     this.config.discovery_enabled = false; // Update internal state
                });
            } catch (err) {
                this.logger.error(`[${this.config.id}] Error closing discovery socket: ${err}`);
            }
        } else {
             this.logger.info(`[${this.config.id}] Discovery already disabled.`);
        }
    }
    // --- End Public Control ---


    // --- Private Start/Stop Helpers ---
    _startHttpServer() {
        return new Promise((resolve, reject) => {
            this.server = http.createServer(this._httpListen.bind(this)); // Bind context

            // Error handling for server creation/listen
            this.server.on('error', (err) => {
                this.logger.error(`[${this.config.id}] HTTP server error: ${err}`);
                this.server = null; // Ensure server is null on error
                reject(err); // Reject the promise
            });

            this.server.listen(this.config.server_port, this.ipAddress, () => {
                this.logger.debug(`[${this.config.id}] HTTP server listening on ${this.ipAddress}:${this.config.server_port}`);

                const wsdlDir = path.join(__dirname, '../wsdl');
                const deviceWsdl = fs.readFileSync(path.join(wsdlDir, 'device_service.wsdl'), 'utf8');
                const mediaWsdl = fs.readFileSync(path.join(wsdlDir, 'media_service.wsdl'), 'utf8');

                try {
                    this.deviceService = soap.listen(this.server, {
                        path: '/onvif/device_service', services: this.onvifServiceImpl, xml: deviceWsdl, forceSoap12Headers: true
                    });
                    this.mediaService = soap.listen(this.server, {
                        path: '/onvif/media_service', services: this.onvifServiceImpl, xml: mediaWsdl, forceSoap12Headers: true
                    });

                    // Optional: Add logging for SOAP requests if needed
                    this.deviceService.on('request', (request, methodName) => this.logger.trace(`[${this.config.id}] DeviceService Request: ${methodName}`));
                    this.mediaService.on('request', (request, methodName) => this.logger.trace(`[${this.config.id}] MediaService Request: ${methodName}`));

                    resolve(); // Resolve promise once listeners are attached
                } catch (err) {
                     this.logger.error(`[${this.config.id}] Failed to attach SOAP listeners: ${err}`);
                     // Attempt to close server if SOAP fails
                     this.server.close(() => { this.server = null; });
                     reject(err);
                }
            });
        });
    }

    _httpListen(request, response) {
        // Only handles placeholder snapshot for now
        const parsedUrl = url.parse(request.url);
        this.logger.trace(`[${this.config.id}] HTTP request: ${request.method} ${parsedUrl.pathname}`);
        if (request.method === 'GET' && parsedUrl.pathname === '/snapshot.png') {
            try {
                const imagePath = path.join(__dirname, '../resources/snapshot.png');
                const image = fs.readFileSync(imagePath);
                response.writeHead(200, {'Content-Type': 'image/png', 'Content-Length': image.length });
                response.end(image, 'binary');
            } catch (err) {
                 this.logger.error(`[${this.config.id}] Error reading placeholder snapshot: ${err}`);
                 response.writeHead(500);
                 response.end('Error loading snapshot');
            }
        } else {
            // Let SOAP handle other paths, or return 404 if needed
            // response.writeHead(404, {'Content-Type': 'text/plain'});
            // response.end('Not Found');
        }
    }

    _startDiscovery() {
        if (this.discoverySocket) {
            this.logger.warn(`[${this.config.id}] Discovery socket already exists.`);
            return;
        }
        try {
            this.discoveryMessageNo = 0;
            this.discoverySocket = dgram.createSocket({ type: 'udp4', reuseAddr: true });

            this.discoverySocket.on('error', (err) => {
                this.logger.error(`[${this.config.id}] Discovery socket error: ${err}`);
                this.discoverySocket.close();
                this.discoverySocket = null; // Reset on error
            });

            this.discoverySocket.on('message', (message, remote) => {
                this._handleDiscoveryMessage(message, remote);
            });

            this.discoverySocket.bind(3702, () => { // Use ONVIF discovery port
                try {
                    this.discoverySocket.addMembership('239.255.255.250', this.ipAddress); // Use specific IP
                    this.logger.info(`[${this.config.id}] Discovery service listening on ${this.ipAddress}:3702`);
                } catch (err) {
                     this.logger.error(`[${this.config.id}] Failed to add multicast membership: ${err}. Discovery may not work.`);
                     // Should we close the socket here? Maybe not, might still receive direct probes.
                }
            });
        } catch (err) {
             this.logger.error(`[${this.config.id}] Failed to create or bind discovery socket: ${err}`);
             this.discoverySocket = null;
        }
    }

     _handleDiscoveryMessage(message, remote) {
         this.logger.trace(`[${this.config.id}] Discovery message from ${remote.address}:${remote.port}`);
         try {
            xml2js.parseString(message.toString(), { tagNameProcessors: [xml2js.processors.stripPrefix] }, (err, result) => {
                if (err) {
                    this.logger.warn(`[${this.config.id}] Failed to parse discovery message XML: ${err}`);
                    return;
                }
                try {
                    const probeUuid = result?.Envelope?.Header?.[0]?.MessageID?.[0];
                    let probeType = result?.Envelope?.Body?.[0]?.Probe?.[0]?.Types?.[0];

                    if (!probeUuid) {
                         this.logger.warn(`[${this.config.id}] Discovery message missing MessageID.`);
                         return;
                    }

                    if (typeof probeType === 'object') probeType = probeType._; // Handle potential xml2js object format

                    // Respond if it's a generic probe or specifically for NetworkVideoTransmitter
                    if (!probeType || probeType.includes('NetworkVideoTransmitter')) {
                        this.logger.debug(`[${this.config.id}] Responding to discovery probe ${probeUuid}`);
                        const response = this._buildDiscoveryResponse(probeUuid);
                        const responseBuffer = Buffer.from(response);
                        // Send response using a temporary socket (safer than reusing discoverySocket)
                        const senderSocket = dgram.createSocket('udp4');
                        senderSocket.send(responseBuffer, 0, responseBuffer.length, remote.port, remote.address, (err) => {
                            if (err) this.logger.error(`[${this.config.id}] Error sending discovery response: ${err}`);
                            senderSocket.close();
                        });
                        this.discoveryMessageNo++;
                    } else {
                         this.logger.trace(`[${this.config.id}] Ignoring probe for type: ${probeType}`);
                    }
                } catch (parseErr) {
                     this.logger.warn(`[${this.config.id}] Error processing parsed discovery message: ${parseErr}`);
                }
            });
         } catch (xmlErr) {
              this.logger.error(`[${this.config.id}] XML parsing error during discovery: ${xmlErr}`);
         }
     }

     _buildDiscoveryResponse(relatesToUuid) {
         const messageId = uuidv1();
         const deviceUuid = this.config.uuid; // Use the UUID assigned to this virtual camera
         const xAddr = `http://${this.ipAddress}:${this.config.server_port}/onvif/device_service`;
         // Simplified scopes
         const scopes = `onvif://www.onvif.org/hardware/${this.config.custom_name || 'VirtualCamera'} onvif://www.onvif.org/name/${this.config.custom_name || 'VirtualCamera'}`;

         return `<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:dn="http://www.onvif.org/ver10/network/wsdl">
<SOAP-ENV:Header>
<wsa:MessageID>urn:uuid:${messageId}</wsa:MessageID>
<wsa:RelatesTo>${relatesToUuid}</wsa:RelatesTo>
<wsa:To SOAP-ENV:mustUnderstand="true">http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To>
<wsa:Action SOAP-ENV:mustUnderstand="true">http://schemas.xmlsoap.org/ws/2005/04/discovery/ProbeMatches</wsa:Action>
<d:AppSequence SOAP-ENV:mustUnderstand="true" MessageNumber="${this.discoveryMessageNo}" InstanceId="${Date.now()}"/>
</SOAP-ENV:Header>
<SOAP-ENV:Body>
<d:ProbeMatches><d:ProbeMatch>
<wsa:EndpointReference><wsa:Address>urn:uuid:${deviceUuid}</wsa:Address></wsa:EndpointReference>
<d:Types>dn:NetworkVideoTransmitter</d:Types>
<d:Scopes>${scopes}</d:Scopes>
<d:XAddrs>${xAddr}</d:XAddrs>
<d:MetadataVersion>1</d:MetadataVersion>
</d:ProbeMatch></d:ProbeMatches>
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>`;
     }


    _startProxies() {
        // Start RTSP Proxy
        if (this.config.rtsp_proxy_port && this.config.target_nvr_hostname && this.config.target_nvr_rtsp_port) {
            try {
                this.rtspProxy = tcpProxy.createProxy(
                    this.config.rtsp_proxy_port,
                    this.config.target_nvr_hostname,
                    this.config.target_nvr_rtsp_port,
                     { hostname: this.ipAddress } // Bind proxy to the specific IP
                 );
                 this.logger.info(`[${this.config.id}] RTSP proxy started: ${this.ipAddress}:${this.config.rtsp_proxy_port} -> ${this.config.target_nvr_hostname}:${this.config.target_nvr_rtsp_port}`);
                 // Note: .on('error', ...) removed as it caused TypeError with this library version
             } catch (err) {
                  this.logger.error(`[${this.config.id}] Failed to start RTSP proxy: ${err}`);
                 this.rtspProxy = null;
            }
        } else {
             this.logger.warn(`[${this.config.id}] RTSP proxy not started due to missing configuration.`);
        }

        // Start Snapshot Proxy (if configured)
        if (this.config.snapshot_proxy_port && this.config.target_nvr_hostname && this.config.target_nvr_snapshot_port && this.config.hq_snapshot_path) {
             try {
                this.snapshotProxy = tcpProxy.createProxy(
                    this.config.snapshot_proxy_port,
                    this.config.target_nvr_hostname,
                    this.config.target_nvr_snapshot_port,
                     { hostname: this.ipAddress } // Bind proxy to the specific IP
                 );
                 this.logger.info(`[${this.config.id}] Snapshot proxy started: ${this.ipAddress}:${this.config.snapshot_proxy_port} -> ${this.config.target_nvr_hostname}:${this.config.target_nvr_snapshot_port}`);
                 // Note: .on('error', ...) removed as it caused TypeError with this library version
             } catch (err) {
                  this.logger.error(`[${this.config.id}] Failed to start Snapshot proxy: ${err}`);
                 this.snapshotProxy = null;
            }
        } else {
             this.logger.info(`[${this.config.id}] Snapshot proxy not started (snapshot path or port not configured).`);
        }
    }
    // --- End Private Helpers ---
}

module.exports = { VirtualCamera, getIpAddressFromMac }; // Export class and helper
