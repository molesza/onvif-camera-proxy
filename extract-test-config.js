const fs = require('fs');
const yaml = require('yaml');
const path = require('path');

// Check if command line arguments are provided
if (process.argv.length < 3) {
  console.log('Usage: node extract-test-config.js <nvr-ip>');
  console.log('Example: node extract-test-config.js 192.168.6.219');
  process.exit(1);
}

const nvrIp = process.argv[2];
const sourceConfigFile = `config-${nvrIp}.yaml`;
const testConfigFile = `config-test-${nvrIp}.yaml`;
const testScriptFile = `setup-network-test-${nvrIp}.sh`;

console.log(`Creating test config for ${nvrIp} with one camera...`);

try {
  // Read the existing config file
  const configData = fs.readFileSync(sourceConfigFile, 'utf8');
  const config = yaml.parse(configData);
  
  if (!config || !config.onvif || !config.onvif.length) {
    console.error(`No cameras found in ${sourceConfigFile}`);
    process.exit(1);
  }
  
  // Create a new config with just the first camera
  const testConfig = {
    onvif: [config.onvif[0]]
  };
  
  // Save the test config
  fs.writeFileSync(testConfigFile, yaml.stringify(testConfig), 'utf8');
  console.log(`Test config saved to ${testConfigFile}`);
  
  // Create a network setup script for the test config
  const macAddress = testConfig.onvif[0].mac;
  // Generate a short interface name (max 15 chars)
  const shortMac = macAddress.replace(/:/g, '').slice(-4);
  const interfaceName = `onv1_${shortMac}`;
  
  let script = `#!/bin/bash\n\n`;
  script += `# Test network setup script for ONVIF virtual interface\n`;
  script += `# Generated for NVR: ${nvrIp} (test with one camera)\n`;
  script += `# Generated on: ${new Date().toISOString()}\n\n`;
  
  script += `# Get the physical interface name (look for the interface with the host IP)\n`;
  script += `HOST_IP=$(hostname -I | awk '{print $1}')\n`;
  script += `PHYS_IFACE=$(ip -o addr show | grep "$HOST_IP" | grep -v macvlan | awk '{print $2}' | cut -d':' -f1)\n`;
  script += `if [ -z "$PHYS_IFACE" ]; then\n`;
  script += `    echo "Error: Could not determine physical interface"\n`;
  script += `    exit 1\n`;
  script += `fi\n`;
  script += `echo "Using physical interface: $PHYS_IFACE"\n\n`;
  
  script += `# Check if dhclient is installed\n`;
  script += `if ! command -v dhclient &> /dev/null; then\n`;
  script += `    echo "dhclient not found. Please install it with:"\n`;
  script += `    echo "  sudo apt-get install isc-dhcp-client    (for Debian/Ubuntu)"\n`;
  script += `    echo "  sudo yum install dhcp-client            (for CentOS/RHEL)"\n`;
  script += `    exit 1\n`;
  script += `fi\n\n`;
  
  // Generate a static IP for the test interface
  const staticIp = `192.168.6.${2 + 1}`; // Use 192.168.6.3 for the test interface
  
  script += `# Create a mapping file for MAC to interface name and IP\n`;
  script += `cat > mac_to_interface.txt << EOF\n`;
  script += `${macAddress} ${interfaceName} ${staticIp}\n`;
  script += `EOF\n\n`;
  
  script += `# Parse command line arguments\n`;
  script += `USE_DHCP=true\n`;
  script += `while [[ "$#" -gt 0 ]]; do\n`;
  script += `    case $1 in\n`;
  script += `        --static) USE_DHCP=false ;;\n`;
  script += `        *) echo "Unknown parameter: $1"; exit 1 ;;\n`;
  script += `    esac\n`;
  script += `    shift\n`;
  script += `done\n\n`;
  
  script += `# Check if dhclient is installed when using DHCP\n`;
  script += `if [ "$USE_DHCP" = true ] && ! command -v dhclient &> /dev/null; then\n`;
  script += `    echo "dhclient not found. Please install it with:"\n`;
  script += `    echo "  sudo apt-get install isc-dhcp-client    (for Debian/Ubuntu)"\n`;
  script += `    echo "  sudo yum install dhcp-client            (for CentOS/RHEL)"\n`;
  script += `    echo "Or use --static to assign static IPs instead."\n`;
  script += `    exit 1\n`;
  script += `fi\n\n`;
  
  script += `# Remove any existing interface\n`;
  script += `ip link show ${interfaceName} > /dev/null 2>&1 && ip link delete ${interfaceName}\n\n`;
  
  script += `# Create new macvlan interface as specified in the README\n`;
  script += `echo "Creating macvlan interface ${interfaceName}..."\n`;
  script += `ip link add ${interfaceName} link $PHYS_IFACE address ${macAddress} type macvlan mode bridge\n`;
  script += `ip link set ${interfaceName} up\n`;
  
  script += `# Assign IP address based on mode\n`;
  script += `if [ "$USE_DHCP" = true ]; then\n`;
  script += `    echo "Requesting IP address for ${interfaceName} via DHCP..."\n`;
  script += `    dhclient -v ${interfaceName} &\n`;
  script += `else\n`;
  script += `    echo "Assigning static IP ${staticIp}/24 to ${interfaceName}..."\n`;
  script += `    ip addr add ${staticIp}/24 dev ${interfaceName}\n`;
  script += `fi\n`;
  
  script += `# Configure ARP to prevent issues with multiple interfaces\n`;
  script += `echo "Configuring ARP settings..."\n`;
  script += `echo 1 > /proc/sys/net/ipv4/conf/${interfaceName}/arp_ignore\n`;
  script += `echo 2 > /proc/sys/net/ipv4/conf/${interfaceName}/arp_announce\n\n`;
  
  script += `# Wait for IP assignment to complete and display IP address\n`;
  script += `sleep 3\n`;
  script += `echo "Virtual interface IP address:"\n`;
  script += `ip -4 addr show | grep -A 2 "${interfaceName}" | grep -v "valid_lft"\n`;
  
  script += `\necho "To use static IP addresses instead of DHCP, run: sudo $0 --static"\n`;
  
  // Save the network script
  fs.writeFileSync(testScriptFile, script, 'utf8');
  fs.chmodSync(testScriptFile, '0755'); // Make executable
  console.log(`Test network setup script saved to ${testScriptFile}`);
  
  console.log('\nTo test with one camera:');
  console.log(`1. Run: sudo ./${testScriptFile}`);
  console.log(`2. Run: node main.js ${testConfigFile}`);
  
} catch (err) {
  console.error('Error creating test config:', err);
}