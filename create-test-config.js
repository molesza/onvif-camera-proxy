const configBuilder = require('./src/config-builder');

// Check if command line arguments are provided
if (process.argv.length < 5) {
  console.log('Usage: node create-test-config.js <hostname> <username> <password>');
  console.log('Example: node create-test-config.js 192.168.6.219 admin password');
  process.exit(1);
}

const hostname = process.argv[2];
const username = process.argv[3];
const password = process.argv[4];

console.log(`Creating test config for ${hostname} with one camera...`);

// Call the createTestConfig function
configBuilder.createTestConfig(hostname, username, password)
  .then(config => {
    if (config) {
      console.log('Test config created successfully!');
      console.log('You can now run:');
      console.log(`  sudo ./setup-network-test-${hostname}.sh`);
      console.log(`  node main.js config-test-${hostname}.yaml`);
    } else {
      console.error('Failed to create test config.');
    }
  })
  .catch(err => {
    console.error('Error creating test config:', err);
  });