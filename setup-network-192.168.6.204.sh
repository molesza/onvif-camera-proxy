#!/bin/bash

# Network setup script for ONVIF virtual interfaces
# Generated for NVR: 192.168.6.204
# Generated on: 2025-04-17T14:43:50.751Z

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
02:6c:7c:51:4a:6c onv1_4a6c 192.168.6.3
02:b5:d3:59:6d:bd onv2_6dbd 192.168.6.4
02:4c:f8:89:fa:84 onv3_fa84 192.168.6.5
02:82:f7:19:d6:f1 onv4_d6f1 192.168.6.6
02:7e:89:ae:44:e8 onv5_44e8 192.168.6.7
02:a0:63:ad:b1:b3 onv6_b1b3 192.168.6.8
02:e1:6c:9f:03:bc onv7_03bc 192.168.6.9
02:8e:6d:14:07:3c onv8_073c 192.168.6.10
02:b0:6e:26:a2:e4 onv9_a2e4 192.168.6.11
02:46:2f:98:d7:54 onv10_d754 192.168.6.12
02:3a:1e:84:f3:c2 onv11_f3c2 192.168.6.13
02:a3:bc:f6:98:a9 onv12_98a9 192.168.6.14
02:24:14:61:07:0d onv13_070d 192.168.6.15
02:a3:ae:c0:be:3c onv14_be3c 192.168.6.16
02:b0:46:fe:30:9d onv15_309d 192.168.6.17
02:b6:10:34:57:93 onv16_5793 192.168.6.18
02:bb:98:b9:82:19 onv17_8219 192.168.6.19
02:24:71:07:ae:ac onv18_aeac 192.168.6.20
02:90:98:73:cd:28 onv19_cd28 192.168.6.21
02:6a:9d:c1:d5:73 onv20_d573 192.168.6.22
02:e2:45:72:05:71 onv21_0571 192.168.6.23
02:50:e8:40:c0:87 onv22_c087 192.168.6.24
02:98:a9:71:83:b6 onv23_83b6 192.168.6.25
02:3b:8a:2e:56:ea onv24_56ea 192.168.6.26
02:c1:b2:86:21:71 onv25_2171 192.168.6.27
02:02:f6:54:16:69 onv26_1669 192.168.6.28
02:bd:6c:9e:96:16 onv27_9616 192.168.6.29
02:0f:b3:45:69:5c onv28_695c 192.168.6.30
02:8a:8f:f6:b8:34 onv29_b834 192.168.6.31
02:fb:78:8e:91:ee onv30_91ee 192.168.6.32
02:0d:ba:c1:63:b2 onv31_63b2 192.168.6.33
02:91:59:0f:42:45 onv32_4245 192.168.6.34
EOF

# Remove any existing interfaces first
ip link show onv1_4a6c > /dev/null 2>&1 && ip link delete onv1_4a6c
ip link show onv2_6dbd > /dev/null 2>&1 && ip link delete onv2_6dbd
ip link show onv3_fa84 > /dev/null 2>&1 && ip link delete onv3_fa84
ip link show onv4_d6f1 > /dev/null 2>&1 && ip link delete onv4_d6f1
ip link show onv5_44e8 > /dev/null 2>&1 && ip link delete onv5_44e8
ip link show onv6_b1b3 > /dev/null 2>&1 && ip link delete onv6_b1b3
ip link show onv7_03bc > /dev/null 2>&1 && ip link delete onv7_03bc
ip link show onv8_073c > /dev/null 2>&1 && ip link delete onv8_073c
ip link show onv9_a2e4 > /dev/null 2>&1 && ip link delete onv9_a2e4
ip link show onv10_d754 > /dev/null 2>&1 && ip link delete onv10_d754
ip link show onv11_f3c2 > /dev/null 2>&1 && ip link delete onv11_f3c2
ip link show onv12_98a9 > /dev/null 2>&1 && ip link delete onv12_98a9
ip link show onv13_070d > /dev/null 2>&1 && ip link delete onv13_070d
ip link show onv14_be3c > /dev/null 2>&1 && ip link delete onv14_be3c
ip link show onv15_309d > /dev/null 2>&1 && ip link delete onv15_309d
ip link show onv16_5793 > /dev/null 2>&1 && ip link delete onv16_5793
ip link show onv17_8219 > /dev/null 2>&1 && ip link delete onv17_8219
ip link show onv18_aeac > /dev/null 2>&1 && ip link delete onv18_aeac
ip link show onv19_cd28 > /dev/null 2>&1 && ip link delete onv19_cd28
ip link show onv20_d573 > /dev/null 2>&1 && ip link delete onv20_d573
ip link show onv21_0571 > /dev/null 2>&1 && ip link delete onv21_0571
ip link show onv22_c087 > /dev/null 2>&1 && ip link delete onv22_c087
ip link show onv23_83b6 > /dev/null 2>&1 && ip link delete onv23_83b6
ip link show onv24_56ea > /dev/null 2>&1 && ip link delete onv24_56ea
ip link show onv25_2171 > /dev/null 2>&1 && ip link delete onv25_2171
ip link show onv26_1669 > /dev/null 2>&1 && ip link delete onv26_1669
ip link show onv27_9616 > /dev/null 2>&1 && ip link delete onv27_9616
ip link show onv28_695c > /dev/null 2>&1 && ip link delete onv28_695c
ip link show onv29_b834 > /dev/null 2>&1 && ip link delete onv29_b834
ip link show onv30_91ee > /dev/null 2>&1 && ip link delete onv30_91ee
ip link show onv31_63b2 > /dev/null 2>&1 && ip link delete onv31_63b2
ip link show onv32_4245 > /dev/null 2>&1 && ip link delete onv32_4245

# Create new virtual interfaces
echo "Creating macvlan interface onv1_4a6c..."
ip link add onv1_4a6c link $PHYS_IFACE address 02:6c:7c:51:4a:6c type macvlan mode bridge
ip link set onv1_4a6c up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv1_4a6c via DHCP..."
    dhclient -v onv1_4a6c &
else
    echo "Assigning static IP 192.168.6.3/24 to onv1_4a6c..."
    ip addr add 192.168.6.3/24 dev onv1_4a6c
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv1_4a6c/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv1_4a6c/arp_announce

echo "Creating macvlan interface onv2_6dbd..."
ip link add onv2_6dbd link $PHYS_IFACE address 02:b5:d3:59:6d:bd type macvlan mode bridge
ip link set onv2_6dbd up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv2_6dbd via DHCP..."
    dhclient -v onv2_6dbd &
else
    echo "Assigning static IP 192.168.6.4/24 to onv2_6dbd..."
    ip addr add 192.168.6.4/24 dev onv2_6dbd
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv2_6dbd/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv2_6dbd/arp_announce

echo "Creating macvlan interface onv3_fa84..."
ip link add onv3_fa84 link $PHYS_IFACE address 02:4c:f8:89:fa:84 type macvlan mode bridge
ip link set onv3_fa84 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv3_fa84 via DHCP..."
    dhclient -v onv3_fa84 &
else
    echo "Assigning static IP 192.168.6.5/24 to onv3_fa84..."
    ip addr add 192.168.6.5/24 dev onv3_fa84
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv3_fa84/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv3_fa84/arp_announce

echo "Creating macvlan interface onv4_d6f1..."
ip link add onv4_d6f1 link $PHYS_IFACE address 02:82:f7:19:d6:f1 type macvlan mode bridge
ip link set onv4_d6f1 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv4_d6f1 via DHCP..."
    dhclient -v onv4_d6f1 &
else
    echo "Assigning static IP 192.168.6.6/24 to onv4_d6f1..."
    ip addr add 192.168.6.6/24 dev onv4_d6f1
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv4_d6f1/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv4_d6f1/arp_announce

echo "Creating macvlan interface onv5_44e8..."
ip link add onv5_44e8 link $PHYS_IFACE address 02:7e:89:ae:44:e8 type macvlan mode bridge
ip link set onv5_44e8 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv5_44e8 via DHCP..."
    dhclient -v onv5_44e8 &
else
    echo "Assigning static IP 192.168.6.7/24 to onv5_44e8..."
    ip addr add 192.168.6.7/24 dev onv5_44e8
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv5_44e8/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv5_44e8/arp_announce

echo "Creating macvlan interface onv6_b1b3..."
ip link add onv6_b1b3 link $PHYS_IFACE address 02:a0:63:ad:b1:b3 type macvlan mode bridge
ip link set onv6_b1b3 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv6_b1b3 via DHCP..."
    dhclient -v onv6_b1b3 &
else
    echo "Assigning static IP 192.168.6.8/24 to onv6_b1b3..."
    ip addr add 192.168.6.8/24 dev onv6_b1b3
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv6_b1b3/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv6_b1b3/arp_announce

echo "Creating macvlan interface onv7_03bc..."
ip link add onv7_03bc link $PHYS_IFACE address 02:e1:6c:9f:03:bc type macvlan mode bridge
ip link set onv7_03bc up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv7_03bc via DHCP..."
    dhclient -v onv7_03bc &
else
    echo "Assigning static IP 192.168.6.9/24 to onv7_03bc..."
    ip addr add 192.168.6.9/24 dev onv7_03bc
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv7_03bc/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv7_03bc/arp_announce

echo "Creating macvlan interface onv8_073c..."
ip link add onv8_073c link $PHYS_IFACE address 02:8e:6d:14:07:3c type macvlan mode bridge
ip link set onv8_073c up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv8_073c via DHCP..."
    dhclient -v onv8_073c &
else
    echo "Assigning static IP 192.168.6.10/24 to onv8_073c..."
    ip addr add 192.168.6.10/24 dev onv8_073c
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv8_073c/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv8_073c/arp_announce

echo "Creating macvlan interface onv9_a2e4..."
ip link add onv9_a2e4 link $PHYS_IFACE address 02:b0:6e:26:a2:e4 type macvlan mode bridge
ip link set onv9_a2e4 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv9_a2e4 via DHCP..."
    dhclient -v onv9_a2e4 &
else
    echo "Assigning static IP 192.168.6.11/24 to onv9_a2e4..."
    ip addr add 192.168.6.11/24 dev onv9_a2e4
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv9_a2e4/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv9_a2e4/arp_announce

echo "Creating macvlan interface onv10_d754..."
ip link add onv10_d754 link $PHYS_IFACE address 02:46:2f:98:d7:54 type macvlan mode bridge
ip link set onv10_d754 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv10_d754 via DHCP..."
    dhclient -v onv10_d754 &
else
    echo "Assigning static IP 192.168.6.12/24 to onv10_d754..."
    ip addr add 192.168.6.12/24 dev onv10_d754
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv10_d754/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv10_d754/arp_announce

echo "Creating macvlan interface onv11_f3c2..."
ip link add onv11_f3c2 link $PHYS_IFACE address 02:3a:1e:84:f3:c2 type macvlan mode bridge
ip link set onv11_f3c2 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv11_f3c2 via DHCP..."
    dhclient -v onv11_f3c2 &
else
    echo "Assigning static IP 192.168.6.13/24 to onv11_f3c2..."
    ip addr add 192.168.6.13/24 dev onv11_f3c2
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv11_f3c2/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv11_f3c2/arp_announce

echo "Creating macvlan interface onv12_98a9..."
ip link add onv12_98a9 link $PHYS_IFACE address 02:a3:bc:f6:98:a9 type macvlan mode bridge
ip link set onv12_98a9 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv12_98a9 via DHCP..."
    dhclient -v onv12_98a9 &
else
    echo "Assigning static IP 192.168.6.14/24 to onv12_98a9..."
    ip addr add 192.168.6.14/24 dev onv12_98a9
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv12_98a9/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv12_98a9/arp_announce

echo "Creating macvlan interface onv13_070d..."
ip link add onv13_070d link $PHYS_IFACE address 02:24:14:61:07:0d type macvlan mode bridge
ip link set onv13_070d up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv13_070d via DHCP..."
    dhclient -v onv13_070d &
else
    echo "Assigning static IP 192.168.6.15/24 to onv13_070d..."
    ip addr add 192.168.6.15/24 dev onv13_070d
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv13_070d/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv13_070d/arp_announce

echo "Creating macvlan interface onv14_be3c..."
ip link add onv14_be3c link $PHYS_IFACE address 02:a3:ae:c0:be:3c type macvlan mode bridge
ip link set onv14_be3c up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv14_be3c via DHCP..."
    dhclient -v onv14_be3c &
else
    echo "Assigning static IP 192.168.6.16/24 to onv14_be3c..."
    ip addr add 192.168.6.16/24 dev onv14_be3c
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv14_be3c/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv14_be3c/arp_announce

echo "Creating macvlan interface onv15_309d..."
ip link add onv15_309d link $PHYS_IFACE address 02:b0:46:fe:30:9d type macvlan mode bridge
ip link set onv15_309d up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv15_309d via DHCP..."
    dhclient -v onv15_309d &
else
    echo "Assigning static IP 192.168.6.17/24 to onv15_309d..."
    ip addr add 192.168.6.17/24 dev onv15_309d
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv15_309d/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv15_309d/arp_announce

echo "Creating macvlan interface onv16_5793..."
ip link add onv16_5793 link $PHYS_IFACE address 02:b6:10:34:57:93 type macvlan mode bridge
ip link set onv16_5793 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv16_5793 via DHCP..."
    dhclient -v onv16_5793 &
else
    echo "Assigning static IP 192.168.6.18/24 to onv16_5793..."
    ip addr add 192.168.6.18/24 dev onv16_5793
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv16_5793/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv16_5793/arp_announce

echo "Creating macvlan interface onv17_8219..."
ip link add onv17_8219 link $PHYS_IFACE address 02:bb:98:b9:82:19 type macvlan mode bridge
ip link set onv17_8219 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv17_8219 via DHCP..."
    dhclient -v onv17_8219 &
else
    echo "Assigning static IP 192.168.6.19/24 to onv17_8219..."
    ip addr add 192.168.6.19/24 dev onv17_8219
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv17_8219/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv17_8219/arp_announce

echo "Creating macvlan interface onv18_aeac..."
ip link add onv18_aeac link $PHYS_IFACE address 02:24:71:07:ae:ac type macvlan mode bridge
ip link set onv18_aeac up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv18_aeac via DHCP..."
    dhclient -v onv18_aeac &
else
    echo "Assigning static IP 192.168.6.20/24 to onv18_aeac..."
    ip addr add 192.168.6.20/24 dev onv18_aeac
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv18_aeac/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv18_aeac/arp_announce

echo "Creating macvlan interface onv19_cd28..."
ip link add onv19_cd28 link $PHYS_IFACE address 02:90:98:73:cd:28 type macvlan mode bridge
ip link set onv19_cd28 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv19_cd28 via DHCP..."
    dhclient -v onv19_cd28 &
else
    echo "Assigning static IP 192.168.6.21/24 to onv19_cd28..."
    ip addr add 192.168.6.21/24 dev onv19_cd28
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv19_cd28/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv19_cd28/arp_announce

echo "Creating macvlan interface onv20_d573..."
ip link add onv20_d573 link $PHYS_IFACE address 02:6a:9d:c1:d5:73 type macvlan mode bridge
ip link set onv20_d573 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv20_d573 via DHCP..."
    dhclient -v onv20_d573 &
else
    echo "Assigning static IP 192.168.6.22/24 to onv20_d573..."
    ip addr add 192.168.6.22/24 dev onv20_d573
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv20_d573/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv20_d573/arp_announce

echo "Creating macvlan interface onv21_0571..."
ip link add onv21_0571 link $PHYS_IFACE address 02:e2:45:72:05:71 type macvlan mode bridge
ip link set onv21_0571 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv21_0571 via DHCP..."
    dhclient -v onv21_0571 &
else
    echo "Assigning static IP 192.168.6.23/24 to onv21_0571..."
    ip addr add 192.168.6.23/24 dev onv21_0571
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv21_0571/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv21_0571/arp_announce

echo "Creating macvlan interface onv22_c087..."
ip link add onv22_c087 link $PHYS_IFACE address 02:50:e8:40:c0:87 type macvlan mode bridge
ip link set onv22_c087 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv22_c087 via DHCP..."
    dhclient -v onv22_c087 &
else
    echo "Assigning static IP 192.168.6.24/24 to onv22_c087..."
    ip addr add 192.168.6.24/24 dev onv22_c087
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv22_c087/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv22_c087/arp_announce

echo "Creating macvlan interface onv23_83b6..."
ip link add onv23_83b6 link $PHYS_IFACE address 02:98:a9:71:83:b6 type macvlan mode bridge
ip link set onv23_83b6 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv23_83b6 via DHCP..."
    dhclient -v onv23_83b6 &
else
    echo "Assigning static IP 192.168.6.25/24 to onv23_83b6..."
    ip addr add 192.168.6.25/24 dev onv23_83b6
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv23_83b6/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv23_83b6/arp_announce

echo "Creating macvlan interface onv24_56ea..."
ip link add onv24_56ea link $PHYS_IFACE address 02:3b:8a:2e:56:ea type macvlan mode bridge
ip link set onv24_56ea up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv24_56ea via DHCP..."
    dhclient -v onv24_56ea &
else
    echo "Assigning static IP 192.168.6.26/24 to onv24_56ea..."
    ip addr add 192.168.6.26/24 dev onv24_56ea
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv24_56ea/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv24_56ea/arp_announce

echo "Creating macvlan interface onv25_2171..."
ip link add onv25_2171 link $PHYS_IFACE address 02:c1:b2:86:21:71 type macvlan mode bridge
ip link set onv25_2171 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv25_2171 via DHCP..."
    dhclient -v onv25_2171 &
else
    echo "Assigning static IP 192.168.6.27/24 to onv25_2171..."
    ip addr add 192.168.6.27/24 dev onv25_2171
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv25_2171/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv25_2171/arp_announce

echo "Creating macvlan interface onv26_1669..."
ip link add onv26_1669 link $PHYS_IFACE address 02:02:f6:54:16:69 type macvlan mode bridge
ip link set onv26_1669 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv26_1669 via DHCP..."
    dhclient -v onv26_1669 &
else
    echo "Assigning static IP 192.168.6.28/24 to onv26_1669..."
    ip addr add 192.168.6.28/24 dev onv26_1669
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv26_1669/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv26_1669/arp_announce

echo "Creating macvlan interface onv27_9616..."
ip link add onv27_9616 link $PHYS_IFACE address 02:bd:6c:9e:96:16 type macvlan mode bridge
ip link set onv27_9616 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv27_9616 via DHCP..."
    dhclient -v onv27_9616 &
else
    echo "Assigning static IP 192.168.6.29/24 to onv27_9616..."
    ip addr add 192.168.6.29/24 dev onv27_9616
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv27_9616/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv27_9616/arp_announce

echo "Creating macvlan interface onv28_695c..."
ip link add onv28_695c link $PHYS_IFACE address 02:0f:b3:45:69:5c type macvlan mode bridge
ip link set onv28_695c up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv28_695c via DHCP..."
    dhclient -v onv28_695c &
else
    echo "Assigning static IP 192.168.6.30/24 to onv28_695c..."
    ip addr add 192.168.6.30/24 dev onv28_695c
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv28_695c/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv28_695c/arp_announce

echo "Creating macvlan interface onv29_b834..."
ip link add onv29_b834 link $PHYS_IFACE address 02:8a:8f:f6:b8:34 type macvlan mode bridge
ip link set onv29_b834 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv29_b834 via DHCP..."
    dhclient -v onv29_b834 &
else
    echo "Assigning static IP 192.168.6.31/24 to onv29_b834..."
    ip addr add 192.168.6.31/24 dev onv29_b834
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv29_b834/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv29_b834/arp_announce

echo "Creating macvlan interface onv30_91ee..."
ip link add onv30_91ee link $PHYS_IFACE address 02:fb:78:8e:91:ee type macvlan mode bridge
ip link set onv30_91ee up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv30_91ee via DHCP..."
    dhclient -v onv30_91ee &
else
    echo "Assigning static IP 192.168.6.32/24 to onv30_91ee..."
    ip addr add 192.168.6.32/24 dev onv30_91ee
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv30_91ee/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv30_91ee/arp_announce

echo "Creating macvlan interface onv31_63b2..."
ip link add onv31_63b2 link $PHYS_IFACE address 02:0d:ba:c1:63:b2 type macvlan mode bridge
ip link set onv31_63b2 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv31_63b2 via DHCP..."
    dhclient -v onv31_63b2 &
else
    echo "Assigning static IP 192.168.6.33/24 to onv31_63b2..."
    ip addr add 192.168.6.33/24 dev onv31_63b2
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv31_63b2/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv31_63b2/arp_announce

echo "Creating macvlan interface onv32_4245..."
ip link add onv32_4245 link $PHYS_IFACE address 02:91:59:0f:42:45 type macvlan mode bridge
ip link set onv32_4245 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv32_4245 via DHCP..."
    dhclient -v onv32_4245 &
else
    echo "Assigning static IP 192.168.6.34/24 to onv32_4245..."
    ip addr add 192.168.6.34/24 dev onv32_4245
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv32_4245/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv32_4245/arp_announce

# Wait for IP assignment to complete and display IP addresses
sleep 3
echo "Virtual interface IP addresses:"
ip -4 addr show | grep -A 2 "onv" | grep -v "valid_lft"

echo "Static IP assignment is the default. To use DHCP instead, run: sudo $0 --dhcp"
