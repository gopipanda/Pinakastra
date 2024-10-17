import os
import json

def load_config(json_file):
    """Read the JSON config file and print export commands."""
    with open(json_file, 'r') as file:
        config = json.load(file)

    for key, value in config.items():
        print(f"export {key}='{value}'")

if __name__ == "__main__":
    config_file = '/home/pinaka/pinak/config.json'  # Path to your JSON config file
    load_config(config_file)
