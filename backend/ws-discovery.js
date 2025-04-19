const dgram = require('dgram');
const { v4: uuidv4 } = require('uuid');
const xml2js = require('xml2js');
const os = require('os');

const DISCOVERY_MULTICAST_ADDRESS = '239.255.255.250';
const DISCOVERY_PORT = 3702;
const PROBE_TIMEOUT = 3000; // Milliseconds to wait for responses

// Function to get all non-internal IPv4 addresses
function getSystemIPs() {
    const ips = [];
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const net of interfaces[name]) {
            // Skip over non-IPv4 and internal (i.e. 127.0.0.1) addresses
            if (net.family === 'IPv4' && !net.internal) {
                ips.push(net.address);
            }
        }
    }
    return ips;
}

// Function to perform WS-Discovery probe
function discoverOnvifDevices(logger) {
    return new Promise((resolve, reject) => {
        const discoveredDevices = new Map(); // Use Map to store unique devices by UUID
        let sockets = []; // Keep track of sockets to close them properly

        const probeMessage = `<?xml version="1.0" encoding="UTF-8"?>
<e:Envelope xmlns:e="http://www.w3.org/2003/05/soap-envelope" xmlns:w="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery" xmlns:dn="http://www.onvif.org/ver10/network/wsdl">
<e:Header><w:MessageID>uuid:${uuidv4()}</w:MessageID><w:To e:mustUnderstand="true">urn:schemas-xmlsoap-org:ws:2005:04:discovery</w:To><w:Action e:mustUnderstand="true">http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</w:Action></e:Header>
<e:Body><d:Probe><d:Types>dn:NetworkVideoTransmitter</d:Types></d:Probe></e:Body>
</e:Envelope>`;
        const probeBuffer = Buffer.from(probeMessage);

        const systemIPs = getSystemIPs();
        if (systemIPs.length === 0) {
            logger?.warn('WS-Discovery: No suitable local IP addresses found to bind sockets.');
            // Resolve with empty list or reject? Resolve empty for now.
            return resolve([]);
        }

        let responsesExpected = systemIPs.length;
        let responsesReceived = 0;

        const parser = new xml2js.Parser({ explicitArray: false, tagNameProcessors: [xml2js.processors.stripPrefix] });

        const closeSockets = () => {
            sockets.forEach(socket => {
                try { socket.close(); } catch (e) { logger?.error('Error closing discovery socket:', e); }
            });
            sockets = []; // Clear the array
        };

        // Set a timeout to resolve the promise even if not all sockets receive messages
        const timeoutId = setTimeout(() => {
            logger?.debug(`WS-Discovery: Probe timeout reached after ${PROBE_TIMEOUT}ms.`);
            closeSockets();
            resolve(Array.from(discoveredDevices.values()));
        }, PROBE_TIMEOUT);

        systemIPs.forEach(ip => {
            const socket = dgram.createSocket({ type: 'udp4', reuseAddr: true });
            sockets.push(socket);

            socket.on('error', (err) => {
                logger?.error(`WS-Discovery: Socket error on ${ip}: ${err.stack}`);
                socket.close(); // Close socket on error
                responsesReceived++;
                if (responsesReceived === responsesExpected) {
                    clearTimeout(timeoutId);
                    closeSockets();
                    resolve(Array.from(discoveredDevices.values()));
                }
            });

            socket.on('message', (msg, rinfo) => {
                logger?.trace(`WS-Discovery: Received message from ${rinfo.address}:${rinfo.port} on socket ${ip}`);
                parser.parseString(msg, (err, result) => {
                    if (err) {
                        logger?.warn(`WS-Discovery: Failed to parse response XML from ${rinfo.address}: ${err}`);
                        return;
                    }
                    try {
                        const probeMatch = result?.Envelope?.Body?.ProbeMatches?.ProbeMatch;
                        if (probeMatch) {
                            const endpointRef = probeMatch.EndpointReference?.Address;
                            const uuidMatch = endpointRef?.match(/urn:uuid:(.+)/);
                            const deviceUUID = uuidMatch ? uuidMatch[1] : endpointRef; // Use full address if no UUID urn
                            const xaddrs = probeMatch.XAddrs;
                            const scopes = probeMatch.Scopes;

                            if (deviceUUID && !discoveredDevices.has(deviceUUID)) {
                                // Extract a primary XAddr (often the device service)
                                let primaryXAddr = Array.isArray(xaddrs) ? xaddrs[0] : xaddrs;
                                if (typeof primaryXAddr === 'string') {
                                    primaryXAddr = primaryXAddr.split(' ')[0]; // Handle space-separated lists
                                } else {
                                    primaryXAddr = null; // Could not determine XAddr
                                }

                                logger?.debug(`WS-Discovery: Discovered device UUID: ${deviceUUID}, XAddr: ${primaryXAddr}`);
                                discoveredDevices.set(deviceUUID, {
                                    uuid: deviceUUID,
                                    xaddrs: xaddrs, // Keep original potentially multi-valued field
                                    primaryXAddr: primaryXAddr,
                                    scopes: scopes,
                                    sourceAddress: rinfo.address // IP address the response came from
                                });
                            }
                        }
                    } catch (parseErr) {
                        logger?.warn(`WS-Discovery: Error processing parsed ProbeMatch from ${rinfo.address}: ${parseErr}`);
                    }
                });
            });

            socket.bind(0, ip, () => { // Bind to specific IP and random port
                 try {
                    logger?.debug(`WS-Discovery: Socket bound to ${ip}:${socket.address().port}`);
                    socket.setBroadcast(true); // Required for multicast sending on some systems
                    // socket.setMulticastTTL(128); // Optional: Set TTL if needed
                    socket.send(probeBuffer, 0, probeBuffer.length, DISCOVERY_PORT, DISCOVERY_MULTICAST_ADDRESS, (err) => {
                        if (err) {
                            logger?.error(`WS-Discovery: Error sending probe from ${ip}: ${err}`);
                            // Don't count this as a response, let timeout handle it
                        } else {
                            logger?.debug(`WS-Discovery: Probe sent from ${ip} to ${DISCOVERY_MULTICAST_ADDRESS}:${DISCOVERY_PORT}`);
                        }
                        // Don't increment responsesReceived here, wait for timeout or socket error/close
                    });
                 } catch (bindErr) {
                      logger?.error(`WS-Discovery: Error binding or setting options for socket on ${ip}: ${bindErr}`);
                      responsesReceived++; // Count this as a failed attempt
                      if (responsesReceived === responsesExpected) {
                          clearTimeout(timeoutId);
                          closeSockets();
                          resolve(Array.from(discoveredDevices.values()));
                      }
                 }
            });
        });
    });
}

module.exports = { discoverOnvifDevices };
