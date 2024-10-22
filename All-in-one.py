import os
import subprocess
import time
import stat
import datetime

# Define the GitHub raw URLs for the shell scripts
script_urls = [
    'https://raw.githubusercontent.com/gopipanda/Pinakastra/main/script1.sh',
    'https://raw.githubusercontent.com/gopipanda/Pinakastra/main/script2.sh',
    'https://raw.githubusercontent.com/gopipanda/Pinakastra/main/script3.sh',
    'https://raw.githubusercontent.com/gopipanda/Pinakastra/main/script4.sh',
    'https://raw.githubusercontent.com/gopipanda/Pinakastra/main/script5.sh',
    'https://raw.githubusercontent.com/gopipanda/Pinakastra/main/script6.sh',
    'https://raw.githubusercontent.com/gopipanda/Pinakastra/main/script7.sh',
    'https://raw.githubusercontent.com/gopipanda/Pinakastra/main/script8.sh'
]

# Define the paths to the marker files
marker_paths = [
    '/home/pinaka/tmps/script1_done',
    '/home/pinaka/tmps/script2_done',
    '/home/pinaka/tmps/script3_done',
    '/home/pinaka/tmps/script4_done',
    '/home/pinaka/tmps/script5_done',
    '/home/pinaka/tmps/script6_done',
    '/home/pinaka/tmps/script7_done',
    '/home/pinaka/tmps/script8_done'
]

# Initialize last_executed_script from a state file if it exists, otherwise start from 0
state_file = '/home/pinaka/tmps/last_executed_script'
if os.path.exists(state_file):
    with open(state_file, 'r') as f:
        last_executed_script = int(f.read().strip())
else:
    last_executed_script = 0

LOG_FILE = "/home/pinaka/tmps/script_runner.log"

def log_to_file(message):
    """Append messages to the central log file with a timestamp."""
    try:
        with open(LOG_FILE, 'a') as f:
            timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            f.write(f"{timestamp} - {message}\n")
    except Exception as e:
        print(f"Failed to write to log file: {e}")
        
HOSTNAME = "hci"
NETMASK="255.255.255.0"
ROOT_USER_PASSWORD ="pinaka"

# Function to download and run a shell script with environment variables
def run_script(url, marker_path):
    if not os.path.exists(marker_path):
        # Define environment variables
        env = os.environ.copy()
        env.update({
            'HOSTNAME': HOSTNAME,
            'NETMASK': NETMASK,
            'ROOT_USER_PASSWORD': ROOT_USER_PASSWORD
        })

        # Download and execute the script via curl, passing environment variables
        command = f"curl -s {url} | bash"
        result = subprocess.run(
            ['bash', '-c', command], 
            capture_output=True, 
            text=True, 
            env=env
        )
         # Log the result centrally
        log_message = f"\n=== Executing URL: {url} ===\n"
        log_message += f"Command: {command}\n"
        log_message += f"Return Code: {result.returncode}\n"
        log_message += f"Output:\n{result.stdout}\n"
        log_message += f"Error:\n{result.stderr}\n"
        log_to_file(log_message)

        # Handle the result
        if result.returncode == 0:
            with open(marker_path, 'w') as f:
                f.write(result.stdout)  # Write stdout output to the marker file
                f.write(result.stderr) # Write stderr if any warnings/info exist
                f.write('done\n')
                time.sleep(50)
            print(f"Output of {url}:\n{result.stdout}")
        else:
            print(f"Error occurred while executing {url}:\n{result.stderr}")
    else:
        print(f"{marker_path} already completed, skipping...")

def execute_and_eval_python_script(script_path):
    """Execute a Python script and set environment variables from its output."""
    try:
        result = subprocess.run(
            ['python3', script_path],
            capture_output=True,
            text=True,
            check=True
        )
    except subprocess.CalledProcessError as e:
        print(f"Error executing {script_path}: {e.stderr.strip()}")
        return  # Exit if the script fails

    # Parse the output and set environment variables
    for line in result.stdout.splitlines():
        if line.startswith("export"):
            key_value = line[7:].split('=', 1)  # Split "export KEY=VALUE"
            if len(key_value) == 2:
                key, value = key_value[0].strip(), key_value[1].strip().strip("'")
                os.environ[key] = value  # Set the environment variable
                print(f"Set environment variable: {key}={value}")

def copy_file_to_host(file_path, target_user, password, host, remote_path):
    """Copy a file to a remote host using sshpass."""
    original_file_name = os.path.basename(file_path)  # Extract the file name

    print(f"Copying {file_path} to {target_user}@{host}:{remote_path}{original_file_name}")
    command = [
        'sshpass', '-p', password,
        'scp', '-o', 'StrictHostKeyChecking=no',
        file_path, f"{target_user}@{host}:{remote_path}{original_file_name}"
    ]

    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True)
        print(f"File copied successfully to {host}: {result.stdout.strip()}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to copy file to {host}: {e.stderr.strip()}")
        
def scp_log(marker_path):
    """Main function to execute a script and copy marker files to remote hosts."""
    script_path = '/home/pinaka/tmps/script.py'
    execute_and_eval_python_script(script_path)  # Run the script to set environment variables

    # Variables for SCP
    target_user = "pinaka"
    password = "pinaka"
    remote_path = "/home/pinaka/markers/"

    # Get the host IP from the environment variable
    target_host = os.environ.get('HOST_IP')
    if not target_host:
        print("HOST_IP environment variable is not set.")
        return

    # Copy the marker file to the remote host
    copy_file_to_host(marker_path, target_user, password, target_host, remote_path)

# Reboot function
def reboot_system():
    print("Rebooting system...")
    subprocess.run(['sudo', 'reboot'])

# Function to read the last executed script index from the state file
def read_state():
    if os.path.exists(state_file):
        with open(state_file, 'r') as f:
            return int(f.read().strip())
    return 0

# Function to write the current script index to the state file
def write_state(index):
    with open(state_file, 'w') as f:
        f.write(str(index))

# Read the last executed script index
last_executed_script = read_state()

# Execute the scripts starting from the last executed one
for i in range(last_executed_script, len(script_urls)):
    time.sleep(50)
    run_script(script_urls[i], marker_paths[i])
    scp_log(marker_paths[i])
    time.sleep(50)
    write_state(i + 1)
    time.sleep(50)

    # Reboot after the second script
    if i == 0 or i == 1:
        reboot_system()

    if i == 4:
        reboot_system()

print("All scripts executed successfully.")
OUTPUT_FILE="/home/pinaka/all_in_one/ceph_dashboard_credentials.txt"

def display_dashboard_info(output_file):
    dashboard_url = None
    dashboard_username = None
    dashboard_password = None

    # Check if the output file exists
    if not os.path.exists(output_file):
        print("Output file does not exist.")
        return

    # Read the output file
    with open(output_file, 'r') as file:
        for line in file:
            if line.startswith("DASHBOARD_URL="):
                dashboard_url = line.split('=', 1)[1].strip()
            elif line.startswith("DASHBOARD_USERNAME="):
                dashboard_username = line.split('=', 1)[1].strip()
            elif line.startswith("DASHBOARD_PASSWORD="):
                dashboard_password = line.split('=', 1)[1].strip()

    # Display the values
    if dashboard_url and dashboard_username and dashboard_password:
        print(f"Ceph Dashboard URL: {dashboard_url}")
        print(f"Ceph Dashboard USERNAME: {dashboard_username}")
        print(f"Ceph Dashboard Admin Password: {dashboard_password}")
    else:
        print("Failed to read the dashboard details from the output file.")

display_dashboard_info(OUTPUT_FILE)

def disable_service(service_name):
    print(f"Disabling service {service_name}...")
    subprocess.run(['sudo', 'systemctl', 'disable', service_name])
    subprocess.run(['sudo', 'systemctl', 'stop', service_name])

disable_service('script_runner.service')
