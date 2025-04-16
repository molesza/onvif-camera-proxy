const fs = require('fs');
const yaml = require('yaml');

// Read MAC-to-IP mapping from mac_to_interface.txt
function readMacToIpMap(filename) {
    const map = {};
    try {
        const lines = fs.readFileSync(filename, 'utf8').split('\n');
        for (const line of lines) {
            const parts = line.trim().split(/\s+/);
            if (parts.length === 3) {
                const [mac, iface, ip] = parts;
                map[mac.toLowerCase()] = ip;
            }
        }
    } catch (e) {
        console.error(`Error reading or parsing ${filename}: ${e.message}`);
    }
    return map;
}

// Read config and print IP + Resolution
function printResolutions(configFile, macToIpMap) {
    try {
        const configText = fs.readFileSync(configFile, 'utf8');
        const config = yaml.parse(configText);

        if (!config || !Array.isArray(config.onvif)) {
            console.error(`Invalid or missing 'onvif' array in ${configFile}`);
            return;
        }

        console.log("IP Address       - High Quality Resolution");
        console.log("-----------------------------------------");

        for (const cam of config.onvif) {
            const mac = cam.mac ? cam.mac.toLowerCase() : null;
            const ip = mac ? macToIpMap[mac] : 'N/A';
            let resolution = 'N/A';

            if (cam.highQuality && cam.highQuality.width && cam.highQuality.height) {
                resolution = `${cam.highQuality.width}x${cam.highQuality.height}`;
            }

            console.log(`${ip.padEnd(16)} - ${resolution}`);
        }
    } catch (e) {
        console.error(`Error reading or parsing ${configFile}: ${e.message}`);
    }
}

// --- Main ---
const macMapFile = 'mac_to_interface.txt';
const configFile = 'config-combined.yaml';

const macToIp = readMacToIpMap(macMapFile);
if (Object.keys(macToIp).length === 0) {
    console.error(`Could not load MAC-to-IP mapping from ${macMapFile}. Exiting.`);
    process.exit(1);
}

printResolutions(configFile, macToIp);