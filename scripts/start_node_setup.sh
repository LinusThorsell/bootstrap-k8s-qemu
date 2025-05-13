#!/usr/bin/env bash

# Function to display usage instructions
usage() {
    echo "Usage: $0 -i disk_image -s disk_iso -m memory_mb"
    echo "  -i disk_image   Path to disk image (required)"
    echo "  -s disk_iso     Path to alpine iso (required)"
    echo "  -m memory_mb    RAM in MB to allocate to VM (required)"
    exit 1
}

# Initialize values as empty
DISK_IMAGE=""
DISK_ISO=""
MEMORY=""

# Parse flags
while getopts ":i:s:m:" opt; do
  case $opt in
    i) DISK_IMAGE="$OPTARG" ;;
    s) DISK_ISO="$OPTARG" ;;
    m) MEMORY="$OPTARG" ;;
    *) usage ;;
  esac
done

# Validate that all required options are provided
if [[ -z "$MEMORY" || -z "$DISK_IMAGE" || -z "$DISK_ISO" ]]; then
    echo "❌ Error: All options -i, -p, and -m are required."
    usage
fi

# Start VM in background
echo "Starting Alpine VM in setup mode with iso: $DISK_ISO using $MEMORY MB RAM using disk $DISK_IMAGE..."

qemu-system-x86_64 \
  -m "$MEMORY" \
  -cdrom "$DISK_ISO" \
  -boot d \
  -hda "$DISK_IMAGE" \
  -net nic -net user \
  -nographic

