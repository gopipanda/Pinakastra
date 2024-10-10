set -x
set -e

sudo apt install -y network-manager
sudo apt install -y curl

SERVER_IP="$IP_ADDRESS"
NETMASK="$NETMASK"
INTERFACE_01="$INTERFACE_01"
INTERFACE_02="$INTERFACE_02"
GATEWAY="$GATEWAY"
DNS_SERVERS="$DNS_SERVERS"

echo "Server IP: $SERVER_IP"
echo "Netmask: $NETMASK"
echo "IPv4 Gateway: $GATEWAY"

# Ensure NetworkManager manages the interfaces
echo "Configuring NetworkManager to manage interfaces..."
sudo sed -i '/\[main\]/a plugins=ifupdown,keyfile' /etc/NetworkManager/NetworkManager.conf
sudo sed -i '/\[ifupdown\]/a managed=true' /etc/NetworkManager/NetworkManager.conf

# Restart NetworkManager
sudo systemctl restart NetworkManager

# Wait for NetworkManager to restart
sleep 10

# Add and configure interface 01
echo "Adding and configuring interface $INTERFACE_01..."
sudo nmcli dev set "$INTERFACE_01" managed yes
sudo nmcli con add type ethernet ifname "$INTERFACE_01" con-name "$INTERFACE_01" autoconnect yes
sudo nmcli con mod "$INTERFACE_01" ipv4.addresses "$SERVER_IP/24"
sudo nmcli con mod "$INTERFACE_01" ipv4.gateway "$GATEWAY"
sudo nmcli con mod "$INTERFACE_01" ipv4.dns "$DNS_SERVERS"
sudo nmcli con mod "$INTERFACE_01" ipv4.method manual
sudo nmcli con up "$INTERFACE_01"

# Wait for the interface to come up
sleep 10

# Add and configure interface 02 (static without IP)
echo "Adding and configuring interface $INTERFACE_02..."
sudo nmcli dev set "$INTERFACE_02" managed yes
sudo nmcli con add type ethernet ifname "$INTERFACE_02" con-name "$INTERFACE_02" autoconnect yes
sudo nmcli con mod "$INTERFACE_02" ipv4.method disabled
sudo nmcli con mod "$INTERFACE_02" ipv6.method ignore
sudo nmcli con up "$INTERFACE_02"

# Wait for the interface to come up
sleep 10

# Set the hostname
sudo hostnamectl set-hostname "$HOSTNAME"

echo "Network settings configured and hostname set to hci."