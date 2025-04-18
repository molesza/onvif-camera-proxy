const tcpProxy = require('node-tcp-proxy');
const onvifServer = require('./src/onvif-server');
const configBuilder = require('./src/config-builder');
const package = require('./package.json');
const argparse = require('argparse');
const readline = require('readline');
const stream = require('stream');
const yaml = require('yaml');
const fs = require('fs');
const simpleLogger = require('simple-node-logger');

/**
 * Reads the MAC-to-IP mapping from the specified file.
 * @param {string} filename - Path to the mapping file (defaults to 'mac_to_interface.txt')
 * @returns {Object} A map where keys are lowercase MAC addresses and values are IP addresses.
 */
function readMacToIpMap(filename = 'mac_to_interface.txt') {
    const map = {};
    try {
        if (!fs.existsSync(filename)) {
             console.warn(`Warning: MAC to IP map file '${filename}' not found.`);
             return map; // Return empty map if file doesn't exist
        }
        const lines = fs.readFileSync(filename, 'utf8').split('\n');
        for (const line of lines) {
            const parts = line.trim().split(/\s+/);
            if (parts.length === 3) {
                const [mac, iface, ip] = parts;
                map[mac.toLowerCase()] = ip; // Store MAC in lowercase for consistent lookup
            }
        }
        console.log(`Loaded ${Object.keys(map).length} MAC-to-IP mappings from ${filename}`);
    } catch (e) {
        console.error(`Error reading or parsing ${filename}: ${e.message}`);
        // Return empty map on error as well, but log the error
    }
    return map;
}

const parser = new argparse.ArgumentParser({
    description: 'Virtual Onvif Server'
});

parser.add_argument('-v', '--version', { action: 'store_true', help: 'show the version information' });
parser.add_argument('-cc', '--create-config', { action: 'store_true', help: 'create a new config' });
parser.add_argument('-d', '--debug', { action: 'store_true', help: 'show onvif requests' });
parser.add_argument('config', { help: 'config filename to use', nargs: '?'});

let args = parser.parse_args();

if (args) {
    const logger = simpleLogger.createSimpleLogger();
    if (args.debug)
        logger.setLevel('trace');

    if (args.version) {
        logger.info('Version: ' + package.version);
        return;
    }

    if (args.create_config) {
        let mutableStdout = new stream.Writable({
            write: function(chunk, encoding, callback) {
                if (!this.muted || chunk.toString().includes('\n'))
                    process.stdout.write(chunk, encoding);
                callback();
            }
        });

        const rl = readline.createInterface({
            input: process.stdin,
            output: mutableStdout,
            terminal: true
        });

        mutableStdout.muted = false;
        rl.question('Onvif Server: ', (hostname) => {
            rl.question('Onvif Username: ', (username) => {
                mutableStdout.muted = true;
                process.stdout.write('Onvif Password: ');
                rl.question('', (password) => {
                    console.log('Generating config ...');
                    // Ensure createConfigWrapper handles potential errors gracefully
                    configBuilder.createConfig(hostname, username, password).then((config) => {
                        if (config) {
                            console.log('# ==================== CONFIG START ====================');
                            console.log(yaml.stringify(config));
                            console.log('# ===================== CONFIG END =====================');
                        } else {
                           console.log('Failed to create config!');
                        }
                    }).catch(err => {
                        // Catch errors from the promise chain in createConfigWrapper
                        console.error("Error during config generation:", err.message || err);
                    }).finally(() => {
                        rl.close();
                    });
                });
            });
        });

    } else if (args.config) {
        let configData;
        try {
            configData = fs.readFileSync(args.config, 'utf8');
        } catch (error) {
            if (error.code === 'ENOENT') {
                logger.error('File not found: ' + args.config);
                return -1;
            }
            throw error;
        }

        let config;
        try {
            config = yaml.parse(configData);
        } catch (error) {
            logger.error('Failed to read config, invalid yaml syntax.')
            return -1;
        }

        // --- Read the MAC-to-IP map ---
        const macToIpMap = readMacToIpMap();
        if (Object.keys(macToIpMap).length === 0) {
            logger.error('MAC to IP map file (mac_to_interface.txt) is empty or could not be read. Cannot determine IP addresses for servers.');
            return -1; // Exit if we can't map MACs to IPs
        }

        let proxies = {};
        // --- START: Dynamic Port Assignment Logic ---
        let baseRtspPort = 8554;
        let baseSnapshotPort = 8580;
        let nvrPorts = {}; // Stores { nvrHostname: { rtsp: port, snapshot: port } }
        // --- END: Dynamic Port Assignment Logic ---

        for (let onvifConfig of config.onvif) {
            // --- Look up the IP address for this camera ---
            const mac = onvifConfig.mac ? onvifConfig.mac.toLowerCase() : null;
            const ipAddress = mac ? macToIpMap[mac] : null; // Get IP from map

            // --- Check if IP was found BEFORE creating server ---
            if (ipAddress) {
                // --- START: Assign Ports ---
                const targetHostname = onvifConfig.target.hostname;
                if (!nvrPorts[targetHostname]) {
                    // First time seeing this NVR, assign current base ports
                    logger.info(`Assigning base ports for new NVR ${targetHostname}: RTSP=${baseRtspPort}, Snapshot=${baseSnapshotPort}`);
                    nvrPorts[targetHostname] = {
                        rtsp: baseRtspPort,
                        snapshot: baseSnapshotPort
                    };
                    // Increment base ports for the *next* NVR
                    baseRtspPort += 2; // Increment RTSP by 2 (for RTCP)
                    baseSnapshotPort += 1; // Increment Snapshot by 1
                }
                // Update the config object *in memory* with the assigned ports for this NVR
                onvifConfig.ports.rtsp = nvrPorts[targetHostname].rtsp;
                onvifConfig.ports.snapshot = nvrPorts[targetHostname].snapshot;
                // --- END: Assign Ports ---

                // --- Pass the found IP address to createServer ---
                let server = onvifServer.createServer(onvifConfig, logger, ipAddress);

                // --- Use the looked-up IP address directly ---
                logger.info(`Starting virtual onvif server for ${onvifConfig.name} on ${ipAddress}:${onvifConfig.ports.server} ...`);
                logger.info(`  Target: ${targetHostname}, Proxy Ports: RTSP=${onvifConfig.ports.rtsp}, Snapshot=${onvifConfig.ports.snapshot}`); // Log assigned proxy ports
                server.startServer();
                // Discovery call removed

                if (args.debug)
                    server.enableDebugOutput();
                logger.info('  Started!');
                logger.info('');

                // Setup proxies using the actual target hostname
                if (!proxies[targetHostname]) {
                    proxies[targetHostname] = {};
                }

                // Use assigned proxy ports from the *updated* onvifConfig
                const rtspProxyPort = onvifConfig.ports.rtsp;
                const snapshotProxyPort = onvifConfig.ports.snapshot;
                const targetRtspPort = onvifConfig.target.ports.rtsp;
                const targetSnapshotPort = onvifConfig.target.ports.snapshot;

                // Add ports to the proxy map *only if they haven't been added for this NVR yet*
                if (rtspProxyPort && targetRtspPort && !proxies[targetHostname][rtspProxyPort]) {
                    proxies[targetHostname][rtspProxyPort] = targetRtspPort;
                    logger.trace(`Added RTSP proxy mapping: NVR=${targetHostname}, ProxyPort=${rtspProxyPort}, TargetPort=${targetRtspPort}`);
                }
                if (snapshotProxyPort && targetSnapshotPort && !proxies[targetHostname][snapshotProxyPort]) {
                    proxies[targetHostname][snapshotProxyPort] = targetSnapshotPort;
                    logger.trace(`Added Snapshot proxy mapping: NVR=${targetHostname}, ProxyPort=${snapshotProxyPort}, TargetPort=${targetSnapshotPort}`);
                }

            } else {
                // --- Log error if IP wasn't found for this MAC ---
                logger.error(`Failed to find IP address in map for MAC address ${onvifConfig.mac}. Skipping server for ${onvifConfig.name}.`);
                // Continue to the next camera instead of exiting
                continue;
            }
        }

        // Start TCP proxies after iterating through all cameras
        // This loop now correctly uses the 'proxies' map which contains the dynamically assigned ports
        for (let destinationAddress in proxies) {
            logger.info(`Setting up proxies for target NVR: ${destinationAddress}`);
            for (let sourcePort in proxies[destinationAddress]) {
                const targetPort = proxies[destinationAddress][sourcePort];
                // Determine if it's RTSP or Snapshot based on port number for logging
                const proxyType = (Number(sourcePort) % 2 === 0 && Number(sourcePort) < 8580) ? "RTSP" : "Snapshot";
                logger.info(`  Starting ${proxyType} proxy: Port ${sourcePort} -> ${destinationAddress}:${targetPort}`);
                try {
                    // Ensure ports are numbers before passing to createProxy
                    tcpProxy.createProxy(Number(sourcePort), destinationAddress, Number(targetPort));
                    logger.info('    Started!');
                } catch (proxyErr) {
                    logger.error(`    Failed to start TCP proxy on port ${sourcePort}: ${proxyErr.message}`);
                }
            }
            logger.info(''); // Add newline after each NVR's proxy setup
        }

    } else {
        logger.error('Please specifiy a config filename!');
        return -1;
    }

    return 0;
}
