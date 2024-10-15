#!/bin/bash
set -ex  # Debugging and exit on error

sudo cephadm shell -- bash -c "
  ceph osd pool create volumes;
  sleep 2;
  ceph osd pool create images;
  sleep 2;
  ceph osd pool create backups;
  sleep 2;
  ceph osd pool create vms;
"
