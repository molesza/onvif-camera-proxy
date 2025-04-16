#!/bin/bash

# Network setup script for ONVIF virtual interfaces
# Generated for NVR: 192.168.6.201
# Generated on: 2025-04-16T13:08:14.256Z

# Get the physical interface name (look for the interface with the host IP)
HOST_IP=$(hostname -I | awk '{print $1}')
PHYS_IFACE=$(ip -o addr show | grep "$HOST_IP" | grep -v macvlan | awk '{print $2}' | cut -d':' -f1)
if [ -z "$PHYS_IFACE" ]; then
    echo "Error: Could not determine physical interface"
    exit 1
fi
echo "Using physical interface: $PHYS_IFACE"

# Parse command line arguments
USE_DHCP=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --static) USE_DHCP=false ;;
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
02:28:5c:53:db:b4 onv1_dbb4 192.168.6.3
02:ca:fe:ba:62:8d onv2_628d 192.168.6.4
02:b0:82:62:fa:d9 onv3_fad9 192.168.6.5
02:09:84:94:24:75 onv4_2475 192.168.6.6
02:20:5c:60:50:93 onv5_5093 192.168.6.7
02:6f:cb:19:cb:b4 onv6_cbb4 192.168.6.8
02:8e:81:a6:21:cb onv7_21cb 192.168.6.9
02:0b:70:bd:69:e3 onv8_69e3 192.168.6.10
02:7e:32:58:29:12 onv9_2912 192.168.6.11
02:cd:47:13:1b:73 onv10_1b73 192.168.6.12
02:af:df:dd:a6:fc onv11_a6fc 192.168.6.13
02:0e:71:51:f9:b6 onv12_f9b6 192.168.6.14
02:dd:ac:2e:c6:b4 onv13_c6b4 192.168.6.15
02:59:a5:04:df:d2 onv14_dfd2 192.168.6.16
02:fd:fc:0e:8e:96 onv15_8e96 192.168.6.17
02:a1:ef:84:32:1b onv16_321b 192.168.6.18
02:1f:4a:4d:dc:b2 onv17_dcb2 192.168.6.19
02:6c:df:c2:8a:e4 onv18_8ae4 192.168.6.20
02:78:5d:1d:93:13 onv19_9313 192.168.6.21
02:72:0e:1c:6c:12 onv20_6c12 192.168.6.22
02:aa:e1:92:ad:20 onv21_ad20 192.168.6.23
02:e6:59:ae:f7:cb onv22_f7cb 192.168.6.24
02:4a:b7:ec:94:0e onv23_940e 192.168.6.25
02:1c:0c:6f:7e:17 onv24_7e17 192.168.6.26
02:f7:53:82:11:5b onv25_115b 192.168.6.27
02:a4:c8:2a:a6:14 onv26_a614 192.168.6.28
02:53:98:1d:1e:db onv27_1edb 192.168.6.29
02:d7:88:0d:33:6f onv28_336f 192.168.6.30
02:c3:5b:fb:ec:72 onv29_ec72 192.168.6.31
02:29:3d:11:bc:3a onv30_bc3a 192.168.6.32
02:0f:dc:bc:54:b3 onv31_54b3 192.168.6.33
02:d0:19:ba:5b:68 onv32_5b68 192.168.6.34
EOF

# Remove any existing interfaces first
ip link show onv1_dbb4 > /dev/null 2>&1 && ip link delete onv1_dbb4
ip link show onv2_628d > /dev/null 2>&1 && ip link delete onv2_628d
ip link show onv3_fad9 > /dev/null 2>&1 && ip link delete onv3_fad9
ip link show onv4_2475 > /dev/null 2>&1 && ip link delete onv4_2475
ip link show onv5_5093 > /dev/null 2>&1 && ip link delete onv5_5093
ip link show onv6_cbb4 > /dev/null 2>&1 && ip link delete onv6_cbb4
ip link show onv7_21cb > /dev/null 2>&1 && ip link delete onv7_21cb
ip link show onv8_69e3 > /dev/null 2>&1 && ip link delete onv8_69e3
ip link show onv9_2912 > /dev/null 2>&1 && ip link delete onv9_2912
ip link show onv10_1b73 > /dev/null 2>&1 && ip link delete onv10_1b73
ip link show onv11_a6fc > /dev/null 2>&1 && ip link delete onv11_a6fc
ip link show onv12_f9b6 > /dev/null 2>&1 && ip link delete onv12_f9b6
ip link show onv13_c6b4 > /dev/null 2>&1 && ip link delete onv13_c6b4
ip link show onv14_dfd2 > /dev/null 2>&1 && ip link delete onv14_dfd2
ip link show onv15_8e96 > /dev/null 2>&1 && ip link delete onv15_8e96
ip link show onv16_321b > /dev/null 2>&1 && ip link delete onv16_321b
ip link show onv17_dcb2 > /dev/null 2>&1 && ip link delete onv17_dcb2
ip link show onv18_8ae4 > /dev/null 2>&1 && ip link delete onv18_8ae4
ip link show onv19_9313 > /dev/null 2>&1 && ip link delete onv19_9313
ip link show onv20_6c12 > /dev/null 2>&1 && ip link delete onv20_6c12
ip link show onv21_ad20 > /dev/null 2>&1 && ip link delete onv21_ad20
ip link show onv22_f7cb > /dev/null 2>&1 && ip link delete onv22_f7cb
ip link show onv23_940e > /dev/null 2>&1 && ip link delete onv23_940e
ip link show onv24_7e17 > /dev/null 2>&1 && ip link delete onv24_7e17
ip link show onv25_115b > /dev/null 2>&1 && ip link delete onv25_115b
ip link show onv26_a614 > /dev/null 2>&1 && ip link delete onv26_a614
ip link show onv27_1edb > /dev/null 2>&1 && ip link delete onv27_1edb
ip link show onv28_336f > /dev/null 2>&1 && ip link delete onv28_336f
ip link show onv29_ec72 > /dev/null 2>&1 && ip link delete onv29_ec72
ip link show onv30_bc3a > /dev/null 2>&1 && ip link delete onv30_bc3a
ip link show onv31_54b3 > /dev/null 2>&1 && ip link delete onv31_54b3
ip link show onv32_5b68 > /dev/null 2>&1 && ip link delete onv32_5b68

# Create new virtual interfaces
echo "Creating macvlan interface onv1_dbb4..."
ip link add onv1_dbb4 link $PHYS_IFACE address 02:28:5c:53:db:b4 type macvlan mode bridge
ip link set onv1_dbb4 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv1_dbb4 via DHCP..."
    dhclient -v onv1_dbb4 &
else
    echo "Assigning static IP 192.168.6.3/24 to onv1_dbb4..."
    ip addr add 192.168.6.3/24 dev onv1_dbb4
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv1_dbb4/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv1_dbb4/arp_announce

echo "Creating macvlan interface onv2_628d..."
ip link add onv2_628d link $PHYS_IFACE address 02:ca:fe:ba:62:8d type macvlan mode bridge
ip link set onv2_628d up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv2_628d via DHCP..."
    dhclient -v onv2_628d &
else
    echo "Assigning static IP 192.168.6.4/24 to onv2_628d..."
    ip addr add 192.168.6.4/24 dev onv2_628d
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv2_628d/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv2_628d/arp_announce

echo "Creating macvlan interface onv3_fad9..."
ip link add onv3_fad9 link $PHYS_IFACE address 02:b0:82:62:fa:d9 type macvlan mode bridge
ip link set onv3_fad9 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv3_fad9 via DHCP..."
    dhclient -v onv3_fad9 &
else
    echo "Assigning static IP 192.168.6.5/24 to onv3_fad9..."
    ip addr add 192.168.6.5/24 dev onv3_fad9
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv3_fad9/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv3_fad9/arp_announce

echo "Creating macvlan interface onv4_2475..."
ip link add onv4_2475 link $PHYS_IFACE address 02:09:84:94:24:75 type macvlan mode bridge
ip link set onv4_2475 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv4_2475 via DHCP..."
    dhclient -v onv4_2475 &
else
    echo "Assigning static IP 192.168.6.6/24 to onv4_2475..."
    ip addr add 192.168.6.6/24 dev onv4_2475
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv4_2475/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv4_2475/arp_announce

echo "Creating macvlan interface onv5_5093..."
ip link add onv5_5093 link $PHYS_IFACE address 02:20:5c:60:50:93 type macvlan mode bridge
ip link set onv5_5093 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv5_5093 via DHCP..."
    dhclient -v onv5_5093 &
else
    echo "Assigning static IP 192.168.6.7/24 to onv5_5093..."
    ip addr add 192.168.6.7/24 dev onv5_5093
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv5_5093/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv5_5093/arp_announce

echo "Creating macvlan interface onv6_cbb4..."
ip link add onv6_cbb4 link $PHYS_IFACE address 02:6f:cb:19:cb:b4 type macvlan mode bridge
ip link set onv6_cbb4 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv6_cbb4 via DHCP..."
    dhclient -v onv6_cbb4 &
else
    echo "Assigning static IP 192.168.6.8/24 to onv6_cbb4..."
    ip addr add 192.168.6.8/24 dev onv6_cbb4
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv6_cbb4/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv6_cbb4/arp_announce

echo "Creating macvlan interface onv7_21cb..."
ip link add onv7_21cb link $PHYS_IFACE address 02:8e:81:a6:21:cb type macvlan mode bridge
ip link set onv7_21cb up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv7_21cb via DHCP..."
    dhclient -v onv7_21cb &
else
    echo "Assigning static IP 192.168.6.9/24 to onv7_21cb..."
    ip addr add 192.168.6.9/24 dev onv7_21cb
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv7_21cb/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv7_21cb/arp_announce

echo "Creating macvlan interface onv8_69e3..."
ip link add onv8_69e3 link $PHYS_IFACE address 02:0b:70:bd:69:e3 type macvlan mode bridge
ip link set onv8_69e3 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv8_69e3 via DHCP..."
    dhclient -v onv8_69e3 &
else
    echo "Assigning static IP 192.168.6.10/24 to onv8_69e3..."
    ip addr add 192.168.6.10/24 dev onv8_69e3
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv8_69e3/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv8_69e3/arp_announce

echo "Creating macvlan interface onv9_2912..."
ip link add onv9_2912 link $PHYS_IFACE address 02:7e:32:58:29:12 type macvlan mode bridge
ip link set onv9_2912 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv9_2912 via DHCP..."
    dhclient -v onv9_2912 &
else
    echo "Assigning static IP 192.168.6.11/24 to onv9_2912..."
    ip addr add 192.168.6.11/24 dev onv9_2912
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv9_2912/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv9_2912/arp_announce

echo "Creating macvlan interface onv10_1b73..."
ip link add onv10_1b73 link $PHYS_IFACE address 02:cd:47:13:1b:73 type macvlan mode bridge
ip link set onv10_1b73 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv10_1b73 via DHCP..."
    dhclient -v onv10_1b73 &
else
    echo "Assigning static IP 192.168.6.12/24 to onv10_1b73..."
    ip addr add 192.168.6.12/24 dev onv10_1b73
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv10_1b73/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv10_1b73/arp_announce

echo "Creating macvlan interface onv11_a6fc..."
ip link add onv11_a6fc link $PHYS_IFACE address 02:af:df:dd:a6:fc type macvlan mode bridge
ip link set onv11_a6fc up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv11_a6fc via DHCP..."
    dhclient -v onv11_a6fc &
else
    echo "Assigning static IP 192.168.6.13/24 to onv11_a6fc..."
    ip addr add 192.168.6.13/24 dev onv11_a6fc
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv11_a6fc/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv11_a6fc/arp_announce

echo "Creating macvlan interface onv12_f9b6..."
ip link add onv12_f9b6 link $PHYS_IFACE address 02:0e:71:51:f9:b6 type macvlan mode bridge
ip link set onv12_f9b6 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv12_f9b6 via DHCP..."
    dhclient -v onv12_f9b6 &
else
    echo "Assigning static IP 192.168.6.14/24 to onv12_f9b6..."
    ip addr add 192.168.6.14/24 dev onv12_f9b6
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv12_f9b6/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv12_f9b6/arp_announce

echo "Creating macvlan interface onv13_c6b4..."
ip link add onv13_c6b4 link $PHYS_IFACE address 02:dd:ac:2e:c6:b4 type macvlan mode bridge
ip link set onv13_c6b4 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv13_c6b4 via DHCP..."
    dhclient -v onv13_c6b4 &
else
    echo "Assigning static IP 192.168.6.15/24 to onv13_c6b4..."
    ip addr add 192.168.6.15/24 dev onv13_c6b4
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv13_c6b4/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv13_c6b4/arp_announce

echo "Creating macvlan interface onv14_dfd2..."
ip link add onv14_dfd2 link $PHYS_IFACE address 02:59:a5:04:df:d2 type macvlan mode bridge
ip link set onv14_dfd2 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv14_dfd2 via DHCP..."
    dhclient -v onv14_dfd2 &
else
    echo "Assigning static IP 192.168.6.16/24 to onv14_dfd2..."
    ip addr add 192.168.6.16/24 dev onv14_dfd2
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv14_dfd2/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv14_dfd2/arp_announce

echo "Creating macvlan interface onv15_8e96..."
ip link add onv15_8e96 link $PHYS_IFACE address 02:fd:fc:0e:8e:96 type macvlan mode bridge
ip link set onv15_8e96 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv15_8e96 via DHCP..."
    dhclient -v onv15_8e96 &
else
    echo "Assigning static IP 192.168.6.17/24 to onv15_8e96..."
    ip addr add 192.168.6.17/24 dev onv15_8e96
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv15_8e96/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv15_8e96/arp_announce

echo "Creating macvlan interface onv16_321b..."
ip link add onv16_321b link $PHYS_IFACE address 02:a1:ef:84:32:1b type macvlan mode bridge
ip link set onv16_321b up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv16_321b via DHCP..."
    dhclient -v onv16_321b &
else
    echo "Assigning static IP 192.168.6.18/24 to onv16_321b..."
    ip addr add 192.168.6.18/24 dev onv16_321b
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv16_321b/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv16_321b/arp_announce

echo "Creating macvlan interface onv17_dcb2..."
ip link add onv17_dcb2 link $PHYS_IFACE address 02:1f:4a:4d:dc:b2 type macvlan mode bridge
ip link set onv17_dcb2 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv17_dcb2 via DHCP..."
    dhclient -v onv17_dcb2 &
else
    echo "Assigning static IP 192.168.6.19/24 to onv17_dcb2..."
    ip addr add 192.168.6.19/24 dev onv17_dcb2
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv17_dcb2/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv17_dcb2/arp_announce

echo "Creating macvlan interface onv18_8ae4..."
ip link add onv18_8ae4 link $PHYS_IFACE address 02:6c:df:c2:8a:e4 type macvlan mode bridge
ip link set onv18_8ae4 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv18_8ae4 via DHCP..."
    dhclient -v onv18_8ae4 &
else
    echo "Assigning static IP 192.168.6.20/24 to onv18_8ae4..."
    ip addr add 192.168.6.20/24 dev onv18_8ae4
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv18_8ae4/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv18_8ae4/arp_announce

echo "Creating macvlan interface onv19_9313..."
ip link add onv19_9313 link $PHYS_IFACE address 02:78:5d:1d:93:13 type macvlan mode bridge
ip link set onv19_9313 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv19_9313 via DHCP..."
    dhclient -v onv19_9313 &
else
    echo "Assigning static IP 192.168.6.21/24 to onv19_9313..."
    ip addr add 192.168.6.21/24 dev onv19_9313
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv19_9313/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv19_9313/arp_announce

echo "Creating macvlan interface onv20_6c12..."
ip link add onv20_6c12 link $PHYS_IFACE address 02:72:0e:1c:6c:12 type macvlan mode bridge
ip link set onv20_6c12 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv20_6c12 via DHCP..."
    dhclient -v onv20_6c12 &
else
    echo "Assigning static IP 192.168.6.22/24 to onv20_6c12..."
    ip addr add 192.168.6.22/24 dev onv20_6c12
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv20_6c12/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv20_6c12/arp_announce

echo "Creating macvlan interface onv21_ad20..."
ip link add onv21_ad20 link $PHYS_IFACE address 02:aa:e1:92:ad:20 type macvlan mode bridge
ip link set onv21_ad20 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv21_ad20 via DHCP..."
    dhclient -v onv21_ad20 &
else
    echo "Assigning static IP 192.168.6.23/24 to onv21_ad20..."
    ip addr add 192.168.6.23/24 dev onv21_ad20
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv21_ad20/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv21_ad20/arp_announce

echo "Creating macvlan interface onv22_f7cb..."
ip link add onv22_f7cb link $PHYS_IFACE address 02:e6:59:ae:f7:cb type macvlan mode bridge
ip link set onv22_f7cb up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv22_f7cb via DHCP..."
    dhclient -v onv22_f7cb &
else
    echo "Assigning static IP 192.168.6.24/24 to onv22_f7cb..."
    ip addr add 192.168.6.24/24 dev onv22_f7cb
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv22_f7cb/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv22_f7cb/arp_announce

echo "Creating macvlan interface onv23_940e..."
ip link add onv23_940e link $PHYS_IFACE address 02:4a:b7:ec:94:0e type macvlan mode bridge
ip link set onv23_940e up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv23_940e via DHCP..."
    dhclient -v onv23_940e &
else
    echo "Assigning static IP 192.168.6.25/24 to onv23_940e..."
    ip addr add 192.168.6.25/24 dev onv23_940e
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv23_940e/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv23_940e/arp_announce

echo "Creating macvlan interface onv24_7e17..."
ip link add onv24_7e17 link $PHYS_IFACE address 02:1c:0c:6f:7e:17 type macvlan mode bridge
ip link set onv24_7e17 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv24_7e17 via DHCP..."
    dhclient -v onv24_7e17 &
else
    echo "Assigning static IP 192.168.6.26/24 to onv24_7e17..."
    ip addr add 192.168.6.26/24 dev onv24_7e17
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv24_7e17/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv24_7e17/arp_announce

echo "Creating macvlan interface onv25_115b..."
ip link add onv25_115b link $PHYS_IFACE address 02:f7:53:82:11:5b type macvlan mode bridge
ip link set onv25_115b up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv25_115b via DHCP..."
    dhclient -v onv25_115b &
else
    echo "Assigning static IP 192.168.6.27/24 to onv25_115b..."
    ip addr add 192.168.6.27/24 dev onv25_115b
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv25_115b/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv25_115b/arp_announce

echo "Creating macvlan interface onv26_a614..."
ip link add onv26_a614 link $PHYS_IFACE address 02:a4:c8:2a:a6:14 type macvlan mode bridge
ip link set onv26_a614 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv26_a614 via DHCP..."
    dhclient -v onv26_a614 &
else
    echo "Assigning static IP 192.168.6.28/24 to onv26_a614..."
    ip addr add 192.168.6.28/24 dev onv26_a614
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv26_a614/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv26_a614/arp_announce

echo "Creating macvlan interface onv27_1edb..."
ip link add onv27_1edb link $PHYS_IFACE address 02:53:98:1d:1e:db type macvlan mode bridge
ip link set onv27_1edb up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv27_1edb via DHCP..."
    dhclient -v onv27_1edb &
else
    echo "Assigning static IP 192.168.6.29/24 to onv27_1edb..."
    ip addr add 192.168.6.29/24 dev onv27_1edb
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv27_1edb/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv27_1edb/arp_announce

echo "Creating macvlan interface onv28_336f..."
ip link add onv28_336f link $PHYS_IFACE address 02:d7:88:0d:33:6f type macvlan mode bridge
ip link set onv28_336f up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv28_336f via DHCP..."
    dhclient -v onv28_336f &
else
    echo "Assigning static IP 192.168.6.30/24 to onv28_336f..."
    ip addr add 192.168.6.30/24 dev onv28_336f
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv28_336f/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv28_336f/arp_announce

echo "Creating macvlan interface onv29_ec72..."
ip link add onv29_ec72 link $PHYS_IFACE address 02:c3:5b:fb:ec:72 type macvlan mode bridge
ip link set onv29_ec72 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv29_ec72 via DHCP..."
    dhclient -v onv29_ec72 &
else
    echo "Assigning static IP 192.168.6.31/24 to onv29_ec72..."
    ip addr add 192.168.6.31/24 dev onv29_ec72
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv29_ec72/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv29_ec72/arp_announce

echo "Creating macvlan interface onv30_bc3a..."
ip link add onv30_bc3a link $PHYS_IFACE address 02:29:3d:11:bc:3a type macvlan mode bridge
ip link set onv30_bc3a up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv30_bc3a via DHCP..."
    dhclient -v onv30_bc3a &
else
    echo "Assigning static IP 192.168.6.32/24 to onv30_bc3a..."
    ip addr add 192.168.6.32/24 dev onv30_bc3a
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv30_bc3a/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv30_bc3a/arp_announce

echo "Creating macvlan interface onv31_54b3..."
ip link add onv31_54b3 link $PHYS_IFACE address 02:0f:dc:bc:54:b3 type macvlan mode bridge
ip link set onv31_54b3 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv31_54b3 via DHCP..."
    dhclient -v onv31_54b3 &
else
    echo "Assigning static IP 192.168.6.33/24 to onv31_54b3..."
    ip addr add 192.168.6.33/24 dev onv31_54b3
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv31_54b3/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv31_54b3/arp_announce

echo "Creating macvlan interface onv32_5b68..."
ip link add onv32_5b68 link $PHYS_IFACE address 02:d0:19:ba:5b:68 type macvlan mode bridge
ip link set onv32_5b68 up
if [ "$USE_DHCP" = true ]; then
    echo "Requesting IP address for onv32_5b68 via DHCP..."
    dhclient -v onv32_5b68 &
else
    echo "Assigning static IP 192.168.6.34/24 to onv32_5b68..."
    ip addr add 192.168.6.34/24 dev onv32_5b68
fi

# Configure ARP to prevent issues with multiple interfaces
echo "Configuring ARP settings..."
echo 1 > /proc/sys/net/ipv4/conf/onv32_5b68/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv32_5b68/arp_announce

# Wait for IP assignment to complete and display IP addresses
sleep 3
echo "Virtual interface IP addresses:"
ip -4 addr show | grep -A 2 "onv" | grep -v "valid_lft"

echo "To use static IP addresses instead of DHCP, run: sudo $0 --static"
