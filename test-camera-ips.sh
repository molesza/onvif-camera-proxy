#!/bin/bash

# This script tests connectivity to all camera IP addresses defined in the config file

# Check if yaml parser is available
if ! command -v yq &> /dev/null; then
  echo "yq command not found. Using grep/awk instead for YAML parsing."
  YAML_PARSER="grep"
else
  YAML_PARSER="yq"
fi

# Default config file
CONFIG_FILE="config-192.168.6.219.yaml"

# Allow specifying a different config file
if [ "$1" != "" ]; then
  CONFIG_FILE="$1"
fi

echo "Using config file: $CONFIG_FILE"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Config file $CONFIG_FILE not found!"
  echo "Usage: $0 [config-file.yaml]"
  exit 1
fi

# Extract target hostname from config file
if [ "$YAML_PARSER" == "yq" ]; then
  TARGET_HOST=$(yq '.onvif[0].target.hostname' "$CONFIG_FILE")
else
  TARGET_HOST=$(grep -A 5 "target:" "$CONFIG_FILE" | grep "hostname:" | head -1 | awk '{print $2}')
fi

echo "Target camera/NVR: $TARGET_HOST"

# Extract camera IPs and ports from config file
echo "Extracting camera configurations from $CONFIG_FILE..."

# Get camera count
if [ "$YAML_PARSER" == "yq" ]; then
  CAMERA_COUNT=$(yq '.onvif | length' "$CONFIG_FILE")
else
  CAMERA_COUNT=$(grep -c "mac:" "$CONFIG_FILE")
fi

echo "Found $CAMERA_COUNT cameras in config"

# Test target camera/NVR connectivity
echo ""
echo "Testing connectivity to target camera/NVR ($TARGET_HOST)..."
ping -c 1 -W 2 "$TARGET_HOST" > /dev/null
if [ $? -eq 0 ]; then
  echo "✅ Target camera/NVR is reachable"
else
  echo "❌ Target camera/NVR is NOT reachable"
  echo "  This may prevent the ONVIF server from working properly."
fi

# Extract RTSP and HTTP ports
if [ "$YAML_PARSER" == "yq" ]; then
  RTSP_PORT=$(yq '.onvif[0].target.ports.rtsp' "$CONFIG_FILE")
  HTTP_PORT=$(yq '.onvif[0].target.ports.snapshot' "$CONFIG_FILE")
else
  # More robust parsing
  RTSP_PORT=$(grep -A 10 "target:" "$CONFIG_FILE" | grep -A 3 "ports:" | grep "rtsp:" | head -1 | awk '{print $2}')
  HTTP_PORT=$(grep -A 10 "target:" "$CONFIG_FILE" | grep -A 3 "ports:" | grep "snapshot:" | head -1 | awk '{print $2}')
fi

echo ""
echo "Testing RTSP port on target camera/NVR..."
nc -z -w 2 "$TARGET_HOST" "$RTSP_PORT"
if [ $? -eq 0 ]; then
  echo "✅ RTSP port ($RTSP_PORT) is open on target camera/NVR"
else
  echo "❌ RTSP port ($RTSP_PORT) is NOT open on target camera/NVR"
  echo "  This may prevent video streaming from working."
fi

echo ""
echo "Testing HTTP port on target camera/NVR..."
nc -z -w 2 "$TARGET_HOST" "$HTTP_PORT"
if [ $? -eq 0 ]; then
  echo "✅ HTTP port ($HTTP_PORT) is open on target camera/NVR"
else
  echo "❌ HTTP port ($HTTP_PORT) is NOT open on target camera/NVR"
  echo "  This may prevent snapshot functionality from working."
fi

echo ""
echo "Testing virtual camera interfaces..."

# Read the entire config file into a variable for easier parsing
CONFIG_CONTENT=$(cat "$CONFIG_FILE")

# Extract all MAC addresses
MAC_ADDRESSES=($(grep -E "^\s*- mac:" "$CONFIG_FILE" | awk '{print $3}'))
NAMES=($(grep -E "^\s*name:" "$CONFIG_FILE" | awk '{print $2}'))
SERVER_PORTS=($(grep -E "^\s*server:" "$CONFIG_FILE" | awk '{print $2}'))

# Loop through each camera in the config
for ((i=0; i<CAMERA_COUNT; i++)); do
  if [ "$YAML_PARSER" == "yq" ]; then
    MAC=$(yq ".onvif[$i].mac" "$CONFIG_FILE")
    NAME=$(yq ".onvif[$i].name" "$CONFIG_FILE")
    SERVER_PORT=$(yq ".onvif[$i].ports.server" "$CONFIG_FILE")
  else
    # Use the arrays we extracted
    MAC="${MAC_ADDRESSES[$i]}"
    NAME="${NAMES[$i]}"
    SERVER_PORT="${SERVER_PORTS[$i]}"
  fi
  
  # Generate interface name from MAC
  SHORT_MAC=$(echo "$MAC" | tr -d ':' | tail -c 5)
  if [ -z "$SHORT_MAC" ]; then
    # If MAC parsing failed, use a fallback
    SHORT_MAC=$(printf "%04x" $i)
  fi
  IFACE="onv$((i+1))_$SHORT_MAC"
  
  echo "Camera $((i+1)): $NAME (MAC: $MAC, Interface: $IFACE, Port: $SERVER_PORT)"
  
  # Check if interface exists
  if ip link show "$IFACE" &> /dev/null; then
    echo "  ✅ Interface $IFACE exists"
    
    # Get IP address
    IP=$(ip -4 addr show dev "$IFACE" 2>/dev/null | grep inet | awk '{print $2}' | cut -d'/' -f1)
    if [ -n "$IP" ]; then
      echo "  ✅ IP address assigned: $IP"
      
      # Test ONVIF server port
      nc -z -w 1 "$IP" "$SERVER_PORT" > /dev/null 2>&1
      if [ $? -eq 0 ]; then
        echo "  ✅ ONVIF server is running on $IP:$SERVER_PORT"
      else
        echo "  ❌ ONVIF server is NOT running on $IP:$SERVER_PORT"
      fi
    else
      echo "  ❌ No IP address assigned to $IFACE"
    fi
  else
    echo "  ❌ Interface $IFACE does not exist"
  fi
  
  echo ""
done

echo "Testing if cameras are discoverable via ONVIF..."
echo "Note: This requires onvif-discovery tool. If not installed, you can install it with:"
echo "npm install -g onvif-discovery"

if command -v onvif-discovery &> /dev/null; then
  echo "Running ONVIF discovery (this may take a few seconds)..."
  onvif-discovery | grep -E "192\.168\.6\.(2[0-9][0-9]|[0-9][0-9]|[0-9])"
else
  echo "onvif-discovery tool not found. Skipping ONVIF discovery test."
  echo "You can install it with: npm install -g onvif-discovery"
fi

echo ""
echo "Test complete!"