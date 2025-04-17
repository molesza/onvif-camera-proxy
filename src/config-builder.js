const soap = require('soap');
const uuid = require('node-uuid');
const fs = require('fs');
const yaml = require('yaml');
const path = require('path');
const crypto = require('crypto');

/**
 * Generates a unique MAC address for a camera
 * @param {string} nvrIp - The IP address of the NVR
 * @param {string} cameraId - Unique identifier for the camera
 * @returns {string} A MAC address in the format 02:XX:XX:XX:XX:XX
 */
function generateMacAddress(nvrIp, cameraId) {
    // Remove any port information from the IP
    const ipOnly = nvrIp.includes(':') ? nvrIp.substring(0, nvrIp.indexOf(':')) : nvrIp;
    
    // Create a hash from the IP and camera ID
    const hash = crypto.createHash('md5').update(`${ipOnly}-${cameraId}`).digest('hex');
    
    // Format as a MAC address (locally administered)
    // 02 prefix indicates a locally administered unicast MAC address
    return `02:${hash.substring(0, 2)}:${hash.substring(2, 4)}:${hash.substring(4, 6)}:${hash.substring(6, 8)}:${hash.substring(8, 10)}`;
}

/**
 * Generates a shell script to set up virtual network interfaces
 * @param {Object} config - The ONVIF configuration object
 * @param {string} nvrIp - The IP address of the NVR
 * @returns {string} Shell script content
 */
/**
 * Generates a short interface name from a MAC address
 * @param {string} mac - MAC address
 * @param {number} index - Camera index for uniqueness
 * @returns {string} Short interface name (max 15 chars)
 */
function generateShortInterfaceName(mac, index) {
    // Extract last 4 chars of MAC (without colons)
    const shortMac = mac.replace(/:/g, '').slice(-4);
    // Create a name like "onv1_1234" (10 chars)
    return `onv${index}_${shortMac}`;
}

/**
 * Generates a static IP address for a virtual interface
 * @param {number} index - Camera index for uniqueness
 * @returns {string} Static IP address in the range 192.168.6.2 - 192.168.6.200
 */
function generateStaticIp(index) {
    // Use 2 + index as the last octet, ensuring we stay within the allowed range
    const lastOctet = 2 + index;
    if (lastOctet > 200) {
        console.warn(`Warning: IP address 192.168.6.${lastOctet} is outside the allowed range`);
    }
    return `192.168.6.${lastOctet}`;
}

function generateNetworkScript(config, nvrIp) {
    // Get the physical interface name once at the beginning
    let script = `#!/bin/bash\n\n` +
                `# Network setup script for ONVIF virtual interfaces\n` +
                `# Generated for NVR: ${nvrIp}\n` +
                `# Generated on: ${new Date().toISOString()}\n\n` +
                
                `# Get the physical interface name (look for the interface with the host IP)\n` +
                `HOST_IP=$(hostname -I | awk '{print $1}')\n` +
                `PHYS_IFACE=$(ip -o addr show | grep "$HOST_IP" | grep -v macvlan | awk '{print $2}' | cut -d':' -f1)\n` +
                `if [ -z "$PHYS_IFACE" ]; then\n` +
                `    echo "Error: Could not determine physical interface"\n` +
                `    exit 1\n` +
                `fi\n` +
                `echo "Using physical interface: $PHYS_IFACE"\n` +
                `# Configure ARP settings for physical interface\n` +
                `echo "Configuring ARP settings for physical interface $PHYS_IFACE..."\n` +
                `echo 1 > /proc/sys/net/ipv4/conf/$PHYS_IFACE/arp_ignore\n` +
                `echo 2 > /proc/sys/net/ipv4/conf/$PHYS_IFACE/arp_announce\n\n` +
                
                `# Parse command line arguments\n` +
                `USE_DHCP=false # Default to static IPs\n` +
                `while [[ "$#" -gt 0 ]]; do\n` +
                `    case $1 in\n` +
                `        --dhcp) USE_DHCP=true ;;\n` +
                `        *) echo "Unknown parameter: $1"; exit 1 ;;\n` +
                `    esac\n` +
                `    shift\n` +
                `done\n\n` +
                
                `# Check if dhclient is installed when using DHCP\n` +
                `if [ "$USE_DHCP" = true ] && ! command -v dhclient &> /dev/null; then\n` +
                `    echo "dhclient not found. Please install it with:"\n` +
                `    echo "  sudo apt-get install isc-dhcp-client    (for Debian/Ubuntu)"\n` +
                `    echo "  sudo yum install dhcp-client            (for CentOS/RHEL)"\n` +
                `    echo "Or use --static to assign static IPs instead."\n` +
                `    exit 1\n` +
                `fi\n\n`;
    
    script += `# Create a mapping file for MAC to interface name and IP\n`;
    script += `cat > mac_to_interface.txt << EOF\n`;
    
    // Add MAC to interface mapping
    let index = 1;
    for (const camera of config.onvif) {
        const macAddress = camera.mac;
        const interfaceName = generateShortInterfaceName(macAddress, index);
        const staticIp = generateStaticIp(index);
        script += `${macAddress} ${interfaceName} ${staticIp}\n`;
        index++;
    }
    script += `EOF\n\n`;
    
    script += `# Remove any existing interfaces first\n`;
    
    // Add commands to remove existing interfaces
    index = 1;
    for (const camera of config.onvif) {
        const macAddress = camera.mac;
        const interfaceName = generateShortInterfaceName(macAddress, index);
        script += `ip link show ${interfaceName} > /dev/null 2>&1 && ip link delete ${interfaceName}\n`;
        index++;
    }
    
    script += `\n# Create new virtual interfaces\n`;
    
    // Add commands to create new interfaces
    index = 1;
    for (const camera of config.onvif) {
        const macAddress = camera.mac;
        const interfaceName = generateShortInterfaceName(macAddress, index);
        const staticIp = generateStaticIp(index);
        
        // Create macvlan interface as specified in the README
        script += `echo "Creating macvlan interface ${interfaceName}..."\n`;
        script += `ip link add ${interfaceName} link $PHYS_IFACE address ${macAddress} type macvlan mode bridge\n`;
        script += `ip link set ${interfaceName} up\n`;
        
        // Add conditional IP assignment based on mode
        script += `if [ "$USE_DHCP" = true ]; then\n`;
        script += `    echo "Requesting IP address for ${interfaceName} via DHCP..."\n`;
        script += `    dhclient -v ${interfaceName} &\n`;
        script += `else\n`;
        script += `    echo "Assigning static IP ${staticIp}/24 to ${interfaceName}..."\n`;
        script += `    ip addr add ${staticIp}/24 dev ${interfaceName}\n`;
        script += `fi\n\n`;
        
        // Add ARP configuration as mentioned in the README troubleshooting section
        script += `# Configure ARP to prevent issues with multiple interfaces\n`;
        script += `echo "Configuring ARP settings..."\n`;
        script += `echo 1 > /proc/sys/net/ipv4/conf/${interfaceName}/arp_ignore\n`;
        script += `echo 2 > /proc/sys/net/ipv4/conf/${interfaceName}/arp_announce\n\n`;
        
        index++;
    }
    
    script += `# Wait for IP assignment to complete and display IP addresses\n`;
    script += `sleep 3\n`;
    script += `echo "Virtual interface IP addresses:"\n`;
    script += `ip -4 addr show | grep -A 2 "onv" | grep -v "valid_lft"\n`;
    
    script += `\necho "Static IP assignment is the default. To use DHCP instead, run: sudo $0 --dhcp"\n`;
    
    return script;
}

function extractPath(url) {
    // Add a check for null/undefined url
    if (!url) return '';
    const protocolSeparatorIndex = url.indexOf('//');
    if (protocolSeparatorIndex === -1) return url; // Handle cases without protocol? Or assume http/rtsp?
    const pathStartIndex = url.indexOf('/', protocolSeparatorIndex + 2);
    if (pathStartIndex === -1) return '/'; // Root path if nothing else
    return url.substr(pathStartIndex);
}

async function createConfig(hostname, username, password) {
    let options = {
        forceSoap12Headers: true
    };

    let securityOptions = {
        hasNonce: true,
        passwordType: 'PasswordDigest'
    };

    let client = await soap.createClientAsync('./wsdl/media_service.wsdl', options);
    // Ensure endpoint uses http, construct carefully
    const endpoint = `http://${hostname.includes(':') ? hostname.substring(0, hostname.indexOf(':')) : hostname}/onvif/device_service`;
    client.setEndpoint(endpoint); // Use calculated endpoint
    client.setSecurity(new soap.WSSecurity(username, password, securityOptions));

    let hostport = 80; // Default HTTP port
    let targetHostname = hostname;
    if (hostname.includes(':')) {
        const parts = hostname.split(':');
        targetHostname = parts[0];
        // Attempt to parse port, default if invalid
        const parsedPort = parseInt(parts[1], 10);
        hostport = !isNaN(parsedPort) ? parsedPort : 80;
    }

    let cameras = {};

    try {
        let profilesResponse = await client.GetProfilesAsync({});
        // Check if Profiles exist and is an array
        let profiles = profilesResponse && profilesResponse[0] && Array.isArray(profilesResponse[0].Profiles) ? profilesResponse[0].Profiles : [];

        for (let profile of profiles) {
            // Ensure profile structure is somewhat valid before proceeding
            if (!profile || !profile.VideoSourceConfiguration || !profile.VideoSourceConfiguration.SourceToken || !profile.attributes || !profile.attributes.token) {
                console.warn('Skipping incomplete profile:', JSON.stringify(profile));
                continue;
            }

            let videoSource = profile.VideoSourceConfiguration.SourceToken;

            if (!cameras[videoSource])
                cameras[videoSource] = [];

            let snapshotUri = null;
            try {
                let snapshotUriResponse = await client.GetSnapshotUriAsync({
                    ProfileToken: profile.attributes.token
                });
                 // Check response structure before accessing Uri
                snapshotUri = snapshotUriResponse && snapshotUriResponse[0] && snapshotUriResponse[0].MediaUri && snapshotUriResponse[0].MediaUri.Uri
                                ? snapshotUriResponse[0].MediaUri.Uri
                                : null; // Default to null if structure is wrong
            } catch (snapErr) {
                console.warn(`Could not get Snapshot URI for profile ${profile.attributes.token}:`, snapErr.message || snapErr);
                // Keep snapshotUri as null
            }


            let streamUri = null;
            try {
                let streamUriResponse = await client.GetStreamUriAsync({
                    StreamSetup: {
                        Stream: 'RTP-Unicast',
                        Transport: {
                            Protocol: 'RTSP'
                        }
                    },
                    ProfileToken: profile.attributes.token
                });
                 // Check response structure before accessing Uri
                streamUri = streamUriResponse && streamUriResponse[0] && streamUriResponse[0].MediaUri && streamUriResponse[0].MediaUri.Uri
                            ? streamUriResponse[0].MediaUri.Uri
                            : null; // Default to null if structure is wrong
            } catch (streamErr) {
                console.warn(`Could not get Stream URI for profile ${profile.attributes.token}:`, streamErr.message || streamErr);
                 // Keep streamUri as null
            }


            // Assign URIs to profile *only if they were successfully fetched*
            if (streamUri) profile.streamUri = streamUri;
            if (snapshotUri) profile.snapshotUri = snapshotUri;

            cameras[videoSource].push(profile);
        }
    } catch (err) {
        if (err.root && err.root.Envelope && err.root.Envelope.Body && err.root.Envelope.Body.Fault && err.root.Envelope.Body.Fault.Reason && err.root.Envelope.Body.Fault.Reason.Text && err.root.Envelope.Body.Fault.Reason.Text['$value'])
            throw new Error(`ONVIF Error: ${err.root.Envelope.Body.Fault.Reason.Text['$value']}`); // Throw standard Error object
        // Throw standard Error object for other cases too
        throw new Error(`ONVIF Communication Error: ${err.message || err}`);
    }

    let config = {
        onvif: []
    };

    let serverPort = 8081;
    for (let camera in cameras) {
        if (!cameras[camera] || cameras[camera].length === 0) {
            console.warn(`Skipping camera source ${camera} due to no valid profiles.`);
            continue;
        }

        let mainStream = cameras[camera][0];
        let subStream = cameras[camera].length > 1 ? cameras[camera][1] : cameras[camera][0]; // Fallback to main if only one exists

        let swapStreams = false;
        // Use optional chaining and default values (e.g., 0) for comparison
        const mainQuality = mainStream?.VideoEncoderConfiguration?.Quality ?? 0;
        const subQuality = subStream?.VideoEncoderConfiguration?.Quality ?? 0;
        const mainWidth = mainStream?.VideoEncoderConfiguration?.Resolution?.Width ?? 0;
        const subWidth = subStream?.VideoEncoderConfiguration?.Resolution?.Width ?? 0;

        if (subQuality > mainQuality) {
            swapStreams = true;
        } else if (subQuality === mainQuality) {
            if (subWidth > mainWidth) {
                swapStreams = true;
            }
        }

        if (swapStreams) {
            let tempStream = subStream;
            subStream = mainStream;
            mainStream = tempStream;
        }

        // Use optional chaining and default values (0 or '') when building config
        let cameraConfig = {
            mac: generateMacAddress(targetHostname, `${camera}-${serverPort}`), // Generate unique MAC
            ports: {
                server: serverPort,
                rtsp: 8554,
                snapshot: 8580
            },
            // Use profile name if available, otherwise fallback
            name: mainStream?.VideoSourceConfiguration?.Name ?? `Camera_${camera}_Main`,
            uuid: uuid.v4(),
            highQuality: {
                // Use extractPath only if streamUri/snapshotUri exist
                rtsp: mainStream?.streamUri ? extractPath(mainStream.streamUri) : '',
                snapshot: mainStream?.snapshotUri ? extractPath(mainStream.snapshotUri) : '',
                width: mainStream?.VideoEncoderConfiguration?.Resolution?.Width ?? 0,
                height: mainStream?.VideoEncoderConfiguration?.Resolution?.Height ?? 0,
                framerate: mainStream?.VideoEncoderConfiguration?.RateControl?.FrameRateLimit ?? 0,
                bitrate: mainStream?.VideoEncoderConfiguration?.RateControl?.BitrateLimit ?? 0,
                quality: 4.0 // Keep fixed quality indicator
            },
            lowQuality: {
                // Use extractPath only if streamUri/snapshotUri exist
                rtsp: subStream?.streamUri ? extractPath(subStream.streamUri) : '',
                snapshot: subStream?.snapshotUri ? extractPath(subStream.snapshotUri) : '',
                width: subStream?.VideoEncoderConfiguration?.Resolution?.Width ?? 0,
                height: subStream?.VideoEncoderConfiguration?.Resolution?.Height ?? 0,
                framerate: subStream?.VideoEncoderConfiguration?.RateControl?.FrameRateLimit ?? 0,
                bitrate: subStream?.VideoEncoderConfiguration?.RateControl?.BitrateLimit ?? 0,
                quality: 1.0 // Keep fixed quality indicator
            },
            target: {
                hostname: targetHostname, // Use parsed hostname
                ports: {
                    rtsp: 554, // Standard RTSP port
                    snapshot: hostport // Use port from input hostname or default 80
                }
            }
        };

        config.onvif.push(cameraConfig);
        serverPort++;
    }

    return config;
}

/**
 * Merges multiple ONVIF configs into a single config
 * @param {Array} configs - Array of config objects to merge
 * @returns {Object} Merged config
 */
function mergeConfigs(configs) {
    // Start with an empty config
    let mergedConfig = {
        onvif: []
    };
    
    // Track MAC addresses to avoid duplicates
    const macAddresses = new Set();
    
    // Track which cameras we're adding/updating for logging
    let added = 0;
    let skipped = 0;
    let updated = 0;
    
    // Add onvif entries from all configs, avoiding duplicates
    for (const config of configs) {
        if (config && config.onvif && Array.isArray(config.onvif)) {
            for (const camera of config.onvif) {
                if (!camera.mac) {
                    console.warn('Skipping camera without MAC address');
                    skipped++;
                    continue;
                }

                const existingIndex = mergedConfig.onvif.findIndex(c => c.mac === camera.mac);
                if (existingIndex === -1) {
                    // New camera
                    if (!macAddresses.has(camera.mac)) {
                        macAddresses.add(camera.mac);
                        mergedConfig.onvif.push({...camera}); // Clone to avoid reference issues
                        added++;
                        console.log(`Added new camera: ${camera.name} (MAC: ${camera.mac})`);
                    }
                } else {
                    // Update existing camera
                    mergedConfig.onvif[existingIndex] = {...camera}; // Clone and replace
                    updated++;
                    console.log(`Updated existing camera: ${camera.name} (MAC: ${camera.mac})`);
                }
            }
        }
    }
    
    console.log(`Merged config summary:`);
    console.log(`- Added: ${added} new cameras`);
    console.log(`- Updated: ${updated} existing cameras`);
    console.log(`- Skipped: ${skipped} invalid entries`);
    console.log(`Total cameras in merged config: ${mergedConfig.onvif.length}`);
    
    return mergedConfig;
}

/**
 * Generates a combined network setup script for multiple NVRs
 * @param {Array} configs - Array of config objects
 * @param {Array} ipAddresses - Array of IP addresses corresponding to configs
 * @returns {string} Combined shell script
 */
function generateCombinedNetworkScript(configs, ipAddresses) {
    let script = `#!/bin/bash\n\n`;
    script += `# Combined network setup script for multiple ONVIF virtual interfaces\n`;
    script += `# Generated for NVRs: ${ipAddresses.join(', ')}\n`;
    script += `# Generated on: ${new Date().toISOString()}\n\n`;
    
    // Remove argument parsing and DHCP check for combined script - always static
    // script += `# Parse command line arguments\n`;
    // script += `USE_DHCP=false # Default to static IPs\n`;
    // script += `while [[ "$#" -gt 0 ]]; do\n`;
    // script += `    case $1 in\n`;
    // script += `        --dhcp) USE_DHCP=true ;;\n`;
    // script += `        *) echo "Unknown parameter: $1"; exit 1 ;;\n`;
    // script += `    esac\n`;
    // script += `    shift\n`;
    // script += `done\n\n`;
    
    // script += `# Check if dhclient is installed when using DHCP\n`;
    // script += `if [ "$USE_DHCP" = true ] && ! command -v dhclient &> /dev/null; then\n`;
    // script += `    echo "dhclient not found. Please install it with:"\n`;
    // script += `    echo "  sudo apt-get install isc-dhcp-client    (for Debian/Ubuntu)"\n`;
    // script += `    echo "  sudo yum install dhcp-client            (for CentOS/RHEL)"\n`;
    // script += `    echo "Or use --static to assign static IPs instead."\n`;
    // script += `    exit 1\n`;
    // script += `fi\n\n`;
    
    // Get the physical interface name once at the beginning
    // NOTE: This duplicates the initial script setup - ensure consistency if changed above
    script = `#!/bin/bash\n\n` +
             `# Combined network setup script for multiple ONVIF virtual interfaces\n` +
             `# Generated for NVRs: ${ipAddresses.join(', ')}\n` +
             `# Generated on: ${new Date().toISOString()}\n\n` +
             
             `# Get the physical interface name (look for the interface with the host IP)\n` +
             `HOST_IP=$(hostname -I | awk '{print $1}')\n` +
             `PHYS_IFACE=$(ip -o addr show | grep "$HOST_IP" | grep -v macvlan | awk '{print $2}' | cut -d':' -f1)\n` +
             `if [ -z "$PHYS_IFACE" ]; then\n` +
             `    echo "Error: Could not determine physical interface"\n` +
             `    exit 1\n` +
             `fi\n` +
             `echo "Using physical interface: $PHYS_IFACE"\n` +
             `# Configure ARP settings for physical interface\n` +
             `echo "Configuring ARP settings for physical interface $PHYS_IFACE..."\n` +
             `echo 1 > /proc/sys/net/ipv4/conf/$PHYS_IFACE/arp_ignore\n` +
             `echo 2 > /proc/sys/net/ipv4/conf/$PHYS_IFACE/arp_announce\n\n`;
             
             // Remove argument parsing - combined script is always static
             //`# Parse command line arguments\n` +
             //`USE_DHCP=true\n` + // This was incorrect, should have been false if kept
             //`while [[ "$#" -gt 0 ]]; do\n` +
             //`    case $1 in\n` +
             //`        --static) USE_DHCP=false ;;\n` + // This logic was for the single script
             //`        *) echo "Unknown parameter: $1"; exit 1 ;;\n` +
             //`    esac\n` +
             //`    shift\n` +
             //`done\n\n`;
    
    script += `# Create a mapping file for MAC to interface name and IP\n`;
    script += `cat > mac_to_interface.txt << EOF\n`;
    
    // Add MAC to interface mapping
    let globalIndex = 1;
    for (const config of configs) {
        if (config && config.onvif && Array.isArray(config.onvif)) {
            for (const camera of config.onvif) {
                const macAddress = camera.mac;
                const interfaceName = generateShortInterfaceName(macAddress, globalIndex);
                const staticIp = generateStaticIp(globalIndex);
                script += `${macAddress} ${interfaceName} ${staticIp}\n`;
                globalIndex++;
            }
        }
    }
    script += `EOF\n\n`;
    
    script += `# Remove any existing interfaces first\n`;
    
    // Add commands to remove existing interfaces from all configs
    globalIndex = 1;
    for (const config of configs) {
        if (config && config.onvif && Array.isArray(config.onvif)) {
            for (const camera of config.onvif) {
                const macAddress = camera.mac;
                const interfaceName = generateShortInterfaceName(macAddress, globalIndex);
                script += `ip link show ${interfaceName} > /dev/null 2>&1 && ip link delete ${interfaceName}\n`;
                globalIndex++;
            }
        }
    }
    
    script += `\n# Create new virtual interfaces\n`;
    
    // Add helper function for interface verification
    script += `# Helper function to verify interface creation and IP assignment\n`;
    script += `verify_interface() {\n`;
    script += `    local iface=$1\n`;
    script += `    local ip=$2\n`;
    script += `    local max_attempts=30\n`;
    script += `    local delay=0.5\n`;
    script += `    local attempt=1\n\n`;
    
    script += `    echo "Verifying interface $iface with IP $ip..."\n\n`;
    
    script += `    # First verify the interface exists\n`;
    script += `    while [ $attempt -le $max_attempts ]; do\n`;
    script += `        if ip link show $iface &>/dev/null; then\n`;
    script += `            echo "  Interface $iface exists. Checking IP address..."\n`;
    script += `            break\n`;
    script += `        fi\n`;
    script += `        echo "  Waiting for interface $iface to be created (attempt $attempt/$max_attempts)"\n`;
    script += `        sleep $delay\n`;
    script += `        attempt=$((attempt+1))\n`;
    script += `    done\n\n`;
    
    script += `    if ! ip link show $iface &>/dev/null; then\n`;
    script += `        echo "  ERROR: Interface $iface could not be created after $max_attempts attempts!"\n`;
    script += `        return 1\n`;
    script += `    fi\n\n`;
    
    script += `    # Now verify IP address is assigned\n`;
    script += `    attempt=1\n`;
    script += `    while [ $attempt -le $max_attempts ]; do\n`;
    script += `        if ip addr show $iface | grep -q "$ip"; then\n`;
    script += `            echo "  Success: Interface $iface has IP address $ip"\n`;
    script += `            return 0\n`;
    script += `        fi\n`;
    script += `        echo "  Waiting for IP $ip to be assigned to $iface (attempt $attempt/$max_attempts)"\n`;
    script += `        sleep $delay\n`;
    script += `        attempt=$((attempt+1))\n`;
    script += `    done\n\n`;
    
    script += `    echo "  ERROR: IP address $ip could not be assigned to $iface after $max_attempts attempts!"\n`;
    script += `    return 1\n`;
    script += `}\n\n`;
    
    // Add commands to create new interfaces from all configs
    globalIndex = 1;
    for (const config of configs) {
        if (config && config.onvif && Array.isArray(config.onvif)) {
            for (const camera of config.onvif) {
                const macAddress = camera.mac;
                const interfaceName = generateShortInterfaceName(macAddress, globalIndex);
                const staticIp = generateStaticIp(globalIndex);
                
                // Create macvlan interface as specified in the README
                script += `echo "Creating interface ${globalIndex}/${configs.reduce((count, c) => count + (c?.onvif?.length || 0), 0)}: ${interfaceName}"\n`;
                script += `ip link add ${interfaceName} link $PHYS_IFACE address ${macAddress} type macvlan mode bridge\n`;
                script += `ip link set ${interfaceName} up\n`;
                
                script += `echo "Assigning static IP ${staticIp}/24 to ${interfaceName}..."\n`;
                script += `ip addr add ${staticIp}/24 dev ${interfaceName}\n`;
                
                // Add ARP configuration
                script += `echo 1 > /proc/sys/net/ipv4/conf/${interfaceName}/arp_ignore\n`;
                script += `echo 2 > /proc/sys/net/ipv4/conf/${interfaceName}/arp_announce\n\n`;
                
                // Verify interface creation and IP assignment
                script += `verify_interface ${interfaceName} ${staticIp}\n`;
                script += `if [ $? -ne 0 ]; then\n`;
                script += `    echo "WARNING: Interface ${interfaceName} or IP ${staticIp} verification failed. Manual check recommended."\n`;
                script += `fi\n\n`;
                
                // Add a small delay between interface creations to prevent race conditions
                script += `sleep 0.1\n\n`;
                
                globalIndex++;
            }
        }
    }
    
    script += `echo "Network interface setup complete."\n`;
    script += `echo "Virtual interface IP addresses:"\n`;
    script += `ip -4 addr show | grep -A 2 "onv" | grep -v "valid_lft"\n`;
    
    // Remove echo about switching modes
    // script += `\necho "Static IP assignment is the default. To use DHCP instead, run: sudo $0 --dhcp"\n`;
    
    return script;
}

/**
 * Loads existing config from a file if it exists
 * @param {string} filename - Path to the config file
 * @returns {Object|null} Loaded config or null if file doesn't exist
 */
function loadExistingConfig(filename) {
    try {
        if (fs.existsSync(filename)) {
            const configData = fs.readFileSync(filename, 'utf8');
            return yaml.parse(configData);
        }
    } catch (err) {
        console.warn(`Could not load existing config from ${filename}:`, err.message);
    }
    return null;
}

/**
 * Creates a test config with just one camera from an NVR
 * @param {string} hostname - The hostname or IP of the NVR
 * @param {string} username - The username for the NVR
 * @param {string} password - The password for the NVR
 * @returns {Object|null} Test config with one camera or null if failed
 */
async function createTestConfig(hostname, username, password) {
    let config = null;
    try {
        // Get the full config first
        const fullConfig = await createConfig(hostname, username, password);
        
        if (fullConfig && fullConfig.onvif && fullConfig.onvif.length > 0) {
            // Create a new config with just the first camera
            config = {
                onvif: [fullConfig.onvif[0]]
            };
            
            // Extract IP address without port for filename
            const ipAddress = hostname.includes(':')
                ? hostname.substring(0, hostname.indexOf(':'))
                : hostname;
            
            // Create filenames
            const testConfigFilename = `config-test-${ipAddress}.yaml`;
            const testScriptFilename = `setup-network-test-${ipAddress}.sh`;
            
            // Save test config to YAML file
            fs.writeFileSync(testConfigFilename, yaml.stringify(config), 'utf8');
            console.log(`Test config with one camera saved to ${testConfigFilename}`);
            
            // Generate and save test network setup script
            const networkScript = generateNetworkScript(config, ipAddress);
            fs.writeFileSync(testScriptFilename, networkScript, 'utf8');
            fs.chmodSync(testScriptFilename, '0755'); // Make executable
            console.log(`Test network setup script saved to ${testScriptFilename}`);
        } else {
            console.error("Could not create test config: No cameras found in the full config");
        }
    } catch (err) {
        console.error("Error creating test config:", err);
    }
    
    return config;
};

async function createConfigWrapper(hostname, username, password) { // Renamed to avoid conflict with internal createConfig
    let config = null; // Initialize config to null
    try {
        config = await createConfig(hostname, username, password);
        
        if (config) {
            // Extract IP address without port for filename
            const ipAddress = hostname.includes(':')
                ? hostname.substring(0, hostname.indexOf(':'))
                : hostname;
            
            // Create filenames
            const individualConfigFilename = `config-${ipAddress}.yaml`;
            const combinedConfigFilename = `config-combined.yaml`;
            const individualScriptFilename = `setup-network-${ipAddress}.sh`;
            const combinedScriptFilename = `setup-network-combined.sh`;
            
            // Save individual config to YAML file
            fs.writeFileSync(individualConfigFilename, yaml.stringify(config), 'utf8');
            console.log(`Individual config saved to ${individualConfigFilename}`);
            
            // Generate and save individual network setup script
            const networkScript = generateNetworkScript(config, ipAddress);
            fs.writeFileSync(individualScriptFilename, networkScript, 'utf8');
            fs.chmodSync(individualScriptFilename, '0755'); // Make executable
            console.log(`Individual network setup script saved to ${individualScriptFilename}`);
            
            // Create or update combined config
            let combinedConfig;
            const existingCombinedConfig = loadExistingConfig(combinedConfigFilename);
            
            if (existingCombinedConfig) {
                // Merge with existing config
                combinedConfig = mergeConfigs([existingCombinedConfig, config]);
                console.log(`Merged new config with existing combined config`);
            } else {
                // Start a new combined config
                combinedConfig = config;
                console.log(`Created new combined config`);
            }
            
            // Save combined config with better error handling
            try {
                const combinedYaml = yaml.stringify(combinedConfig);
                // First write to a temporary file
                const tempFile = `${combinedConfigFilename}.tmp`;
                fs.writeFileSync(tempFile, combinedYaml, 'utf8');
                // Then rename to actual file (atomic operation)
                fs.renameSync(tempFile, combinedConfigFilename);
                console.log(`Combined config successfully saved to ${combinedConfigFilename}`);
                // Log the number of cameras in the combined config
                console.log(`Total cameras in combined config: ${combinedConfig.onvif.length}`);
            } catch (writeErr) {
                console.error(`Failed to save combined config: ${writeErr.message}`);
                throw writeErr; // Re-throw to trigger error handling
            }
            
            // Create combined network script
            // First, find all individual config files
            const configFiles = fs.readdirSync('.').filter(file =>
                file.startsWith('config-') &&
                file.endsWith('.yaml') &&
                !file.startsWith('config-test-') && // Exclude test configs
                file !== combinedConfigFilename
            );
            
            const configs = [];
            const ipAddresses = [];
            
            // Load all individual configs
            for (const file of configFiles) {
                const config = loadExistingConfig(file);
                if (config) {
                    configs.push(config);
                    // Extract IP from filename (format: config-192.168.0.219.yaml)
                    const ipMatch = file.match(/config-(.+)\.yaml/);
                    if (ipMatch && ipMatch[1]) {
                        ipAddresses.push(ipMatch[1]);
                    }
                }
            }
            
            // Generate combined network script
            const combinedScript = generateCombinedNetworkScript(configs, ipAddresses);
            fs.writeFileSync(combinedScriptFilename, combinedScript, 'utf8');
            fs.chmodSync(combinedScriptFilename, '0755'); // Make executable
            console.log(`Combined network setup script saved to ${combinedScriptFilename}`);
        }
    } catch (err) {
        console.error("Error during initial config creation attempt:");
        console.error(err); // Log the full error object/message

        // Check if the error message contains the time check failure string
        if (err && typeof err.message === 'string' && err.message.includes('time check failed')) {
            console.log('Time check failed, attempting retry with adjusted time...');

            // Temporarily adjust time (Note: This is a workaround and might have side effects)
            var originalGetUTCHours = Date.prototype.getUTCHours;
            var utcHours = (new Date()).getUTCHours();
            Date.prototype.getUTCHours = function() {
                // Adjust by +1 hour, consider wrapping around 23->0 if needed, though unlikely to be the exact fix boundary
                 return (utcHours + 1) % 24;
            };

            try {
                config = await createConfig(hostname, username, password);
                console.log("Retry attempt successful.");
                
                if (config) {
                    // Extract IP address without port for filename
                    const ipAddress = hostname.includes(':')
                        ? hostname.substring(0, hostname.indexOf(':'))
                        : hostname;
                    
                    // Create filenames
                    const individualConfigFilename = `config-${ipAddress}.yaml`;
                    const combinedConfigFilename = `config-combined.yaml`;
                    const individualScriptFilename = `setup-network-${ipAddress}.sh`;
                    const combinedScriptFilename = `setup-network-combined.sh`;
                    
                    // Save individual config to YAML file
                    fs.writeFileSync(individualConfigFilename, yaml.stringify(config), 'utf8');
                    console.log(`Individual config saved to ${individualConfigFilename}`);
                    
                    // Generate and save individual network setup script
                    const networkScript = generateNetworkScript(config, ipAddress);
                    fs.writeFileSync(individualScriptFilename, networkScript, 'utf8');
                    fs.chmodSync(individualScriptFilename, '0755'); // Make executable
                    console.log(`Individual network setup script saved to ${individualScriptFilename}`);
                    
                    // Create or update combined config
                    let combinedConfig;
                    const existingCombinedConfig = loadExistingConfig(combinedConfigFilename);
                    
                    if (existingCombinedConfig) {
                        // Merge with existing config
                        combinedConfig = mergeConfigs([existingCombinedConfig, config]);
                        console.log(`Merged new config with existing combined config`);
                    } else {
                        // Start a new combined config
                        combinedConfig = config;
                        console.log(`Created new combined config`);
                    }
                    
                    // Save combined config with better error handling
                    try {
                        const combinedYaml = yaml.stringify(combinedConfig);
                        // First write to a temporary file
                        const tempFile = `${combinedConfigFilename}.tmp`;
                        fs.writeFileSync(tempFile, combinedYaml, 'utf8');
                        // Then rename to actual file (atomic operation)
                        fs.renameSync(tempFile, combinedConfigFilename);
                        console.log(`Combined config successfully saved to ${combinedConfigFilename}`);
                        // Log the number of cameras in the combined config
                        console.log(`Total cameras in combined config: ${combinedConfig.onvif.length}`);
                    } catch (writeErr) {
                        console.error(`Failed to save combined config: ${writeErr.message}`);
                        throw writeErr; // Re-throw to trigger error handling
                    }
                    
            // Create combined network script
            // First, find all individual config files
            const configFiles = fs.readdirSync('.').filter(file =>
                file.startsWith('config-') &&
                file.endsWith('.yaml') &&
                !file.startsWith('config-test-') && // Exclude test configs
                file !== combinedConfigFilename
            );
                    
                    const configs = [];
                    const ipAddresses = [];
                    
                    // Load all individual configs
                    for (const file of configFiles) {
                        const config = loadExistingConfig(file);
                        if (config) {
                            configs.push(config);
                            // Extract IP from filename (format: config-192.168.0.219.yaml)
                            const ipMatch = file.match(/config-(.+)\.yaml/);
                            if (ipMatch && ipMatch[1]) {
                                ipAddresses.push(ipMatch[1]);
                            }
                        }
                    }
                    
                    // Generate combined network script
                    const combinedScript = generateCombinedNetworkScript(configs, ipAddresses);
                    fs.writeFileSync(combinedScriptFilename, combinedScript, 'utf8');
                    fs.chmodSync(combinedScriptFilename, '0755'); // Make executable
                    console.log(`Combined network setup script saved to ${combinedScriptFilename}`);
                }
            } catch (retryErr) {
                console.error("Error during retry attempt:");
                console.error(retryErr); // Log the error from the retry
            } finally {
                 // IMPORTANT: Restore original function
                Date.prototype.getUTCHours = originalGetUTCHours;
            }
        } else {
             // Log that it's not the time check error we were looking for
             console.error("Caught error was not the 'time check failed' error, no retry performed for this reason.");
        }
    }

    return config; // Return config (which might be null if all attempts failed)
}

// Export necessary functions
exports.createConfig = createConfigWrapper; // Use the wrapper that creates files
exports.createTestConfig = createTestConfig;
exports.generateNetworkScript = generateNetworkScript;
exports.generateCombinedNetworkScript = generateCombinedNetworkScript;
exports.generateStaticIp = generateStaticIp; // Add this export
