import os
import subprocess
import time
import stat

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

HOSTNAME = "hci"
IP_ADDRESS = "192.168.249.23"
NETMASK="255.255.255.0"
INTERFACE_01 = "eno1"
INTERFACE_02 = "eno2"
GATEWAY="192.168.249.1"
DNS_SERVERS="8.8.8.8 8.8.4.4"
ROOT_USER_PASSWORD = "pinaka"

# Function to download and run a shell script
# Function to download and run a shell script with environment variables
def run_script(url, marker_path):
    if not os.path.exists(marker_path):
        # Define environment variables
        env = os.environ.copy()
        env.update({
            'HOSTNAME': HOSTNAME,
            'IP_ADDRESS': IP_ADDRESS,
            'NETMASK': NETMASK,
            'INTERFACE_01': INTERFACE_01,
            'INTERFACE_02': INTERFACE_02,
            'GATEWAY': GATEWAY,
            'DNS_SERVERS': DNS_SERVERS,
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

        # Handle the result
        if result.returncode == 0:
            with open(marker_path, 'w') as f:
                f.write(result.stdout)  # Write stdout output to the marker file
                f.write(result.stderr) # Write stderr if any warnings/info exist
                f.write('done\n')
            print(f"Output of {url}:\n{result.stdout}")
        else:
            print(f"Error occurred while executing {url}:\n{result.stderr}")
    else:
        print(f"{marker_path} already completed, skipping...")



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
    run_script(script_urls[i], marker_paths[i])
    write_state(i + 1)
    time.sleep(100)

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
