#!/bin/bash

# Combined network setup script for multiple ONVIF virtual interfaces
# Generated for NVRs: 192.168.6.201, 192.168.6.202, 192.168.6.204
# Generated on: 2025-04-17T14:43:50.903Z

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
02:cc:00:d2:a6:c3 onv33_a6c3 192.168.6.35
02:c9:54:34:84:df onv34_84df 192.168.6.36
02:90:67:6b:60:43 onv35_6043 192.168.6.37
02:6f:ea:dc:25:89 onv36_2589 192.168.6.38
02:27:2b:64:d0:20 onv37_d020 192.168.6.39
02:92:d2:00:e6:ae onv38_e6ae 192.168.6.40
02:37:e5:a8:a6:04 onv39_a604 192.168.6.41
02:bc:83:1a:dc:a0 onv40_dca0 192.168.6.42
02:eb:6c:a6:68:8a onv41_688a 192.168.6.43
02:39:b8:15:6a:af onv42_6aaf 192.168.6.44
02:c8:5b:d2:94:9e onv43_949e 192.168.6.45
02:ff:43:d3:a5:6d onv44_a56d 192.168.6.46
02:50:e1:ff:17:7e onv45_177e 192.168.6.47
02:6e:97:6b:39:e3 onv46_39e3 192.168.6.48
02:f8:26:39:03:d0 onv47_03d0 192.168.6.49
02:80:c4:d4:58:00 onv48_5800 192.168.6.50
02:6c:7c:51:4a:6c onv49_4a6c 192.168.6.51
02:b5:d3:59:6d:bd onv50_6dbd 192.168.6.52
02:4c:f8:89:fa:84 onv51_fa84 192.168.6.53
02:82:f7:19:d6:f1 onv52_d6f1 192.168.6.54
02:7e:89:ae:44:e8 onv53_44e8 192.168.6.55
02:a0:63:ad:b1:b3 onv54_b1b3 192.168.6.56
02:e1:6c:9f:03:bc onv55_03bc 192.168.6.57
02:8e:6d:14:07:3c onv56_073c 192.168.6.58
02:b0:6e:26:a2:e4 onv57_a2e4 192.168.6.59
02:46:2f:98:d7:54 onv58_d754 192.168.6.60
02:3a:1e:84:f3:c2 onv59_f3c2 192.168.6.61
02:a3:bc:f6:98:a9 onv60_98a9 192.168.6.62
02:24:14:61:07:0d onv61_070d 192.168.6.63
02:a3:ae:c0:be:3c onv62_be3c 192.168.6.64
02:b0:46:fe:30:9d onv63_309d 192.168.6.65
02:b6:10:34:57:93 onv64_5793 192.168.6.66
02:bb:98:b9:82:19 onv65_8219 192.168.6.67
02:24:71:07:ae:ac onv66_aeac 192.168.6.68
02:90:98:73:cd:28 onv67_cd28 192.168.6.69
02:6a:9d:c1:d5:73 onv68_d573 192.168.6.70
02:e2:45:72:05:71 onv69_0571 192.168.6.71
02:50:e8:40:c0:87 onv70_c087 192.168.6.72
02:98:a9:71:83:b6 onv71_83b6 192.168.6.73
02:3b:8a:2e:56:ea onv72_56ea 192.168.6.74
02:c1:b2:86:21:71 onv73_2171 192.168.6.75
02:02:f6:54:16:69 onv74_1669 192.168.6.76
02:bd:6c:9e:96:16 onv75_9616 192.168.6.77
02:0f:b3:45:69:5c onv76_695c 192.168.6.78
02:8a:8f:f6:b8:34 onv77_b834 192.168.6.79
02:fb:78:8e:91:ee onv78_91ee 192.168.6.80
02:0d:ba:c1:63:b2 onv79_63b2 192.168.6.81
02:91:59:0f:42:45 onv80_4245 192.168.6.82
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
ip link show onv33_a6c3 > /dev/null 2>&1 && ip link delete onv33_a6c3
ip link show onv34_84df > /dev/null 2>&1 && ip link delete onv34_84df
ip link show onv35_6043 > /dev/null 2>&1 && ip link delete onv35_6043
ip link show onv36_2589 > /dev/null 2>&1 && ip link delete onv36_2589
ip link show onv37_d020 > /dev/null 2>&1 && ip link delete onv37_d020
ip link show onv38_e6ae > /dev/null 2>&1 && ip link delete onv38_e6ae
ip link show onv39_a604 > /dev/null 2>&1 && ip link delete onv39_a604
ip link show onv40_dca0 > /dev/null 2>&1 && ip link delete onv40_dca0
ip link show onv41_688a > /dev/null 2>&1 && ip link delete onv41_688a
ip link show onv42_6aaf > /dev/null 2>&1 && ip link delete onv42_6aaf
ip link show onv43_949e > /dev/null 2>&1 && ip link delete onv43_949e
ip link show onv44_a56d > /dev/null 2>&1 && ip link delete onv44_a56d
ip link show onv45_177e > /dev/null 2>&1 && ip link delete onv45_177e
ip link show onv46_39e3 > /dev/null 2>&1 && ip link delete onv46_39e3
ip link show onv47_03d0 > /dev/null 2>&1 && ip link delete onv47_03d0
ip link show onv48_5800 > /dev/null 2>&1 && ip link delete onv48_5800
ip link show onv49_4a6c > /dev/null 2>&1 && ip link delete onv49_4a6c
ip link show onv50_6dbd > /dev/null 2>&1 && ip link delete onv50_6dbd
ip link show onv51_fa84 > /dev/null 2>&1 && ip link delete onv51_fa84
ip link show onv52_d6f1 > /dev/null 2>&1 && ip link delete onv52_d6f1
ip link show onv53_44e8 > /dev/null 2>&1 && ip link delete onv53_44e8
ip link show onv54_b1b3 > /dev/null 2>&1 && ip link delete onv54_b1b3
ip link show onv55_03bc > /dev/null 2>&1 && ip link delete onv55_03bc
ip link show onv56_073c > /dev/null 2>&1 && ip link delete onv56_073c
ip link show onv57_a2e4 > /dev/null 2>&1 && ip link delete onv57_a2e4
ip link show onv58_d754 > /dev/null 2>&1 && ip link delete onv58_d754
ip link show onv59_f3c2 > /dev/null 2>&1 && ip link delete onv59_f3c2
ip link show onv60_98a9 > /dev/null 2>&1 && ip link delete onv60_98a9
ip link show onv61_070d > /dev/null 2>&1 && ip link delete onv61_070d
ip link show onv62_be3c > /dev/null 2>&1 && ip link delete onv62_be3c
ip link show onv63_309d > /dev/null 2>&1 && ip link delete onv63_309d
ip link show onv64_5793 > /dev/null 2>&1 && ip link delete onv64_5793
ip link show onv65_8219 > /dev/null 2>&1 && ip link delete onv65_8219
ip link show onv66_aeac > /dev/null 2>&1 && ip link delete onv66_aeac
ip link show onv67_cd28 > /dev/null 2>&1 && ip link delete onv67_cd28
ip link show onv68_d573 > /dev/null 2>&1 && ip link delete onv68_d573
ip link show onv69_0571 > /dev/null 2>&1 && ip link delete onv69_0571
ip link show onv70_c087 > /dev/null 2>&1 && ip link delete onv70_c087
ip link show onv71_83b6 > /dev/null 2>&1 && ip link delete onv71_83b6
ip link show onv72_56ea > /dev/null 2>&1 && ip link delete onv72_56ea
ip link show onv73_2171 > /dev/null 2>&1 && ip link delete onv73_2171
ip link show onv74_1669 > /dev/null 2>&1 && ip link delete onv74_1669
ip link show onv75_9616 > /dev/null 2>&1 && ip link delete onv75_9616
ip link show onv76_695c > /dev/null 2>&1 && ip link delete onv76_695c
ip link show onv77_b834 > /dev/null 2>&1 && ip link delete onv77_b834
ip link show onv78_91ee > /dev/null 2>&1 && ip link delete onv78_91ee
ip link show onv79_63b2 > /dev/null 2>&1 && ip link delete onv79_63b2
ip link show onv80_4245 > /dev/null 2>&1 && ip link delete onv80_4245

# Create new virtual interfaces
# Helper function to verify interface creation and IP assignment
verify_interface() {
    local iface=$1
    local ip=$2
    local max_attempts=30
    local delay=0.5
    local attempt=1

    echo "Verifying interface $iface with IP $ip..."

    # First verify the interface exists
    while [ $attempt -le $max_attempts ]; do
        if ip link show $iface &>/dev/null; then
            echo "  Interface $iface exists. Checking IP address..."
            break
        fi
        echo "  Waiting for interface $iface to be created (attempt $attempt/$max_attempts)"
        sleep $delay
        attempt=$((attempt+1))
    done

    if ! ip link show $iface &>/dev/null; then
        echo "  ERROR: Interface $iface could not be created after $max_attempts attempts!"
        return 1
    fi

    # Now verify IP address is assigned
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if ip addr show $iface | grep -q "$ip"; then
            echo "  Success: Interface $iface has IP address $ip"
            return 0
        fi
        echo "  Waiting for IP $ip to be assigned to $iface (attempt $attempt/$max_attempts)"
        sleep $delay
        attempt=$((attempt+1))
    done

    echo "  ERROR: IP address $ip could not be assigned to $iface after $max_attempts attempts!"
    return 1
}

echo "Creating interface 1/80: onv1_dbb4"
ip link add onv1_dbb4 link $PHYS_IFACE address 02:28:5c:53:db:b4 type macvlan mode bridge
ip link set onv1_dbb4 up
echo "Assigning static IP 192.168.6.3/24 to onv1_dbb4..."
ip addr add 192.168.6.3/24 dev onv1_dbb4
echo 1 > /proc/sys/net/ipv4/conf/onv1_dbb4/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv1_dbb4/arp_announce

verify_interface onv1_dbb4 192.168.6.3
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv1_dbb4 or IP 192.168.6.3 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 2/80: onv2_628d"
ip link add onv2_628d link $PHYS_IFACE address 02:ca:fe:ba:62:8d type macvlan mode bridge
ip link set onv2_628d up
echo "Assigning static IP 192.168.6.4/24 to onv2_628d..."
ip addr add 192.168.6.4/24 dev onv2_628d
echo 1 > /proc/sys/net/ipv4/conf/onv2_628d/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv2_628d/arp_announce

verify_interface onv2_628d 192.168.6.4
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv2_628d or IP 192.168.6.4 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 3/80: onv3_fad9"
ip link add onv3_fad9 link $PHYS_IFACE address 02:b0:82:62:fa:d9 type macvlan mode bridge
ip link set onv3_fad9 up
echo "Assigning static IP 192.168.6.5/24 to onv3_fad9..."
ip addr add 192.168.6.5/24 dev onv3_fad9
echo 1 > /proc/sys/net/ipv4/conf/onv3_fad9/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv3_fad9/arp_announce

verify_interface onv3_fad9 192.168.6.5
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv3_fad9 or IP 192.168.6.5 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 4/80: onv4_2475"
ip link add onv4_2475 link $PHYS_IFACE address 02:09:84:94:24:75 type macvlan mode bridge
ip link set onv4_2475 up
echo "Assigning static IP 192.168.6.6/24 to onv4_2475..."
ip addr add 192.168.6.6/24 dev onv4_2475
echo 1 > /proc/sys/net/ipv4/conf/onv4_2475/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv4_2475/arp_announce

verify_interface onv4_2475 192.168.6.6
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv4_2475 or IP 192.168.6.6 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 5/80: onv5_5093"
ip link add onv5_5093 link $PHYS_IFACE address 02:20:5c:60:50:93 type macvlan mode bridge
ip link set onv5_5093 up
echo "Assigning static IP 192.168.6.7/24 to onv5_5093..."
ip addr add 192.168.6.7/24 dev onv5_5093
echo 1 > /proc/sys/net/ipv4/conf/onv5_5093/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv5_5093/arp_announce

verify_interface onv5_5093 192.168.6.7
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv5_5093 or IP 192.168.6.7 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 6/80: onv6_cbb4"
ip link add onv6_cbb4 link $PHYS_IFACE address 02:6f:cb:19:cb:b4 type macvlan mode bridge
ip link set onv6_cbb4 up
echo "Assigning static IP 192.168.6.8/24 to onv6_cbb4..."
ip addr add 192.168.6.8/24 dev onv6_cbb4
echo 1 > /proc/sys/net/ipv4/conf/onv6_cbb4/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv6_cbb4/arp_announce

verify_interface onv6_cbb4 192.168.6.8
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv6_cbb4 or IP 192.168.6.8 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 7/80: onv7_21cb"
ip link add onv7_21cb link $PHYS_IFACE address 02:8e:81:a6:21:cb type macvlan mode bridge
ip link set onv7_21cb up
echo "Assigning static IP 192.168.6.9/24 to onv7_21cb..."
ip addr add 192.168.6.9/24 dev onv7_21cb
echo 1 > /proc/sys/net/ipv4/conf/onv7_21cb/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv7_21cb/arp_announce

verify_interface onv7_21cb 192.168.6.9
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv7_21cb or IP 192.168.6.9 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 8/80: onv8_69e3"
ip link add onv8_69e3 link $PHYS_IFACE address 02:0b:70:bd:69:e3 type macvlan mode bridge
ip link set onv8_69e3 up
echo "Assigning static IP 192.168.6.10/24 to onv8_69e3..."
ip addr add 192.168.6.10/24 dev onv8_69e3
echo 1 > /proc/sys/net/ipv4/conf/onv8_69e3/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv8_69e3/arp_announce

verify_interface onv8_69e3 192.168.6.10
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv8_69e3 or IP 192.168.6.10 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 9/80: onv9_2912"
ip link add onv9_2912 link $PHYS_IFACE address 02:7e:32:58:29:12 type macvlan mode bridge
ip link set onv9_2912 up
echo "Assigning static IP 192.168.6.11/24 to onv9_2912..."
ip addr add 192.168.6.11/24 dev onv9_2912
echo 1 > /proc/sys/net/ipv4/conf/onv9_2912/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv9_2912/arp_announce

verify_interface onv9_2912 192.168.6.11
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv9_2912 or IP 192.168.6.11 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 10/80: onv10_1b73"
ip link add onv10_1b73 link $PHYS_IFACE address 02:cd:47:13:1b:73 type macvlan mode bridge
ip link set onv10_1b73 up
echo "Assigning static IP 192.168.6.12/24 to onv10_1b73..."
ip addr add 192.168.6.12/24 dev onv10_1b73
echo 1 > /proc/sys/net/ipv4/conf/onv10_1b73/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv10_1b73/arp_announce

verify_interface onv10_1b73 192.168.6.12
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv10_1b73 or IP 192.168.6.12 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 11/80: onv11_a6fc"
ip link add onv11_a6fc link $PHYS_IFACE address 02:af:df:dd:a6:fc type macvlan mode bridge
ip link set onv11_a6fc up
echo "Assigning static IP 192.168.6.13/24 to onv11_a6fc..."
ip addr add 192.168.6.13/24 dev onv11_a6fc
echo 1 > /proc/sys/net/ipv4/conf/onv11_a6fc/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv11_a6fc/arp_announce

verify_interface onv11_a6fc 192.168.6.13
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv11_a6fc or IP 192.168.6.13 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 12/80: onv12_f9b6"
ip link add onv12_f9b6 link $PHYS_IFACE address 02:0e:71:51:f9:b6 type macvlan mode bridge
ip link set onv12_f9b6 up
echo "Assigning static IP 192.168.6.14/24 to onv12_f9b6..."
ip addr add 192.168.6.14/24 dev onv12_f9b6
echo 1 > /proc/sys/net/ipv4/conf/onv12_f9b6/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv12_f9b6/arp_announce

verify_interface onv12_f9b6 192.168.6.14
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv12_f9b6 or IP 192.168.6.14 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 13/80: onv13_c6b4"
ip link add onv13_c6b4 link $PHYS_IFACE address 02:dd:ac:2e:c6:b4 type macvlan mode bridge
ip link set onv13_c6b4 up
echo "Assigning static IP 192.168.6.15/24 to onv13_c6b4..."
ip addr add 192.168.6.15/24 dev onv13_c6b4
echo 1 > /proc/sys/net/ipv4/conf/onv13_c6b4/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv13_c6b4/arp_announce

verify_interface onv13_c6b4 192.168.6.15
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv13_c6b4 or IP 192.168.6.15 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 14/80: onv14_dfd2"
ip link add onv14_dfd2 link $PHYS_IFACE address 02:59:a5:04:df:d2 type macvlan mode bridge
ip link set onv14_dfd2 up
echo "Assigning static IP 192.168.6.16/24 to onv14_dfd2..."
ip addr add 192.168.6.16/24 dev onv14_dfd2
echo 1 > /proc/sys/net/ipv4/conf/onv14_dfd2/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv14_dfd2/arp_announce

verify_interface onv14_dfd2 192.168.6.16
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv14_dfd2 or IP 192.168.6.16 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 15/80: onv15_8e96"
ip link add onv15_8e96 link $PHYS_IFACE address 02:fd:fc:0e:8e:96 type macvlan mode bridge
ip link set onv15_8e96 up
echo "Assigning static IP 192.168.6.17/24 to onv15_8e96..."
ip addr add 192.168.6.17/24 dev onv15_8e96
echo 1 > /proc/sys/net/ipv4/conf/onv15_8e96/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv15_8e96/arp_announce

verify_interface onv15_8e96 192.168.6.17
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv15_8e96 or IP 192.168.6.17 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 16/80: onv16_321b"
ip link add onv16_321b link $PHYS_IFACE address 02:a1:ef:84:32:1b type macvlan mode bridge
ip link set onv16_321b up
echo "Assigning static IP 192.168.6.18/24 to onv16_321b..."
ip addr add 192.168.6.18/24 dev onv16_321b
echo 1 > /proc/sys/net/ipv4/conf/onv16_321b/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv16_321b/arp_announce

verify_interface onv16_321b 192.168.6.18
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv16_321b or IP 192.168.6.18 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 17/80: onv17_dcb2"
ip link add onv17_dcb2 link $PHYS_IFACE address 02:1f:4a:4d:dc:b2 type macvlan mode bridge
ip link set onv17_dcb2 up
echo "Assigning static IP 192.168.6.19/24 to onv17_dcb2..."
ip addr add 192.168.6.19/24 dev onv17_dcb2
echo 1 > /proc/sys/net/ipv4/conf/onv17_dcb2/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv17_dcb2/arp_announce

verify_interface onv17_dcb2 192.168.6.19
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv17_dcb2 or IP 192.168.6.19 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 18/80: onv18_8ae4"
ip link add onv18_8ae4 link $PHYS_IFACE address 02:6c:df:c2:8a:e4 type macvlan mode bridge
ip link set onv18_8ae4 up
echo "Assigning static IP 192.168.6.20/24 to onv18_8ae4..."
ip addr add 192.168.6.20/24 dev onv18_8ae4
echo 1 > /proc/sys/net/ipv4/conf/onv18_8ae4/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv18_8ae4/arp_announce

verify_interface onv18_8ae4 192.168.6.20
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv18_8ae4 or IP 192.168.6.20 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 19/80: onv19_9313"
ip link add onv19_9313 link $PHYS_IFACE address 02:78:5d:1d:93:13 type macvlan mode bridge
ip link set onv19_9313 up
echo "Assigning static IP 192.168.6.21/24 to onv19_9313..."
ip addr add 192.168.6.21/24 dev onv19_9313
echo 1 > /proc/sys/net/ipv4/conf/onv19_9313/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv19_9313/arp_announce

verify_interface onv19_9313 192.168.6.21
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv19_9313 or IP 192.168.6.21 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 20/80: onv20_6c12"
ip link add onv20_6c12 link $PHYS_IFACE address 02:72:0e:1c:6c:12 type macvlan mode bridge
ip link set onv20_6c12 up
echo "Assigning static IP 192.168.6.22/24 to onv20_6c12..."
ip addr add 192.168.6.22/24 dev onv20_6c12
echo 1 > /proc/sys/net/ipv4/conf/onv20_6c12/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv20_6c12/arp_announce

verify_interface onv20_6c12 192.168.6.22
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv20_6c12 or IP 192.168.6.22 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 21/80: onv21_ad20"
ip link add onv21_ad20 link $PHYS_IFACE address 02:aa:e1:92:ad:20 type macvlan mode bridge
ip link set onv21_ad20 up
echo "Assigning static IP 192.168.6.23/24 to onv21_ad20..."
ip addr add 192.168.6.23/24 dev onv21_ad20
echo 1 > /proc/sys/net/ipv4/conf/onv21_ad20/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv21_ad20/arp_announce

verify_interface onv21_ad20 192.168.6.23
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv21_ad20 or IP 192.168.6.23 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 22/80: onv22_f7cb"
ip link add onv22_f7cb link $PHYS_IFACE address 02:e6:59:ae:f7:cb type macvlan mode bridge
ip link set onv22_f7cb up
echo "Assigning static IP 192.168.6.24/24 to onv22_f7cb..."
ip addr add 192.168.6.24/24 dev onv22_f7cb
echo 1 > /proc/sys/net/ipv4/conf/onv22_f7cb/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv22_f7cb/arp_announce

verify_interface onv22_f7cb 192.168.6.24
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv22_f7cb or IP 192.168.6.24 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 23/80: onv23_940e"
ip link add onv23_940e link $PHYS_IFACE address 02:4a:b7:ec:94:0e type macvlan mode bridge
ip link set onv23_940e up
echo "Assigning static IP 192.168.6.25/24 to onv23_940e..."
ip addr add 192.168.6.25/24 dev onv23_940e
echo 1 > /proc/sys/net/ipv4/conf/onv23_940e/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv23_940e/arp_announce

verify_interface onv23_940e 192.168.6.25
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv23_940e or IP 192.168.6.25 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 24/80: onv24_7e17"
ip link add onv24_7e17 link $PHYS_IFACE address 02:1c:0c:6f:7e:17 type macvlan mode bridge
ip link set onv24_7e17 up
echo "Assigning static IP 192.168.6.26/24 to onv24_7e17..."
ip addr add 192.168.6.26/24 dev onv24_7e17
echo 1 > /proc/sys/net/ipv4/conf/onv24_7e17/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv24_7e17/arp_announce

verify_interface onv24_7e17 192.168.6.26
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv24_7e17 or IP 192.168.6.26 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 25/80: onv25_115b"
ip link add onv25_115b link $PHYS_IFACE address 02:f7:53:82:11:5b type macvlan mode bridge
ip link set onv25_115b up
echo "Assigning static IP 192.168.6.27/24 to onv25_115b..."
ip addr add 192.168.6.27/24 dev onv25_115b
echo 1 > /proc/sys/net/ipv4/conf/onv25_115b/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv25_115b/arp_announce

verify_interface onv25_115b 192.168.6.27
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv25_115b or IP 192.168.6.27 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 26/80: onv26_a614"
ip link add onv26_a614 link $PHYS_IFACE address 02:a4:c8:2a:a6:14 type macvlan mode bridge
ip link set onv26_a614 up
echo "Assigning static IP 192.168.6.28/24 to onv26_a614..."
ip addr add 192.168.6.28/24 dev onv26_a614
echo 1 > /proc/sys/net/ipv4/conf/onv26_a614/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv26_a614/arp_announce

verify_interface onv26_a614 192.168.6.28
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv26_a614 or IP 192.168.6.28 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 27/80: onv27_1edb"
ip link add onv27_1edb link $PHYS_IFACE address 02:53:98:1d:1e:db type macvlan mode bridge
ip link set onv27_1edb up
echo "Assigning static IP 192.168.6.29/24 to onv27_1edb..."
ip addr add 192.168.6.29/24 dev onv27_1edb
echo 1 > /proc/sys/net/ipv4/conf/onv27_1edb/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv27_1edb/arp_announce

verify_interface onv27_1edb 192.168.6.29
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv27_1edb or IP 192.168.6.29 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 28/80: onv28_336f"
ip link add onv28_336f link $PHYS_IFACE address 02:d7:88:0d:33:6f type macvlan mode bridge
ip link set onv28_336f up
echo "Assigning static IP 192.168.6.30/24 to onv28_336f..."
ip addr add 192.168.6.30/24 dev onv28_336f
echo 1 > /proc/sys/net/ipv4/conf/onv28_336f/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv28_336f/arp_announce

verify_interface onv28_336f 192.168.6.30
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv28_336f or IP 192.168.6.30 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 29/80: onv29_ec72"
ip link add onv29_ec72 link $PHYS_IFACE address 02:c3:5b:fb:ec:72 type macvlan mode bridge
ip link set onv29_ec72 up
echo "Assigning static IP 192.168.6.31/24 to onv29_ec72..."
ip addr add 192.168.6.31/24 dev onv29_ec72
echo 1 > /proc/sys/net/ipv4/conf/onv29_ec72/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv29_ec72/arp_announce

verify_interface onv29_ec72 192.168.6.31
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv29_ec72 or IP 192.168.6.31 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 30/80: onv30_bc3a"
ip link add onv30_bc3a link $PHYS_IFACE address 02:29:3d:11:bc:3a type macvlan mode bridge
ip link set onv30_bc3a up
echo "Assigning static IP 192.168.6.32/24 to onv30_bc3a..."
ip addr add 192.168.6.32/24 dev onv30_bc3a
echo 1 > /proc/sys/net/ipv4/conf/onv30_bc3a/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv30_bc3a/arp_announce

verify_interface onv30_bc3a 192.168.6.32
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv30_bc3a or IP 192.168.6.32 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 31/80: onv31_54b3"
ip link add onv31_54b3 link $PHYS_IFACE address 02:0f:dc:bc:54:b3 type macvlan mode bridge
ip link set onv31_54b3 up
echo "Assigning static IP 192.168.6.33/24 to onv31_54b3..."
ip addr add 192.168.6.33/24 dev onv31_54b3
echo 1 > /proc/sys/net/ipv4/conf/onv31_54b3/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv31_54b3/arp_announce

verify_interface onv31_54b3 192.168.6.33
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv31_54b3 or IP 192.168.6.33 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 32/80: onv32_5b68"
ip link add onv32_5b68 link $PHYS_IFACE address 02:d0:19:ba:5b:68 type macvlan mode bridge
ip link set onv32_5b68 up
echo "Assigning static IP 192.168.6.34/24 to onv32_5b68..."
ip addr add 192.168.6.34/24 dev onv32_5b68
echo 1 > /proc/sys/net/ipv4/conf/onv32_5b68/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv32_5b68/arp_announce

verify_interface onv32_5b68 192.168.6.34
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv32_5b68 or IP 192.168.6.34 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 33/80: onv33_a6c3"
ip link add onv33_a6c3 link $PHYS_IFACE address 02:cc:00:d2:a6:c3 type macvlan mode bridge
ip link set onv33_a6c3 up
echo "Assigning static IP 192.168.6.35/24 to onv33_a6c3..."
ip addr add 192.168.6.35/24 dev onv33_a6c3
echo 1 > /proc/sys/net/ipv4/conf/onv33_a6c3/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv33_a6c3/arp_announce

verify_interface onv33_a6c3 192.168.6.35
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv33_a6c3 or IP 192.168.6.35 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 34/80: onv34_84df"
ip link add onv34_84df link $PHYS_IFACE address 02:c9:54:34:84:df type macvlan mode bridge
ip link set onv34_84df up
echo "Assigning static IP 192.168.6.36/24 to onv34_84df..."
ip addr add 192.168.6.36/24 dev onv34_84df
echo 1 > /proc/sys/net/ipv4/conf/onv34_84df/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv34_84df/arp_announce

verify_interface onv34_84df 192.168.6.36
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv34_84df or IP 192.168.6.36 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 35/80: onv35_6043"
ip link add onv35_6043 link $PHYS_IFACE address 02:90:67:6b:60:43 type macvlan mode bridge
ip link set onv35_6043 up
echo "Assigning static IP 192.168.6.37/24 to onv35_6043..."
ip addr add 192.168.6.37/24 dev onv35_6043
echo 1 > /proc/sys/net/ipv4/conf/onv35_6043/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv35_6043/arp_announce

verify_interface onv35_6043 192.168.6.37
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv35_6043 or IP 192.168.6.37 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 36/80: onv36_2589"
ip link add onv36_2589 link $PHYS_IFACE address 02:6f:ea:dc:25:89 type macvlan mode bridge
ip link set onv36_2589 up
echo "Assigning static IP 192.168.6.38/24 to onv36_2589..."
ip addr add 192.168.6.38/24 dev onv36_2589
echo 1 > /proc/sys/net/ipv4/conf/onv36_2589/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv36_2589/arp_announce

verify_interface onv36_2589 192.168.6.38
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv36_2589 or IP 192.168.6.38 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 37/80: onv37_d020"
ip link add onv37_d020 link $PHYS_IFACE address 02:27:2b:64:d0:20 type macvlan mode bridge
ip link set onv37_d020 up
echo "Assigning static IP 192.168.6.39/24 to onv37_d020..."
ip addr add 192.168.6.39/24 dev onv37_d020
echo 1 > /proc/sys/net/ipv4/conf/onv37_d020/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv37_d020/arp_announce

verify_interface onv37_d020 192.168.6.39
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv37_d020 or IP 192.168.6.39 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 38/80: onv38_e6ae"
ip link add onv38_e6ae link $PHYS_IFACE address 02:92:d2:00:e6:ae type macvlan mode bridge
ip link set onv38_e6ae up
echo "Assigning static IP 192.168.6.40/24 to onv38_e6ae..."
ip addr add 192.168.6.40/24 dev onv38_e6ae
echo 1 > /proc/sys/net/ipv4/conf/onv38_e6ae/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv38_e6ae/arp_announce

verify_interface onv38_e6ae 192.168.6.40
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv38_e6ae or IP 192.168.6.40 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 39/80: onv39_a604"
ip link add onv39_a604 link $PHYS_IFACE address 02:37:e5:a8:a6:04 type macvlan mode bridge
ip link set onv39_a604 up
echo "Assigning static IP 192.168.6.41/24 to onv39_a604..."
ip addr add 192.168.6.41/24 dev onv39_a604
echo 1 > /proc/sys/net/ipv4/conf/onv39_a604/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv39_a604/arp_announce

verify_interface onv39_a604 192.168.6.41
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv39_a604 or IP 192.168.6.41 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 40/80: onv40_dca0"
ip link add onv40_dca0 link $PHYS_IFACE address 02:bc:83:1a:dc:a0 type macvlan mode bridge
ip link set onv40_dca0 up
echo "Assigning static IP 192.168.6.42/24 to onv40_dca0..."
ip addr add 192.168.6.42/24 dev onv40_dca0
echo 1 > /proc/sys/net/ipv4/conf/onv40_dca0/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv40_dca0/arp_announce

verify_interface onv40_dca0 192.168.6.42
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv40_dca0 or IP 192.168.6.42 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 41/80: onv41_688a"
ip link add onv41_688a link $PHYS_IFACE address 02:eb:6c:a6:68:8a type macvlan mode bridge
ip link set onv41_688a up
echo "Assigning static IP 192.168.6.43/24 to onv41_688a..."
ip addr add 192.168.6.43/24 dev onv41_688a
echo 1 > /proc/sys/net/ipv4/conf/onv41_688a/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv41_688a/arp_announce

verify_interface onv41_688a 192.168.6.43
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv41_688a or IP 192.168.6.43 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 42/80: onv42_6aaf"
ip link add onv42_6aaf link $PHYS_IFACE address 02:39:b8:15:6a:af type macvlan mode bridge
ip link set onv42_6aaf up
echo "Assigning static IP 192.168.6.44/24 to onv42_6aaf..."
ip addr add 192.168.6.44/24 dev onv42_6aaf
echo 1 > /proc/sys/net/ipv4/conf/onv42_6aaf/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv42_6aaf/arp_announce

verify_interface onv42_6aaf 192.168.6.44
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv42_6aaf or IP 192.168.6.44 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 43/80: onv43_949e"
ip link add onv43_949e link $PHYS_IFACE address 02:c8:5b:d2:94:9e type macvlan mode bridge
ip link set onv43_949e up
echo "Assigning static IP 192.168.6.45/24 to onv43_949e..."
ip addr add 192.168.6.45/24 dev onv43_949e
echo 1 > /proc/sys/net/ipv4/conf/onv43_949e/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv43_949e/arp_announce

verify_interface onv43_949e 192.168.6.45
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv43_949e or IP 192.168.6.45 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 44/80: onv44_a56d"
ip link add onv44_a56d link $PHYS_IFACE address 02:ff:43:d3:a5:6d type macvlan mode bridge
ip link set onv44_a56d up
echo "Assigning static IP 192.168.6.46/24 to onv44_a56d..."
ip addr add 192.168.6.46/24 dev onv44_a56d
echo 1 > /proc/sys/net/ipv4/conf/onv44_a56d/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv44_a56d/arp_announce

verify_interface onv44_a56d 192.168.6.46
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv44_a56d or IP 192.168.6.46 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 45/80: onv45_177e"
ip link add onv45_177e link $PHYS_IFACE address 02:50:e1:ff:17:7e type macvlan mode bridge
ip link set onv45_177e up
echo "Assigning static IP 192.168.6.47/24 to onv45_177e..."
ip addr add 192.168.6.47/24 dev onv45_177e
echo 1 > /proc/sys/net/ipv4/conf/onv45_177e/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv45_177e/arp_announce

verify_interface onv45_177e 192.168.6.47
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv45_177e or IP 192.168.6.47 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 46/80: onv46_39e3"
ip link add onv46_39e3 link $PHYS_IFACE address 02:6e:97:6b:39:e3 type macvlan mode bridge
ip link set onv46_39e3 up
echo "Assigning static IP 192.168.6.48/24 to onv46_39e3..."
ip addr add 192.168.6.48/24 dev onv46_39e3
echo 1 > /proc/sys/net/ipv4/conf/onv46_39e3/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv46_39e3/arp_announce

verify_interface onv46_39e3 192.168.6.48
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv46_39e3 or IP 192.168.6.48 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 47/80: onv47_03d0"
ip link add onv47_03d0 link $PHYS_IFACE address 02:f8:26:39:03:d0 type macvlan mode bridge
ip link set onv47_03d0 up
echo "Assigning static IP 192.168.6.49/24 to onv47_03d0..."
ip addr add 192.168.6.49/24 dev onv47_03d0
echo 1 > /proc/sys/net/ipv4/conf/onv47_03d0/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv47_03d0/arp_announce

verify_interface onv47_03d0 192.168.6.49
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv47_03d0 or IP 192.168.6.49 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 48/80: onv48_5800"
ip link add onv48_5800 link $PHYS_IFACE address 02:80:c4:d4:58:00 type macvlan mode bridge
ip link set onv48_5800 up
echo "Assigning static IP 192.168.6.50/24 to onv48_5800..."
ip addr add 192.168.6.50/24 dev onv48_5800
echo 1 > /proc/sys/net/ipv4/conf/onv48_5800/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv48_5800/arp_announce

verify_interface onv48_5800 192.168.6.50
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv48_5800 or IP 192.168.6.50 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 49/80: onv49_4a6c"
ip link add onv49_4a6c link $PHYS_IFACE address 02:6c:7c:51:4a:6c type macvlan mode bridge
ip link set onv49_4a6c up
echo "Assigning static IP 192.168.6.51/24 to onv49_4a6c..."
ip addr add 192.168.6.51/24 dev onv49_4a6c
echo 1 > /proc/sys/net/ipv4/conf/onv49_4a6c/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv49_4a6c/arp_announce

verify_interface onv49_4a6c 192.168.6.51
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv49_4a6c or IP 192.168.6.51 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 50/80: onv50_6dbd"
ip link add onv50_6dbd link $PHYS_IFACE address 02:b5:d3:59:6d:bd type macvlan mode bridge
ip link set onv50_6dbd up
echo "Assigning static IP 192.168.6.52/24 to onv50_6dbd..."
ip addr add 192.168.6.52/24 dev onv50_6dbd
echo 1 > /proc/sys/net/ipv4/conf/onv50_6dbd/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv50_6dbd/arp_announce

verify_interface onv50_6dbd 192.168.6.52
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv50_6dbd or IP 192.168.6.52 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 51/80: onv51_fa84"
ip link add onv51_fa84 link $PHYS_IFACE address 02:4c:f8:89:fa:84 type macvlan mode bridge
ip link set onv51_fa84 up
echo "Assigning static IP 192.168.6.53/24 to onv51_fa84..."
ip addr add 192.168.6.53/24 dev onv51_fa84
echo 1 > /proc/sys/net/ipv4/conf/onv51_fa84/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv51_fa84/arp_announce

verify_interface onv51_fa84 192.168.6.53
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv51_fa84 or IP 192.168.6.53 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 52/80: onv52_d6f1"
ip link add onv52_d6f1 link $PHYS_IFACE address 02:82:f7:19:d6:f1 type macvlan mode bridge
ip link set onv52_d6f1 up
echo "Assigning static IP 192.168.6.54/24 to onv52_d6f1..."
ip addr add 192.168.6.54/24 dev onv52_d6f1
echo 1 > /proc/sys/net/ipv4/conf/onv52_d6f1/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv52_d6f1/arp_announce

verify_interface onv52_d6f1 192.168.6.54
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv52_d6f1 or IP 192.168.6.54 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 53/80: onv53_44e8"
ip link add onv53_44e8 link $PHYS_IFACE address 02:7e:89:ae:44:e8 type macvlan mode bridge
ip link set onv53_44e8 up
echo "Assigning static IP 192.168.6.55/24 to onv53_44e8..."
ip addr add 192.168.6.55/24 dev onv53_44e8
echo 1 > /proc/sys/net/ipv4/conf/onv53_44e8/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv53_44e8/arp_announce

verify_interface onv53_44e8 192.168.6.55
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv53_44e8 or IP 192.168.6.55 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 54/80: onv54_b1b3"
ip link add onv54_b1b3 link $PHYS_IFACE address 02:a0:63:ad:b1:b3 type macvlan mode bridge
ip link set onv54_b1b3 up
echo "Assigning static IP 192.168.6.56/24 to onv54_b1b3..."
ip addr add 192.168.6.56/24 dev onv54_b1b3
echo 1 > /proc/sys/net/ipv4/conf/onv54_b1b3/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv54_b1b3/arp_announce

verify_interface onv54_b1b3 192.168.6.56
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv54_b1b3 or IP 192.168.6.56 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 55/80: onv55_03bc"
ip link add onv55_03bc link $PHYS_IFACE address 02:e1:6c:9f:03:bc type macvlan mode bridge
ip link set onv55_03bc up
echo "Assigning static IP 192.168.6.57/24 to onv55_03bc..."
ip addr add 192.168.6.57/24 dev onv55_03bc
echo 1 > /proc/sys/net/ipv4/conf/onv55_03bc/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv55_03bc/arp_announce

verify_interface onv55_03bc 192.168.6.57
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv55_03bc or IP 192.168.6.57 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 56/80: onv56_073c"
ip link add onv56_073c link $PHYS_IFACE address 02:8e:6d:14:07:3c type macvlan mode bridge
ip link set onv56_073c up
echo "Assigning static IP 192.168.6.58/24 to onv56_073c..."
ip addr add 192.168.6.58/24 dev onv56_073c
echo 1 > /proc/sys/net/ipv4/conf/onv56_073c/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv56_073c/arp_announce

verify_interface onv56_073c 192.168.6.58
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv56_073c or IP 192.168.6.58 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 57/80: onv57_a2e4"
ip link add onv57_a2e4 link $PHYS_IFACE address 02:b0:6e:26:a2:e4 type macvlan mode bridge
ip link set onv57_a2e4 up
echo "Assigning static IP 192.168.6.59/24 to onv57_a2e4..."
ip addr add 192.168.6.59/24 dev onv57_a2e4
echo 1 > /proc/sys/net/ipv4/conf/onv57_a2e4/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv57_a2e4/arp_announce

verify_interface onv57_a2e4 192.168.6.59
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv57_a2e4 or IP 192.168.6.59 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 58/80: onv58_d754"
ip link add onv58_d754 link $PHYS_IFACE address 02:46:2f:98:d7:54 type macvlan mode bridge
ip link set onv58_d754 up
echo "Assigning static IP 192.168.6.60/24 to onv58_d754..."
ip addr add 192.168.6.60/24 dev onv58_d754
echo 1 > /proc/sys/net/ipv4/conf/onv58_d754/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv58_d754/arp_announce

verify_interface onv58_d754 192.168.6.60
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv58_d754 or IP 192.168.6.60 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 59/80: onv59_f3c2"
ip link add onv59_f3c2 link $PHYS_IFACE address 02:3a:1e:84:f3:c2 type macvlan mode bridge
ip link set onv59_f3c2 up
echo "Assigning static IP 192.168.6.61/24 to onv59_f3c2..."
ip addr add 192.168.6.61/24 dev onv59_f3c2
echo 1 > /proc/sys/net/ipv4/conf/onv59_f3c2/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv59_f3c2/arp_announce

verify_interface onv59_f3c2 192.168.6.61
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv59_f3c2 or IP 192.168.6.61 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 60/80: onv60_98a9"
ip link add onv60_98a9 link $PHYS_IFACE address 02:a3:bc:f6:98:a9 type macvlan mode bridge
ip link set onv60_98a9 up
echo "Assigning static IP 192.168.6.62/24 to onv60_98a9..."
ip addr add 192.168.6.62/24 dev onv60_98a9
echo 1 > /proc/sys/net/ipv4/conf/onv60_98a9/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv60_98a9/arp_announce

verify_interface onv60_98a9 192.168.6.62
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv60_98a9 or IP 192.168.6.62 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 61/80: onv61_070d"
ip link add onv61_070d link $PHYS_IFACE address 02:24:14:61:07:0d type macvlan mode bridge
ip link set onv61_070d up
echo "Assigning static IP 192.168.6.63/24 to onv61_070d..."
ip addr add 192.168.6.63/24 dev onv61_070d
echo 1 > /proc/sys/net/ipv4/conf/onv61_070d/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv61_070d/arp_announce

verify_interface onv61_070d 192.168.6.63
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv61_070d or IP 192.168.6.63 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 62/80: onv62_be3c"
ip link add onv62_be3c link $PHYS_IFACE address 02:a3:ae:c0:be:3c type macvlan mode bridge
ip link set onv62_be3c up
echo "Assigning static IP 192.168.6.64/24 to onv62_be3c..."
ip addr add 192.168.6.64/24 dev onv62_be3c
echo 1 > /proc/sys/net/ipv4/conf/onv62_be3c/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv62_be3c/arp_announce

verify_interface onv62_be3c 192.168.6.64
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv62_be3c or IP 192.168.6.64 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 63/80: onv63_309d"
ip link add onv63_309d link $PHYS_IFACE address 02:b0:46:fe:30:9d type macvlan mode bridge
ip link set onv63_309d up
echo "Assigning static IP 192.168.6.65/24 to onv63_309d..."
ip addr add 192.168.6.65/24 dev onv63_309d
echo 1 > /proc/sys/net/ipv4/conf/onv63_309d/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv63_309d/arp_announce

verify_interface onv63_309d 192.168.6.65
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv63_309d or IP 192.168.6.65 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 64/80: onv64_5793"
ip link add onv64_5793 link $PHYS_IFACE address 02:b6:10:34:57:93 type macvlan mode bridge
ip link set onv64_5793 up
echo "Assigning static IP 192.168.6.66/24 to onv64_5793..."
ip addr add 192.168.6.66/24 dev onv64_5793
echo 1 > /proc/sys/net/ipv4/conf/onv64_5793/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv64_5793/arp_announce

verify_interface onv64_5793 192.168.6.66
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv64_5793 or IP 192.168.6.66 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 65/80: onv65_8219"
ip link add onv65_8219 link $PHYS_IFACE address 02:bb:98:b9:82:19 type macvlan mode bridge
ip link set onv65_8219 up
echo "Assigning static IP 192.168.6.67/24 to onv65_8219..."
ip addr add 192.168.6.67/24 dev onv65_8219
echo 1 > /proc/sys/net/ipv4/conf/onv65_8219/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv65_8219/arp_announce

verify_interface onv65_8219 192.168.6.67
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv65_8219 or IP 192.168.6.67 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 66/80: onv66_aeac"
ip link add onv66_aeac link $PHYS_IFACE address 02:24:71:07:ae:ac type macvlan mode bridge
ip link set onv66_aeac up
echo "Assigning static IP 192.168.6.68/24 to onv66_aeac..."
ip addr add 192.168.6.68/24 dev onv66_aeac
echo 1 > /proc/sys/net/ipv4/conf/onv66_aeac/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv66_aeac/arp_announce

verify_interface onv66_aeac 192.168.6.68
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv66_aeac or IP 192.168.6.68 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 67/80: onv67_cd28"
ip link add onv67_cd28 link $PHYS_IFACE address 02:90:98:73:cd:28 type macvlan mode bridge
ip link set onv67_cd28 up
echo "Assigning static IP 192.168.6.69/24 to onv67_cd28..."
ip addr add 192.168.6.69/24 dev onv67_cd28
echo 1 > /proc/sys/net/ipv4/conf/onv67_cd28/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv67_cd28/arp_announce

verify_interface onv67_cd28 192.168.6.69
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv67_cd28 or IP 192.168.6.69 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 68/80: onv68_d573"
ip link add onv68_d573 link $PHYS_IFACE address 02:6a:9d:c1:d5:73 type macvlan mode bridge
ip link set onv68_d573 up
echo "Assigning static IP 192.168.6.70/24 to onv68_d573..."
ip addr add 192.168.6.70/24 dev onv68_d573
echo 1 > /proc/sys/net/ipv4/conf/onv68_d573/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv68_d573/arp_announce

verify_interface onv68_d573 192.168.6.70
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv68_d573 or IP 192.168.6.70 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 69/80: onv69_0571"
ip link add onv69_0571 link $PHYS_IFACE address 02:e2:45:72:05:71 type macvlan mode bridge
ip link set onv69_0571 up
echo "Assigning static IP 192.168.6.71/24 to onv69_0571..."
ip addr add 192.168.6.71/24 dev onv69_0571
echo 1 > /proc/sys/net/ipv4/conf/onv69_0571/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv69_0571/arp_announce

verify_interface onv69_0571 192.168.6.71
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv69_0571 or IP 192.168.6.71 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 70/80: onv70_c087"
ip link add onv70_c087 link $PHYS_IFACE address 02:50:e8:40:c0:87 type macvlan mode bridge
ip link set onv70_c087 up
echo "Assigning static IP 192.168.6.72/24 to onv70_c087..."
ip addr add 192.168.6.72/24 dev onv70_c087
echo 1 > /proc/sys/net/ipv4/conf/onv70_c087/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv70_c087/arp_announce

verify_interface onv70_c087 192.168.6.72
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv70_c087 or IP 192.168.6.72 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 71/80: onv71_83b6"
ip link add onv71_83b6 link $PHYS_IFACE address 02:98:a9:71:83:b6 type macvlan mode bridge
ip link set onv71_83b6 up
echo "Assigning static IP 192.168.6.73/24 to onv71_83b6..."
ip addr add 192.168.6.73/24 dev onv71_83b6
echo 1 > /proc/sys/net/ipv4/conf/onv71_83b6/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv71_83b6/arp_announce

verify_interface onv71_83b6 192.168.6.73
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv71_83b6 or IP 192.168.6.73 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 72/80: onv72_56ea"
ip link add onv72_56ea link $PHYS_IFACE address 02:3b:8a:2e:56:ea type macvlan mode bridge
ip link set onv72_56ea up
echo "Assigning static IP 192.168.6.74/24 to onv72_56ea..."
ip addr add 192.168.6.74/24 dev onv72_56ea
echo 1 > /proc/sys/net/ipv4/conf/onv72_56ea/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv72_56ea/arp_announce

verify_interface onv72_56ea 192.168.6.74
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv72_56ea or IP 192.168.6.74 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 73/80: onv73_2171"
ip link add onv73_2171 link $PHYS_IFACE address 02:c1:b2:86:21:71 type macvlan mode bridge
ip link set onv73_2171 up
echo "Assigning static IP 192.168.6.75/24 to onv73_2171..."
ip addr add 192.168.6.75/24 dev onv73_2171
echo 1 > /proc/sys/net/ipv4/conf/onv73_2171/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv73_2171/arp_announce

verify_interface onv73_2171 192.168.6.75
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv73_2171 or IP 192.168.6.75 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 74/80: onv74_1669"
ip link add onv74_1669 link $PHYS_IFACE address 02:02:f6:54:16:69 type macvlan mode bridge
ip link set onv74_1669 up
echo "Assigning static IP 192.168.6.76/24 to onv74_1669..."
ip addr add 192.168.6.76/24 dev onv74_1669
echo 1 > /proc/sys/net/ipv4/conf/onv74_1669/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv74_1669/arp_announce

verify_interface onv74_1669 192.168.6.76
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv74_1669 or IP 192.168.6.76 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 75/80: onv75_9616"
ip link add onv75_9616 link $PHYS_IFACE address 02:bd:6c:9e:96:16 type macvlan mode bridge
ip link set onv75_9616 up
echo "Assigning static IP 192.168.6.77/24 to onv75_9616..."
ip addr add 192.168.6.77/24 dev onv75_9616
echo 1 > /proc/sys/net/ipv4/conf/onv75_9616/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv75_9616/arp_announce

verify_interface onv75_9616 192.168.6.77
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv75_9616 or IP 192.168.6.77 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 76/80: onv76_695c"
ip link add onv76_695c link $PHYS_IFACE address 02:0f:b3:45:69:5c type macvlan mode bridge
ip link set onv76_695c up
echo "Assigning static IP 192.168.6.78/24 to onv76_695c..."
ip addr add 192.168.6.78/24 dev onv76_695c
echo 1 > /proc/sys/net/ipv4/conf/onv76_695c/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv76_695c/arp_announce

verify_interface onv76_695c 192.168.6.78
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv76_695c or IP 192.168.6.78 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 77/80: onv77_b834"
ip link add onv77_b834 link $PHYS_IFACE address 02:8a:8f:f6:b8:34 type macvlan mode bridge
ip link set onv77_b834 up
echo "Assigning static IP 192.168.6.79/24 to onv77_b834..."
ip addr add 192.168.6.79/24 dev onv77_b834
echo 1 > /proc/sys/net/ipv4/conf/onv77_b834/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv77_b834/arp_announce

verify_interface onv77_b834 192.168.6.79
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv77_b834 or IP 192.168.6.79 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 78/80: onv78_91ee"
ip link add onv78_91ee link $PHYS_IFACE address 02:fb:78:8e:91:ee type macvlan mode bridge
ip link set onv78_91ee up
echo "Assigning static IP 192.168.6.80/24 to onv78_91ee..."
ip addr add 192.168.6.80/24 dev onv78_91ee
echo 1 > /proc/sys/net/ipv4/conf/onv78_91ee/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv78_91ee/arp_announce

verify_interface onv78_91ee 192.168.6.80
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv78_91ee or IP 192.168.6.80 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 79/80: onv79_63b2"
ip link add onv79_63b2 link $PHYS_IFACE address 02:0d:ba:c1:63:b2 type macvlan mode bridge
ip link set onv79_63b2 up
echo "Assigning static IP 192.168.6.81/24 to onv79_63b2..."
ip addr add 192.168.6.81/24 dev onv79_63b2
echo 1 > /proc/sys/net/ipv4/conf/onv79_63b2/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv79_63b2/arp_announce

verify_interface onv79_63b2 192.168.6.81
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv79_63b2 or IP 192.168.6.81 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Creating interface 80/80: onv80_4245"
ip link add onv80_4245 link $PHYS_IFACE address 02:91:59:0f:42:45 type macvlan mode bridge
ip link set onv80_4245 up
echo "Assigning static IP 192.168.6.82/24 to onv80_4245..."
ip addr add 192.168.6.82/24 dev onv80_4245
echo 1 > /proc/sys/net/ipv4/conf/onv80_4245/arp_ignore
echo 2 > /proc/sys/net/ipv4/conf/onv80_4245/arp_announce

verify_interface onv80_4245 192.168.6.82
if [ $? -ne 0 ]; then
    echo "WARNING: Interface onv80_4245 or IP 192.168.6.82 verification failed. Manual check recommended."
fi

sleep 0.1

echo "Network interface setup complete."
echo "Virtual interface IP addresses:"
ip -4 addr show | grep -A 2 "onv" | grep -v "valid_lft"
