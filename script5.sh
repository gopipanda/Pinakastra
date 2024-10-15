set -x
#!/bin/bash

# Accessing environment variables
echo "Hostname: $HOSTNAME"
echo "IP Address: $IP_ADDRESS"
echo "Netmask: $NETMASK"
echo "Interface 1: $INTERFACE_01"
echo "Interface 2: $INTERFACE_02"
echo "Gateway: $GATEWAY"
echo "DNS Servers: $DNS_SERVERS"
echo "Root User Password: $ROOT_USER_PASSWORD"

is_ceph_installed() {
  if command -v ceph > /dev/null; then
    return 0
  else
    return 1
  fi
}

stop_and_disable_ceph_services() {
  echo "Stopping and disabling Ceph services..."

  # Stop and disable ceph.target
  sudo systemctl stop ceph.target
  sudo systemctl disable ceph.target

  # Stop and disable individual Ceph services
  for service in ceph-mon@* ceph-osd@* ceph-mds@* ceph-mgr; do
    if systemctl is-active --quiet $service; then
      sudo systemctl stop $service
    fi
    sudo systemctl disable $service
  done
}

# Function to remove Ceph packages
remove_ceph_packages() {
  echo "Removing Ceph packages..."
  if [ -f /etc/debian_version ]; then
    sudo apt-get remove -y ceph ceph-common ceph-mon ceph-osd ceph-mgr ceph-mds
  else
    sudo echo "Unsupported distribution. Please adjust package removal commands."
    exit 1
  fi
}

# Function to clean up remaining Ceph data and configuration files
cleanup_ceph_data() {
  echo "Cleaning up remaining Ceph data and configuration files..."
  sudo rm -rf /etc/ceph
  sudo rm -rf /var/lib/ceph
  sudo rm -rf /var/log/ceph
  sudo rm -rf /var/run/ceph
}

# Main script
if is_ceph_installed; then
  echo "Ceph is installed. Proceeding with uninstallation..."
  stop_and_disable_ceph_services
  remove_ceph_packages
  cleanup_ceph_data
  echo "Ceph uninstallation complete."
else
  echo "Ceph is not installed."
fi

#!/bin/bash
Ceph_LIST="/etc/apt/sources.list.d/ceph.list"
if [[ -f "$Ceph_LIST" ]]; then
    sudo rm -f "$Ceph_LIST"
    echo "Removed existing Ceph repository for Ubuntu."
else
    echo "No existing Ceph repository for Ubuntu found."
fi
# Set the Ceph release version

CEPH_RELEASE=18.2.4

# Download the cephadm script
sudo curl --silent --remote-name --location https://download.ceph.com/rpm-${CEPH_RELEASE}/el9/noarch/cephadm

# Make the cephadm script executable
sudo chmod +x cephadm

# Install cephadm
# Add the Ceph repository for the specified release
sudo python3 ./cephadm add-repo --release reef

# Install cephadm again (to make sure all dependencies are resolved)
sudo python3 ./cephadm install

# Check the Ceph version
sudo cephadm shell -- ceph --version


MGMT_IP="$IP_ADDRESS"
OUTPUT_FILE="/home/pinaka/all_in_one/vpinakastra/ceph_dashboard_credentials.txt"

# Simulated output from the Ceph bootstrap command
BOOTSTRAP_OUTPUT=$(sudo cephadm bootstrap --mon-ip $MGMT_IP --allow-fqdn-hostname)

# Extract the necessary information
DASHBOARD_URL=$(echo "$BOOTSTRAP_OUTPUT" | grep -Po 'URL: \Khttps?://[^\s]+')
DASHBOARD_USERNAME=$(echo "$BOOTSTRAP_OUTPUT" | grep -Po 'User: \K[^\s]+')
DASHBOARD_PASSWORD=$(echo "$BOOTSTRAP_OUTPUT" | grep -Po 'Password: \K[^\s]+')

# Verify that the variables are correctly populated
echo "Extracted URL: $DASHBOARD_URL"
echo "Extracted Username: $DASHBOARD_USERNAME"
echo "Extracted Password: $DASHBOARD_PASSWORD"

# Store the extracted information in the output file
echo "Ceph Dashboard URL: $DASHBOARD_URL" > $OUTPUT_FILE
echo "Ceph Dashboard Username: $DASHBOARD_USERNAME" >> $OUTPUT_FILE
echo "Ceph Dashboard Password: $DASHBOARD_PASSWORD" >> $OUTPUT_FILE

# Verify that the information is written to the output file
cat $OUTPUT_FILE
zap_disk(){
  raw_devices=$(sudo cephadm shell -- ceph orch device ls --format json-pretty)
  echo "Raw devices output:"
  echo "$raw_devices"

# Parse the JSON and list all device paths
  device_paths=$(echo "$raw_devices" | jq -r '.[] | .devices[] | .path')
  echo "Device paths:"
  echo "$device_paths"

# Filter devices based on rejection reasons and boot keyword
  filtered_devices=$(echo "$raw_devices" | jq -r '.[] | .devices[] | select(.rejected_reasons != null and (.rejected_reasons | length > 0) and (.path | contains("boot") | not)) | .path')
  echo "Filtered device paths:"
  echo "$filtered_devices"

  # Function to zap devices
  zap_device() {
    local host=$1
    local device=$2
    sudo cephadm shell -- ceph orch device zap $host $device --force
  }

# Zap filtered devices
  for device in $filtered_devices; do
    echo "Zapping device: $device"
    zap_device "$HOSTNAME" "$device"
  done
}

zap_disk
sudo cephadm shell -- ceph orch apply osd --all-available-devices --method raw
zap_disk

echo "Device zapping completed."
sudo cephadm shell -- ceph orch device ls
sleep 10
sleep 10

sudo cephadm shell -- ceph osd pool create volumes
sudo cephadm shell -- ceph osd pool create images
sudo cephadm shell -- ceph osd pool create backups
sudo cephadm shell -- ceph osd pool create vms
sleep 10

sudo cephadm shell -- ceph config set global mon_allow_pool_size_one true
sudo cephadm shell -- ceph osd pool set .mgr size 1 --yes-i-really-mean-it
sudo cephadm shell -- ceph osd pool set images size 1 --yes-i-really-mean-it
sudo cephadm shell -- ceph osd pool set backups size 1 --yes-i-really-mean-it
sudo cephadm shell -- ceph osd pool set volumes size 1 --yes-i-really-mean-it
sudo cephadm shell -- ceph osd pool set vms size 1 --yes-i-really-mean-it
sleep 10

sudo cephadm shell -- rbd pool init volumes
sudo cephadm shell -- rbd pool init vms
sudo cephadm shell -- rbd pool init images
sudo cephadm shell -- rbd pool init backups

echo "Ceph configuration and initialization completed."
sleep 10


sudo mkdir -p /opt/cni/bin
sudo mkdir -p /etc/kolla/config/cinder
sudo mkdir -p /etc/kolla/config/glance
sudo mkdir -p /etc/kolla/config/nova
sudo mkdir -p /etc/kolla/config/horizon
sudo mkdir -p /etc/kolla/config/cinder/cinder-volume
sudo mkdir -p /etc/kolla/config/cinder/cinder-backup

sudo cephadm shell ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images' mgr 'profile rbd pool=images'
sudo cephadm shell ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms'
sudo cephadm shell ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups'
sudo cephadm shell ceph auth get-or-create client.glance | ssh $HOSTNAME sudo tee /etc/ceph/ceph.client.glance.keyring
sudo cephadm shell ceph auth get-or-create client.glance | ssh $HOSTNAME sudo tee /etc/ceph/ceph.client.glance.keyring
ssh $HOSTNAME sudo chown root:root /etc/ceph/ceph.client.glance.keyring
sudo cephadm shell ceph auth get-or-create client.cinder | ssh $HOSTNAME sudo tee /etc/ceph/ceph.client.cinder.keyring
ssh $HOSTNAME sudo chown root:root /etc/ceph/ceph.client.cinder.keyring
sudo cephadm shell ceph auth get-or-create client.cinder-backup | ssh $HOSTNAME sudo tee /etc/ceph/ceph.client.cinder-backup.keyring
ssh $HOSTNAME sudo chown root:root /etc/ceph/ceph.client.cinder-backup.keyring
sudo cephadm shell ceph auth get-or-create client.cinder | ssh $HOSTNAME sudo tee /etc/ceph/ceph.client.cinder.keyring
sudo cephadm shell ceph auth get-key client.cinder | ssh $HOSTNAME tee client.cinder.key
sudo cp /etc/ceph/ceph.client.cinder.keyring /etc/kolla/config/cinder
sudo cp /etc/ceph/ceph.conf /etc/kolla/config/cinder
sudo cp /etc/ceph/ceph.client.cinder-backup.keyring /etc/kolla/config/cinder/cinder-backup/
sudo cp /etc/ceph/ceph.client.cinder.keyring /etc/kolla/config/cinder/cinder-backup/
sudo cp /etc/ceph/ceph.conf /etc/kolla/config/cinder/cinder-backup/
sudo cp /etc/ceph/ceph.client.cinder.keyring /etc/kolla/config/cinder/cinder-volume/
sudo cp /etc/ceph/ceph.conf /etc/kolla/config/cinder/cinder-volume/
sudo cp /etc/ceph/ceph.client.glance.keyring /etc/kolla/config/glance/
sudo cp /etc/ceph/ceph.conf /etc/kolla/config/glance/
sudo cp /etc/ceph/ceph.client.cinder.keyring /etc/kolla/config/nova/
sudo cp /etc/ceph/ceph.conf /etc/kolla/config/nova/

# Add the following lines to /etc/kolla/config/nova/nova-compute.conf
sudo tee -a /etc/kolla/config/nova/nova-compute.conf <<EOF
[libvirt]
images_rbd_pool=vms
images_type=rbd
images_rbd_ceph_conf=/etc/ceph/ceph.conf
rbd_user=cinder
block_device_allocate_retries = 800
block_device_allocate_retries_interval = 3
EOF

echo "Configuration added to /etc/kolla/config/nova/nova-compute.conf"

CONF_FILE="/etc/kolla/config/cinder/ceph.conf"
CONF_FILE1="/etc/kolla/config/cinder/cinder-backup/ceph.conf"
CONF_FILE2="/etc/kolla/config/cinder/cinder-volume/ceph.conf"
CONF_FILE3="/etc/kolla/config/glance/ceph.conf"
CONF_FILE4="/etc/kolla/config/nova/ceph.conf"
START_LINE=3

sudo sed -i.bak "${START_LINE},\$s/\t//g" "$CONF_FILE"
sudo sed -i.bak "${START_LINE},\$s/\t//g" "$CONF_FILE1"
sudo sed -i.bak "${START_LINE},\$s/\t//g" "$CONF_FILE2"
sudo sed -i.bak "${START_LINE},\$s/\t//g" "$CONF_FILE3"
sudo sed -i.bak "${START_LINE},\$s/\t//g" "$CONF_FILE4"

echo "Spaces have been removed from line $START_LINE onward in $CONF_FILE"

cd /home/pinaka/all_in_one/vpinakastra/

sudo tee -a /home/pinaka/all_in_one/vpinakastra/all-in-one <<EOF
[all]
$HOSTNAME
[all:vars]
keystone_internal_port=5000
EOF

if [[ -f "$Ceph_LIST" ]]; then
    sudo rm -f "$Ceph_LIST"
    echo "Removed existing Ceph repository for Ubuntu."
else
    echo "No existing Ceph repository for Ubuntu found."
fi
sudo apt update

echo "Ceph Dashboard URL: $DASHBOARD_URL"
echo "Ceph Dashboard USERNAME: $DASHBOARD_USERNAME"
echo "Ceph Dashboard Admin Password: $DASHBOARD_PASSWORD"

