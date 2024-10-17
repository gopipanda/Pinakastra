set -x
#!/bin/bash
eval $(python3 /home/pinaka/tmps/script.py)

# Accessing environment variables
echo "Hostname: $HOSTNAME"
echo "IP Address: $IP_ADDRESS"
echo "Netmask: $NETMASK"
echo "Interface 1: $INTERFACE_01"
echo "Interface 2: $INTERFACE_02"
echo "Gateway: $GATEWAY"
echo "DNS Servers: $DNS_SERVERS"
echo "Root User Password: $ROOT_USER_PASSWORD"
sudo apt update -y
sudo apt upgrade -y
sudo apt-get install jq -y
sudo apt-get install python3-dbus -y

# Install packages
sudo apt install -y \
    htop \
    speedtest-cli \
    dbus-x11 \
    python3-sqlalchemy \
    git \
    python3-dev \
    libffi-dev \
    gcc \
    libssl-dev \
    libdbus-1-dev \
    libglib2.0-dev \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    lvm2

# Remove the existing Docker repository for Ubuntu
DOCKER_LIST="/etc/apt/sources.list.d/docker.list"
if [[ -f "$DOCKER_LIST" ]]; then
    sudo rm -f "$DOCKER_LIST"
    echo "Removed existing Docker repository for Ubuntu."
else
    echo "No existing Docker repository for Ubuntu found."
fi

# Download and add Docker’s official GPG key
sudo curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker's APT repository to the sources list
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the APT package index
sudo apt update

# Install Docker Engine, CLI, and containerd
sudo apt install -y docker-ce docker-ce-cli containerd.io


# Install Python packages
sudo apt install -y python3-pip -y

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker
sleep 10

# Remove the existing Docker repository for Ubuntu
DOCKER_LIST="/etc/apt/sources.list.d/docker.list"
if [[ -f "$DOCKER_LIST" ]]; then
    sudo rm -f "$DOCKER_LIST"
    echo "Removed existing Docker repository for Ubuntu."
else
    echo "No existing Docker repository for Ubuntu found."
fi
sudo apt update

# Set up Python virtual environment
sudo apt install -y python3.11-venv
python3 -m venv /home/pinaka/all_in_one/vpinakastra
source /home/pinaka/all_in_one/vpinakastra/bin/activate
pip install -U pip
pip install selinux ansible-core==2.13.13 dbus-python docker git+https://opendev.org/openstack/kolla-ansible@stable/2023.1

# Configure Kolla Ansible
sudo mkdir -p /etc/kolla
echo $USER
sudo chown $USER:$USER /etc/kolla
sudo cp -r /home/pinaka/all_in_one/vpinakastra/share/kolla-ansible/etc_examples/kolla/* /etc/kolla

# Set up Kolla Ansible inventory
cd /home/pinaka/all_in_one/vpinakastra
sudo cp /home/pinaka/all_in_one/vpinakastra/share/kolla-ansible/ansible/inventory/all-in-one .

# Install Ansible collections
ansible-galaxy collection install ansible.posix ansible.netcommon community.general ansible.utils community.mysql

# Install Kolla Ansible dependencies and generate passwords
kolla-ansible install-deps
kolla-genpwd

sleep 10
