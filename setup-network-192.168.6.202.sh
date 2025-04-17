#!/bin/bash

# Network setup script for ONVIF virtual interfaces
# Generated for NVR: 192.168.6.202
# Generated on: 2025-04-17T14:43:32.719Z

# Get the physical interface name (look for the interface with the host IP)
HOST_IP=$(hostname -I | awk '{print $1}')
PHYS_IFACE=$(ip -o addr show | grep "$HOST_IP" | grep -v macvlan | awk '{print $2}' | cut -d':' -f1)
if [ -z "$PHYS_IFACE" ]; then
    echo "Error: Could not determine physical interface"
    exit 1
fi
echo "Using physical interface: $PHYS_IFACE"
# Configure ARP settings for physical interface
echo "Configuring ARP settings for physical interface $PHYS_IFACE..."
echo 1 > /proc/sys/net/ipv4/conf/$PHYS_IFACE/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/$PHYS_IFACE/arp_announce

# Parse command line arguments
USE_DHCP=false # Default to static IPs
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dhcp) USE_DHCP=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Check if dhclient is installed when using DHCP
if [ "$USE_DHCP" = true ] && ! command -v dhclient &> /dev/null; then
    echo "dhclient not found. Please install it with:"
    echo "  sudo apt-get install isc-dhcp-client    (for Debian/Ubuntu)"
    echo "  sudo yum install dhcp-client            (for CentOS/RHEL)"
    echo "Or use --static to assign static IPs instead."
    exit 1
fi

# Create a mapping file for MAC to interface name and IP
cat > mac_to_interface.txt << EOF
02:cc:00:d2:a6:c3 onv1_a6c3 192.168.6.3
02:c9:54:34:84:df onv2_84df 192.168.6.4
02:90:67:6b:60:43 onv3_6043 192.168.6.5
02:6f:ea:dc:25:89 onv4_2589 192.168.6.6
02:27:2b:64:d0:20 onv5_d020 192.168.6.7
02:92:d2:00:e6:ae onv6_e6ae 192.168.6.8
02:37:e5:a8:a6:04 onv7_a604 192.168.6.9
02:bc:83:1a:dc:a0 onv8_dca0 192.168.6.10
02:eb:6c:a6:68:8a onv9_688a 192.168.6.11
02:39:b8:15:6a:af onv10_6aaf 192.168.6.12
02:c8:5b:d2:94:9e onv11_949e 192.168.6.13
02:ff:43:d3:a5:6d onv12_a56d 192.168.6.14
02:50:e1:ff:17:7e onv13_177e 192.168.6.15
02:6e:97:6b:39:e3 onv14_39e3 192.168.6.16
02:f8:26:39:03:d0 onv15_03d0 192.168.6.17
02:80:c4:d4:58:00 onv16_5800 192.168.6.18
EOF

# Remove any existing interfaces first
ip link show onv1_a6c3 > /dev/null 2>&1 && ip link delete onv1_a6c3
ip link show onv2_84df > /dev/null 2>&1 && ip link delete onv2_84df
ip link show onv3_6043 > /dev/null 2>&1 && ip link delete onv3_6043
ip link show onv4_2589 > /dev/null 2>&1 && ip link delete onv4_2589
ip link show onv5_d020 > /dev/null 2>&1 && ip link delete onv5_d020
ip link show onv6_e6ae > /dev/null 2>&1 && ip link delete onv6_e6ae
ip link show onv7_a604 > /dev/null 2>&1 && ip link delete onv7_a604
ip link show onv8_dca0 > /dev/null 2>&1 && ip link delete onv8_dca0
ip link show onv9_688a > /dev/null 2>&1 && ip link delete onv9_688a
ip link show onv10_6aaf > /dev/null 2>&1 && ip link delete onv10_6aaf
ip link show onv11_949e > /dev/null 2>&1 && ip link delete onv11_949e
ip link show onv12_a56d > /dev/null 2>&1 && ip link delete onv12_a56d
ip link show onv13_177e > /dev/null 2>&1 && ip link delete onv13_177e
ip link show onv14_39e3 > /dev/null 2>&1 && ip link delete onv14_39e3
ip link show onv15_03d0 > /dev/null 2>&1 && ip link delete onv15_03d0
ip link show onv16_5800 > /dev/null 2>&1 && ip link delete onv16_5800

# Create new virtual interfaces
echo "Creating macvlan interface onv1_a6c3..."
ip link add onv1_a6c3 link $PHYS_IFACE address 02:cc:00:d2:a6:c3 type macvlan mode bridge
ip link set onv1_a6c3 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv1_a6c3 via DHCP..."
    dhclient -v onv1_a6c3 &
else
    echo "Assigning static IP 192.168.6.3/24 to onv1_a6c3..."
    ip addr add 192.168.6.3/24 dev onv1_a6c3
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv1_a6c3/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv1_a6c3/arp_announce

echo "Creating macvlan interface onv2_84df..."
ip link add onv2_84df link $PHYS_IFACE address 02:c9:54:34:84:df type macvlan mode bridge
ip link set onv2_84df up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv2_84df via DHCP..."
    dhclient -v onv2_84df &
else
    echo "Assigning static IP 192.168.6.4/24 to onv2_84df..."
    ip addr add 192.168.6.4/24 dev onv2_84df
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv2_84df/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv2_84df/arp_announce

echo "Creating macvlan interface onv3_6043..."
ip link add onv3_6043 link $PHYS_IFACE address 02:90:67:6b:60:43 type macvlan mode bridge
ip link set onv3_6043 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv3_6043 via DHCP..."
    dhclient -v onv3_6043 &
else
    echo "Assigning static IP 192.168.6.5/24 to onv3_6043..."
    ip addr add 192.168.6.5/24 dev onv3_6043
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv3_6043/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv3_6043/arp_announce

echo "Creating macvlan interface onv4_2589..."
ip link add onv4_2589 link $PHYS_IFACE address 02:6f:ea:dc:25:89 type macvlan mode bridge
ip link set onv4_2589 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv4_2589 via DHCP..."
    dhclient -v onv4_2589 &
else
    echo "Assigning static IP 192.168.6.6/24 to onv4_2589..."
    ip addr add 192.168.6.6/24 dev onv4_2589
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv4_2589/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv4_2589/arp_announce

echo "Creating macvlan interface onv5_d020..."
ip link add onv5_d020 link $PHYS_IFACE address 02:27:2b:64:d0:20 type macvlan mode bridge
ip link set onv5_d020 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv5_d020 via DHCP..."
    dhclient -v onv5_d020 &
else
    echo "Assigning static IP 192.168.6.7/24 to onv5_d020..."
    ip addr add 192.168.6.7/24 dev onv5_d020
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv5_d020/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv5_d020/arp_announce

echo "Creating macvlan interface onv6_e6ae..."
ip link add onv6_e6ae link $PHYS_IFACE address 02:92:d2:00:e6:ae type macvlan mode bridge
ip link set onv6_e6ae up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv6_e6ae via DHCP..."
    dhclient -v onv6_e6ae &
else
    echo "Assigning static IP 192.168.6.8/24 to onv6_e6ae..."
    ip addr add 192.168.6.8/24 dev onv6_e6ae
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv6_e6ae/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv6_e6ae/arp_announce

echo "Creating macvlan interface onv7_a604..."
ip link add onv7_a604 link $PHYS_IFACE address 02:37:e5:a8:a6:04 type macvlan mode bridge
ip link set onv7_a604 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv7_a604 via DHCP..."
    dhclient -v onv7_a604 &
else
    echo "Assigning static IP 192.168.6.9/24 to onv7_a604..."
    ip addr add 192.168.6.9/24 dev onv7_a604
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv7_a604/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv7_a604/arp_announce

echo "Creating macvlan interface onv8_dca0..."
ip link add onv8_dca0 link $PHYS_IFACE address 02:bc:83:1a:dc:a0 type macvlan mode bridge
ip link set onv8_dca0 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv8_dca0 via DHCP..."
    dhclient -v onv8_dca0 &
else
    echo "Assigning static IP 192.168.6.10/24 to onv8_dca0..."
    ip addr add 192.168.6.10/24 dev onv8_dca0
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv8_dca0/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv8_dca0/arp_announce

echo "Creating macvlan interface onv9_688a..."
ip link add onv9_688a link $PHYS_IFACE address 02:eb:6c:a6:68:8a type macvlan mode bridge
ip link set onv9_688a up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv9_688a via DHCP..."
    dhclient -v onv9_688a &
else
    echo "Assigning static IP 192.168.6.11/24 to onv9_688a..."
    ip addr add 192.168.6.11/24 dev onv9_688a
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv9_688a/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv9_688a/arp_announce

echo "Creating macvlan interface onv10_6aaf..."
ip link add onv10_6aaf link $PHYS_IFACE address 02:39:b8:15:6a:af type macvlan mode bridge
ip link set onv10_6aaf up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv10_6aaf via DHCP..."
    dhclient -v onv10_6aaf &
else
    echo "Assigning static IP 192.168.6.12/24 to onv10_6aaf..."
    ip addr add 192.168.6.12/24 dev onv10_6aaf
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv10_6aaf/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv10_6aaf/arp_announce

echo "Creating macvlan interface onv11_949e..."
ip link add onv11_949e link $PHYS_IFACE address 02:c8:5b:d2:94:9e type macvlan mode bridge
ip link set onv11_949e up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv11_949e via DHCP..."
    dhclient -v onv11_949e &
else
    echo "Assigning static IP 192.168.6.13/24 to onv11_949e..."
    ip addr add 192.168.6.13/24 dev onv11_949e
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv11_949e/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv11_949e/arp_announce

echo "Creating macvlan interface onv12_a56d..."
ip link add onv12_a56d link $PHYS_IFACE address 02:ff:43:d3:a5:6d type macvlan mode bridge
ip link set onv12_a56d up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv12_a56d via DHCP..."
    dhclient -v onv12_a56d &
else
    echo "Assigning static IP 192.168.6.14/24 to onv12_a56d..."
    ip addr add 192.168.6.14/24 dev onv12_a56d
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv12_a56d/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv12_a56d/arp_announce

echo "Creating macvlan interface onv13_177e..."
ip link add onv13_177e link $PHYS_IFACE address 02:50:e1:ff:17:7e type macvlan mode bridge
ip link set onv13_177e up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv13_177e via DHCP..."
    dhclient -v onv13_177e &
else
    echo "Assigning static IP 192.168.6.15/24 to onv13_177e..."
    ip addr add 192.168.6.15/24 dev onv13_177e
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv13_177e/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv13_177e/arp_announce

echo "Creating macvlan interface onv14_39e3..."
ip link add onv14_39e3 link $PHYS_IFACE address 02:6e:97:6b:39:e3 type macvlan mode bridge
ip link set onv14_39e3 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv14_39e3 via DHCP..."
    dhclient -v onv14_39e3 &
else
    echo "Assigning static IP 192.168.6.16/24 to onv14_39e3..."
    ip addr add 192.168.6.16/24 dev onv14_39e3
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv14_39e3/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv14_39e3/arp_announce

echo "Creating macvlan interface onv15_03d0..."
ip link add onv15_03d0 link $PHYS_IFACE address 02:f8:26:39:03:d0 type macvlan mode bridge
ip link set onv15_03d0 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv15_03d0 via DHCP..."
    dhclient -v onv15_03d0 &
else
    echo "Assigning static IP 192.168.6.17/24 to onv15_03d0..."
    ip addr add 192.168.6.17/24 dev onv15_03d0
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv15_03d0/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv15_03d0/arp_announce

echo "Creating macvlan interface onv16_5800..."
ip link add onv16_5800 link $PHYS_IFACE address 02:80:c4:d4:58:00 type macvlan mode bridge
ip link set onv16_5800 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv16_5800 via DHCP..."
    dhclient -v onv16_5800 &
else
    echo "Assigning static IP 192.168.6.18/24 to onv16_5800..."
    ip addr add 192.168.6.18/24 dev onv16_5800
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv16_5800/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv16_5800/arp_announce

# Wait for IP assignment to complete and display IP addresses
sleep 3
echo "Virtual interface IP addresses:"
ip -4 addr show | grep -A 2 "onv" | grep -v "valid_lft"

echo "Static IP assignment is the default. To use DHCP instead, run: sudo $0 --dhcp"
