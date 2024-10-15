#!/bin/bash
set -ex  # Fail the script if any command fails
echo "$IP_ADDRESS"
echo "Creating volumes pool..."
sudo cephadm shell -- ceph osd pool create volumes

echo "Creating images pool..."
sudo cephadm shell -- ceph osd pool create images

echo "Creating backups pool..."
sudo cephadm shell -- ceph osd pool create backups

echo "Creating vms pool..."
sudo cephadm shell -- ceph osd pool create vms
