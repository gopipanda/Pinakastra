#!/bin/bash
set -e
set -x
SERVICE_NAME="script_runner"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
PYTHON_SCRIPT_PATH="/root/pinaka/All-in-one.py"
LOG_FILE="/var/log/${SERVICE_NAME}.log"

# Create the service file content
service_content="[Unit]
Description=Script Runner Service

[Service]
ExecStart=/usr/bin/python3 ${PYTHON_SCRIPT_PATH}
StandardOutput=append:${LOG_FILE}
StandardError=append:${LOG_FILE}
Restart=on-failure

[Install]
WantedBy=multi-user.target
"

# Write the service file
echo "Creating service file at ${SERVICE_FILE}..."
echo "$service_content" | sudo tee ${SERVICE_FILE} > /dev/null

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
