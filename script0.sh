#!/bin/bash
set -ex  # Debugging and exit on error


sudo cephadm shell -- ceph osd pool create volumes
sleep 2

sudo cephadm shell -- ceph osd pool create images
sleep 2

sudo cephadm shell -- ceph osd pool create backups
sleep 2

sudo cephadm shell -- ceph osd pool create vms

