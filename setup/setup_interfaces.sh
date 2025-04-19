#!/bin/bash

# Privileged Setup Script for ONVIF Proxy GUI Application
# Creates persistent MACVLAN interfaces and registers them in the database.
# MUST be run with sudo privileges.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
DB_FILE_REL="db/onvif-proxy.db" # Default database path relative to project root
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_ROOT=$( cd -- "$(dirname "$SCRIPT_DIR")" &> /dev/null && pwd )
DB_FILE="$PROJECT_ROOT/$DB_FILE_REL"
PERSISTENCE_DIR="/etc/systemd/network" # systemd-networkd config directory
DEFAULT_SLEEP_INTERVAL=0.5 # Seconds to sleep between interface creations

# --- Helper Functions ---

# Check if a command exists
function check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: Required command '$1' not found. Please install it."
        exit 1
    fi
}
# Increment the last octet of a MAC address
# Input: MAC address (e.g., a2:00:00:00:00:01)
# Output: Incremented MAC address (e.g., a2:00:00:00:00:02)
# Limitations: Basic, only increments last octet, assumes hex, no carry-over.
function increment_mac() {
    local mac=$1
    local prefix=$(echo "$mac" | cut -d: -f1-5)
    local last_octet=$(echo "$mac" | cut -d: -f6)
    local next_octet_dec=$((16#$last_octet + 1))
    # Handle potential overflow for the last octet (simple wrap around for demo)
    if [ $next_octet_dec -gt 255 ]; then
        echo "Warning: MAC address last octet overflow not fully handled." >&2
        next_octet_dec=0
    fi
    local next_octet_hex=$(printf '%02x' "$next_octet_dec")
    echo "$prefix:$next_octet_hex"
}

# Increment an IPv4 address
# Input: IP address (e.g., 192.168.6.3)
# Output: Incremented IP address (e.g., 192.168.6.4)
# Limitations: Basic, handles single carry-over from last octet.
function increment_ip() {
    local ip=$1
    local IFS='.'
    read -r ip1 ip2 ip3 ip4 <<< "$ip"

    ip4=$((ip4 + 1))
    if [ $ip4 -gt 255 ]; then
        ip4=0
        ip3=$((ip3 + 1))
        if [ $ip3 -gt 255 ]; then
             echo "Warning: IP address increment overflow beyond 3rd octet not handled." >&2
             # Resetting for demo purposes, real scenario might need more logic or error
             ip3=0
             ip2=$((ip2 + 1))
             # Add more checks if needed
        fi
    fi
    echo "$ip1.$ip2.$ip3.$ip4"
}


# --- Cleanup Function ---
function cleanup_interfaces() {
    local base_name=$1
    echo "--- Starting Cleanup for interfaces matching '$base_name-*' ---"

    # Find interfaces in DB
    mapfile -t interfaces_to_delete < <(sqlite3 "$DB_FILE" "SELECT interface_name, mac_address FROM virtual_interfaces WHERE interface_name LIKE '${base_name}-%';")

    if [ ${#interfaces_to_delete[@]} -eq 0 ]; then
        echo "No interfaces found in database matching '$base_name-*' to clean up."
        return
    fi

    echo "Found ${#interfaces_to_delete[@]} interface(s) in DB to remove."

    for entry in "${interfaces_to_delete[@]}"; do
        local iface_name=$(echo "$entry" | cut -d'|' -f1)
        local mac_addr=$(echo "$entry" | cut -d'|' -f2)
        echo "Processing $iface_name ($mac_addr)..."

        # 1. Remove systemd-networkd files
        local link_file="$PERSISTENCE_DIR/90-${iface_name}.link"
        local network_file="$PERSISTENCE_DIR/90-${iface_name}.network"
        if [ -f "$link_file" ]; then
            echo "  Removing $link_file"
            rm -f "$link_file" || echo "  Warning: Failed to remove $link_file"
        fi
        if [ -f "$network_file" ]; then
            echo "  Removing $network_file"
            rm -f "$network_file" || echo "  Warning: Failed to remove $network_file"
        fi

        # 2. Delete network interface if it exists
        if ip link show "$iface_name" &> /dev/null; then
            echo "  Deleting interface $iface_name"
            ip link delete "$iface_name" || echo "  Warning: Failed to delete interface $iface_name"
        else
            echo "  Interface $iface_name does not exist in system."
        fi

        # 3. Delete from database
        echo "  Deleting DB entry for $iface_name"
        sqlite3 "$DB_FILE" "DELETE FROM virtual_interfaces WHERE interface_name = '$iface_name';" || echo "  Warning: Failed to delete DB entry for $iface_name"
    done

    echo "--- Cleanup Finished ---"
    echo "NOTE: You might still need to run 'systemctl restart systemd-networkd' or reboot."
    echo
}


# --- Main Script ---

# Default values
CLEANUP_MODE=false
DHCP_MODE=false

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --cleanup) CLEANUP_MODE=true ;;
        --dhcp) DHCP_MODE=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done


echo "ONVIF Proxy GUI - MACVLAN Interface Setup"
echo "========================================="
echo "This script requires sudo privileges."
echo "Database file: $DB_FILE"
echo

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (using sudo)."
  exit 1
fi

# Check DB file exists
if [ ! -f "$DB_FILE" ]; then
    echo "Error: Database file not found at $DB_FILE"
    echo "Please ensure the database exists (you might need to create it from db_schema.sql first)."
    exit 1
fi

# 1. Check Dependencies
echo "Checking dependencies..."
check_command "ip"
check_command "sqlite3"
echo "Dependencies found."
echo

# 2. Gather User Input (unless only cleaning up)
if [ "$CLEANUP_MODE" = true ]; then
     read -p "Enter the base name for interfaces to CLEAN UP (e.g., onvif-proxy): " BASE_NAME
     if [ -z "$BASE_NAME" ]; then
        echo "Error: Base name cannot be empty for cleanup."
        exit 1
     fi
     cleanup_interfaces "$BASE_NAME"
     echo "Cleanup operation complete."
     exit 0
fi

# --- Creation Mode ---
echo "--- Interface Creation ---"
read -p "Enter the parent network interface (e.g., eth0, enp3s0): " PARENT_INTERFACE
if [ -z "$PARENT_INTERFACE" ]; then
    echo "Error: Parent interface cannot be empty."
    exit 1
fi
if ! ip link show "$PARENT_INTERFACE" &> /dev/null; then
    echo "Error: Parent interface '$PARENT_INTERFACE' does not seem to exist."
    exit 1
fi

read -p "Enter the starting locally administered MAC address (e.g., a2:00:00:00:00:01): " START_MAC
# Check if empty
if [ -z "$START_MAC" ]; then
    echo "Error: Starting MAC address cannot be empty."
    exit 1
fi
# Basic MAC format validation
if ! [[ "$START_MAC" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
    echo "Error: Invalid MAC address format. Use xx:xx:xx:xx:xx:xx format."
    exit 1
fi
# Basic check for locally administered bit (second char must be 2, 6, A, E)
second_char=$(echo "$START_MAC" | cut -c 2)
if ! [[ "$second_char" =~ ^[26AEae]$ ]]; then
     echo "Warning: MAC address '$START_MAC' might not be locally administered (second hex digit is not 2, 6, A, or E)." >&2
fi


read -p "Enter the number of virtual interfaces to create: " NUM_INTERFACES
if ! [[ "$NUM_INTERFACES" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: Number of interfaces must be a positive integer."
    exit 1
fi

read -p "Enter the base name for virtual interfaces (e.g., onvif-proxy): " BASE_NAME
if [ -z "$BASE_NAME" ]; then
    echo "Error: Base name cannot be empty."
    exit 1
fi

# Gather Static IP info if not in DHCP mode
if [ "$DHCP_MODE" = false ]; then
    read -p "Enter the starting Static IP address (e.g., 192.168.6.3): " START_IP
    # Basic IP format validation
    if ! [[ "$START_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "Error: Invalid starting IP address format."
        exit 1
    fi
    read -p "Enter the subnet prefix length (CIDR, e.g., 24): " SUBNET_CIDR
    if ! [[ "$SUBNET_CIDR" =~ ^[0-9]+$ ]] || [ "$SUBNET_CIDR" -lt 1 ] || [ "$SUBNET_CIDR" -gt 32 ]; then
        echo "Error: Invalid subnet CIDR (must be 1-32)."
        exit 1
    fi
    read -p "Enter the Gateway IP address: " GATEWAY_IP
     if ! [[ "$GATEWAY_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "Error: Invalid Gateway IP address format."
        exit 1
    fi
    read -p "Enter DNS server IP address(es) (space-separated): " DNS_SERVERS
    # Basic validation for at least one IP
    if [ -z "$DNS_SERVERS" ]; then
        echo "Error: At least one DNS server must be provided."
        exit 1
    fi
    # Further validation could be added for each DNS server IP format
fi


echo
echo "--- Summary ---"
echo "Parent Interface: $PARENT_INTERFACE"
echo "Starting MAC:     $START_MAC"
echo "Number to Create: $NUM_INTERFACES"
echo "Base Name:        $BASE_NAME"
echo "Database File:    $DB_FILE"
echo "Persistence Dir:  $PERSISTENCE_DIR"
if [ "$DHCP_MODE" = true ]; then
    echo "Mode:             DHCP"
else
    echo "Mode:             Static IP"
    echo "Starting IP:      $START_IP / $SUBNET_CIDR"
    echo "Gateway:          $GATEWAY_IP"
    echo "DNS Servers:      $DNS_SERVERS"
fi
echo "---------------"
read -p "Proceed with creation? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi
echo

# 3. Create Interfaces, Configure Persistence, Update DB
echo "Creating interfaces sequentially..."
CURRENT_MAC=$START_MAC
CURRENT_IP=$START_IP # Only used in static mode

for (( i=1; i<=NUM_INTERFACES; i++ )); do
    IFACE_NAME="${BASE_NAME}-${i}"
    echo "--- Processing Interface $i/$NUM_INTERFACES: $IFACE_NAME ($CURRENT_MAC) ---"

    # --- Pre-checks ---
    # Check if interface name already exists in system
    if ip link show "$IFACE_NAME" &> /dev/null; then
        echo "  SKIPPING: Interface '$IFACE_NAME' already exists in the system."
        CURRENT_MAC=$(increment_mac "$CURRENT_MAC")
        [ "$DHCP_MODE" = false ] && CURRENT_IP=$(increment_ip "$CURRENT_IP")
        continue
    fi

    # Check if interface name or MAC already exists in DB
    DB_CHECK=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM virtual_interfaces WHERE interface_name = '$IFACE_NAME' OR mac_address = '$CURRENT_MAC';")
    if [ "$DB_CHECK" -ne 0 ]; then
        echo "  SKIPPING: Interface name '$IFACE_NAME' or MAC '$CURRENT_MAC' already exists in the database."
        CURRENT_MAC=$(increment_mac "$CURRENT_MAC")
         [ "$DHCP_MODE" = false ] && CURRENT_IP=$(increment_ip "$CURRENT_IP")
        continue
    fi

    # --- Creation ---
    # Create MACVLAN interface
    echo "  Creating MACVLAN interface..."
    ip link add "$IFACE_NAME" link "$PARENT_INTERFACE" address "$CURRENT_MAC" type macvlan mode bridge
    if [ $? -ne 0 ]; then
        echo "  ERROR: Failed to create MACVLAN interface '$IFACE_NAME'. Stopping."
        exit 1 # Stop on critical failure
    fi

    # --- Verification Step 1 ---
    echo -n "  Verifying interface creation..."
    if ! ip link show "$IFACE_NAME" &> /dev/null; then
         echo " FAILED."
         echo "  ERROR: Interface '$IFACE_NAME' not found after creation attempt. Stopping."
         # Attempt cleanup of potentially half-created interface? For now, just exit.
         exit 1
    fi
    echo " OK."

    # --- Configuration & Persistence ---
    # Bring interface up
    echo "  Bringing interface up..."
    ip link set "$IFACE_NAME" up
    if [ $? -ne 0 ]; then
        echo "  Warning: Failed to bring up interface '$IFACE_NAME'."
        # Continue anyway, might come up later
    fi

    # Create systemd-networkd .link file
    LINK_FILE_PATH="$PERSISTENCE_DIR/90-${IFACE_NAME}.link"
    echo "  Creating persistence file: $LINK_FILE_PATH"
    echo "[Match]" > "$LINK_FILE_PATH"
    echo "MACAddress=$CURRENT_MAC" >> "$LINK_FILE_PATH"
    echo "" >> "$LINK_FILE_PATH"
    echo "[Link]" >> "$LINK_FILE_PATH"
    echo "Name=$IFACE_NAME" >> "$LINK_FILE_PATH"

    # Create systemd-networkd .network file
    NETWORK_FILE_PATH="$PERSISTENCE_DIR/90-${IFACE_NAME}.network"
    echo "  Creating persistence file: $NETWORK_FILE_PATH"
    {
        echo "[Match]"
        echo "Name=$IFACE_NAME"
        echo ""
        echo "[Network]"
        if [ "$DHCP_MODE" = true ]; then
            echo "DHCP=ipv4"
        else
            echo "Address=$CURRENT_IP/$SUBNET_CIDR"
            echo "Gateway=$GATEWAY_IP"
            # Add multiple DNS servers if provided
            dns_string=""
            for dns in $DNS_SERVERS; do
                dns_string+="DNS=$dns"$'\n'
            done
            echo -n "$dns_string" # Use echo -n to avoid extra newline if empty
        fi
         echo "MACVLAN=" # Ensures it's treated correctly by systemd-networkd
    } > "$NETWORK_FILE_PATH"


    # --- Database Update ---
    # Insert into database
    echo "  Inserting into database..."
    sqlite3 "$DB_FILE" "INSERT INTO virtual_interfaces (mac_address, interface_name, parent_interface, status) VALUES ('$CURRENT_MAC', '$IFACE_NAME', '$PARENT_INTERFACE', 'available');"
    if [ $? -ne 0 ]; then
        echo "  Error: Failed to insert interface '$IFACE_NAME' into database. Manual cleanup might be needed."
        # Consider attempting to roll back system changes? For now, just warn.
    fi

    echo "  Done with $IFACE_NAME."
    CURRENT_MAC=$(increment_mac "$CURRENT_MAC")
    [ "$DHCP_MODE" = false ] && CURRENT_IP=$(increment_ip "$CURRENT_IP")

    echo "  Sleeping for $DEFAULT_SLEEP_INTERVAL seconds..."
    sleep "$DEFAULT_SLEEP_INTERVAL"
done

echo
echo "Interface creation loop finished."
echo

# 4. Final Instructions
echo "---------------------------------------------------------------------"
echo "IMPORTANT:"
echo "Network configuration files for persistence have been created in $PERSISTENCE_DIR."
echo "You may need to restart the network service or reboot for changes"
echo "to be fully persistent and for interfaces to obtain IP addresses via DHCP."
echo "Example (systemd-networkd): sudo systemctl restart systemd-networkd"
echo "---------------------------------------------------------------------"
echo
echo "Setup script finished."

exit 0
