set -x
#!/bin/bash
eval $(python3 /home/pinaka/tmps/script.py)

# Now the environment variables are available

# Accessing environment variables
echo "Hostname: $HOSTNAME"
echo "IP Address: $IP_ADDRESS"
echo "Netmask: $NETMASK"
echo "Interface 1: $INTERFACE_01"
echo "Interface 2: $INTERFACE_02"
echo "Gateway: $GATEWAY"
echo "DNS Servers: $DNS_SERVERS"
echo "Root User Password: $ROOT_USER_PASSWORD"
ROOT_USER_PASSWORD="$ROOT_USER_PASSWORD"
HOSTNAME="$HOSTNAME"

# Check if ROOT_USER_PASSWORD is set
if [ -z "$ROOT_USER_PASSWORD" ]; then
    echo "Error: ROOT_USER_PASSWORD environment variable is not set."
    exit 1
fi

# Check if HOSTNAME is set
if [ -z "$HOSTNAME" ]; then
    echo "Error: HOSTNAME environment variable is not set."
    exit 1
fi

# Update /etc/hosts
sudo bash -c "echo '$IP_ADDRESS   $HOSTNAME' >> /etc/hosts"
sudo sed -i.bak 's/^::1\s*localhost.*/#::1         localhost localhost.localdomain localhost6 localhost6.localdomain6/' /etc/hosts
sudo sed -i.bak 's/^127.0.0.1\s*localhost.*/#127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4/' /etc/hosts

# Wait for 20 seconds
sleep 20

# Generate SSH key pair without prompts
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi

# Verify that the key was generated
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Error: SSH key generation failed."
    exit 1
fi

# Install sshpass if it's not already installed
if ! command -v sshpass &> /dev/null; then
    echo "sshpass could not be found, installing..."
    sudo apt update
    sudo apt install -y sshpass
fi

# Copy the SSH key to the remote host for the specified user without password prompt
sshpass -p "$ROOT_USER_PASSWORD" ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no pinaka@$HOSTNAME

# Test the SSH connection using the username@hostname format
if ssh -o StrictHostKeyChecking=no pinaka@$HOSTNAME "echo 'SSH key authentication successful with username@hostname!'"; then
    echo "SSH key authentication was successful using pinaka@$HOSTNAME."
else
    echo "SSH key authentication failed using pinaka@$HOSTNAME."
    exit 1
fi

# Test the SSH connection using just the hostname
if ssh -o StrictHostKeyChecking=no $HOSTNAME "echo 'SSH key authentication successful with just hostname!'"; then
    echo "SSH key authentication was successful using just $HOSTNAME."
else
    echo "SSH key authentication failed using just $HOSTNAME."
    exit 1
fi
