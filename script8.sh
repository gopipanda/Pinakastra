set -x
#!/bin/bash

# Accessing environment variables
source /home/pinaka/all_in_one/vpinakastra/bin/activate
export ANSIBLE_PYTHON_INTERPRETER=/home/pinaka/all_in_one/vpinakastra/bin/python
kolla-ansible post-deploy
pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/2023.1
/home/pinaka/all_in_one/vpinakastra/share/kolla-ansible/init-runonce

test_date=$(date)

# Write the test date to the install date file
echo "$test_date" > /root/vpinakastra/.install-date

echo "Test date set to: $test_date"
eval $(python3 /home/pinaka/tmps/script.py)

SERVICE_NAME="trial_period_monitor"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
GITHUB_RAW_URL="https://raw.githubusercontent.com/gopipanda/Pinakastra/main/watch_install_date.sh"
LOCAL_PYTHON_SCRIPT_PATH="/home/pinaka/all_in_one/watch_install_date.sh"
LOG_FILE="/home/pinaka/log/${SERVICE_NAME}.log"
/usr/bin/curl -sL ${GITHUB_RAW_URL} -o ${LOCAL_PYTHON_SCRIPT_PATH}
# Create the service file content
service_content="[Unit]
Description=Watch Install Date and Manage Docker Trial Period
After=network.target

[Service]
Type=simple
ExecStart=/home/pinaka/all_in_one/watch_install_date.sh
Restart=always
RestartSec=60
User=root

[Install]
WantedBy=multi-user.target

"

# Write the service file
echo "Creating service file at ${SERVICE_FILE}..."
sudo echo "$service_content" | sudo tee ${SERVICE_FILE} > /dev/null

# Reload systemd manager configuration
echo "Reloading systemd manager configuration..."
sudo systemctl daemon-reload

# Enable the service
echo "Enabling the service ${SERVICE_NAME}..."
sudo systemctl enable ${SERVICE_NAME}

# Start the service
echo "Starting the service ${SERVICE_NAME}..."
sudo systemctl start ${SERVICE_NAME}

echo "Service ${SERVICE_NAME} created and started. Logs can be found in ${LOG_FILE}"



keystone_password=$(grep 'keystone_admin_password' /etc/kolla/passwords.yml | cut -d'=' -f2)
Ceph_password=$(grep 'Password' /home/pinaka/all_in_one/vpinakastra/ceph_dashboard_credentials.txt | cut -d'=' -f2)
trial_end_time=$(sudo journalctl -u trial_period_monitor.service | awk '/Trial period ends at/ {for (i=6; i<=NF; i++) printf $i " "; print ""}' | tail -n 1)
echo "$keystone_password"

Credentials_path="/home/pinaka/all_in_one/credentials.txt
Service_Credentials="========== SKYLINE CREDENTIALS ==============
URL : http://$IP_ADDRESS:9999/

DEFAULT REGION : REGION ONE
Username : admin
Password : $keystone_password

============= CEPH CREDENTIALS =====================
URL : http://$IP_ADDRESS:8443

Ceph Dashboard URL: https://$IP_ADDRESS:8443/
Ceph Dashboard Username: admin
Ceph Dashboard Password: $Ceph_password

============= Trial Period time ===================
Trial period ends at: $trial_end_time

"
sudo echo "$Service_Credentials" | sudo tee ${Credentials_path} > /dev/null


sshpass -p "$ROOT_USER_PASSWORD" scp -o StrictHostKeyChecking=no $Credentials_path pinaka@$HOST_IP:/home/pinaka/makers/

echo "scp done successfully"

