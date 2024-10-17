#!/bin/bash
set -x
mkdir -p all_in_one
mkdir -p log
mkdir -p tmps
curl -s https://raw.githubusercontent.com/gopipanda/Pinakastra/main/script.py -o /home/pinaka/tmps/script.py
# Define variables
SERVICE_NAME="script_runner"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
GITHUB_RAW_URL="https://raw.githubusercontent.com/gopipanda/Pinakastra/main/All-in-one.py"
LOCAL_PYTHON_SCRIPT_PATH="/home/pinaka/all_in_one/All-in-one.py"
LOG_FILE="/home/pinaka/log/${SERVICE_NAME}.log"
/usr/bin/curl -sL ${GITHUB_RAW_URL} -o ${LOCAL_PYTHON_SCRIPT_PATH}
# Create the service file content
service_content="[Unit]
Description=Script Runner Service
After=network-online.target
Wants=network-online.target

[Service]
User=pinaka
WorkingDirectory=/home/pinaka/tmps
ExecStart=/usr/bin/python3 /home/pinaka/all_in_one/All-in-one.py
Restart=on-failure
Environment=PYTHONUNBUFFERED=1

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
