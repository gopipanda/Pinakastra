#!/bin/bash
set -ex  # Fail the script if any command fails
echo "$IP_ADDRESS"
echo "Creating volumes pool..."
sudo cephadm shell -- ceph osd pool create volumes
sleep 50
echo "Creating images pool..."
sudo cephadm shell -- ceph osd pool create images
sleep 50

echo "Creating backups pool..."
sudo cephadm shell -- ceph osd pool create backups
sleep 50

echo "Creating vms pool..."
sudo cephadm shell -- ceph osd pool create vms
sleep 50
