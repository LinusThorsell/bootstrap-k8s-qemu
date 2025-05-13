#!/usr/bin/env bash

# Function to display usage instructions
usage() {
    echo "Usage: $0 -i disk_image -p ssh_port -m memory_mb"
    echo "  -i disk_image   Path to disk image (required)"
    echo "  -p ssh_port     Port on host to forward to guest's SSH (required)"
    echo "  -m memory_mb    RAM in MB to allocate to VM (required)"
    exit 1
}

# Initialize values as empty
DISK_IMAGE=""
SSH_PORT=""
MEMORY=""

# Parse flags
while getopts ":i:p:m:" opt; do
  case $opt in
    i) DISK_IMAGE="$OPTARG" ;;
    p) SSH_PORT="$OPTARG" ;;
    m) MEMORY="$OPTARG" ;;
    *) usage ;;
  esac
done

# Validate that all required options are provided
if [[ -z "$SSH_PORT" || -z "$MEMORY" || -z "$DISK_IMAGE" ]]; then
    echo "❌ Error: All options -i, -p, and -m are required."
    usage
fi

# Start VM in background
echo "Starting Alpine VM with $MEMORY MB RAM and SSH on port $SSH_PORT using disk $DISK_IMAGE..."

qemu-system-x86_64 \
  -m "$MEMORY" \
  -hda "$DISK_IMAGE" \
  -net nic -net user,hostfwd=tcp::"$SSH_PORT"-:22 \
  -display none \
  -daemonize \
  -pidfile k3s_"$SSH_PORT".pid \
  -monitor unix:qemu-monitor.sock,server,nowait
