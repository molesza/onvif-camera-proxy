const fs = require('fs');
const yaml = require('yaml');
const { execSync } = require('child_process');

// Get all onv* interfaces with their MAC and IPv4 addresses
function getOnvifMacIpMap() {
    const map = {};
    const ipAddrLines = execSync('ip -o -4 addr show | grep "onv"').toString().split('\n');
    for (const line of ipAddrLines) {
        if (!line.trim()) continue;
        const parts = line.trim().split(/\s+/);
        const iface = parts[1];
        const ip = parts[3].split('/')[0];
        try {
            const macLine = execSync(`ip link show ${iface} | grep ether`).toString();
            const mac = macLine.trim().split(/\s+/)[1].toLowerCase();
            map[mac] = ip;
        } catch (e) {
            console.warn(`Could not get MAC for interface ${iface}`);
        }
    }
    return map;
}

// Update YAML config with dynamic hostnames
function updateConfigWithHostnames(configFile, macToIpMap, outputFile) {
    const configText = fs.readFileSync(configFile, 'utf8');
    const config = yaml.parse(configText);

    if (!Array.isArray(config.onvif)) {
        throw new Error('Invalid config: missing onvif array');
    }

    for (const cam of config.onvif) {
        if (cam.mac && macToIpMap[cam.mac.toLowerCase()]) {
            cam.hostname = macToIpMap[cam.mac.toLowerCase()];
        } else {
            console.warn(`No IP found for MAC ${cam.mac}, leaving hostname unchanged.`);
        }
    }

    const newYaml = yaml.stringify(config);
    fs.writeFileSync(outputFile, newYaml, 'utf8');
    console.log(`Updated config written to ${outputFile}`);
}

// Main
const args = process.argv.slice(2);
if (args.length < 2) {
    console.log('Usage: node generate-dynamic-config.js <input-config.yaml> <output-config.yaml>');
    process.exit(1);
}
const [inputConfig, outputConfig] = args;
const macToIp = getOnvifMacIpMap();
updateConfigWithHostnames(inputConfig, macToIp, outputConfig);