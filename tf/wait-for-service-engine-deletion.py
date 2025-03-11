import requests
import json
import urllib3
import sys
import time

# Suppress SSL warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def get_cloud_uuid(controller, session, cloud_name):
    cloud_endpoint = f"https://{controller}/api/cloud"
    response = session.get(cloud_endpoint)
    if response.status_code != 200:
        print("Failed to retrieve cloud information")
        return None
    
    clouds = response.json().get("results", [])
    for cloud in clouds:
        if cloud.get("name") == cloud_name:
            return cloud.get("uuid")
    return None

def get_service_engines(controller, username, password, cloud_name):
    api_endpoint = f"https://{controller}/api/serviceengine"
    login_endpoint = f"https://{controller}/login"
    
    session = requests.Session()
    session.verify = False  # Disable SSL verification
    
    # Authenticate
    auth_payload = {"username": username, "password": password}
    response = session.post(login_endpoint, json=auth_payload)
    
    if response.status_code != 200:
        print("Authentication failed", file=sys.stderr)
        sys.exit(1)
    
    # Get Cloud UUID
    cloud_uuid = get_cloud_uuid(controller, session, cloud_name)
    if not cloud_uuid:
        return False
    
    # Get Service Engines
    response = session.get(api_endpoint)
    if response.status_code != 200:
        return False
    
    service_engines = response.json().get("results", [])
    
    filtered_se = [se for se in service_engines if se.get("cloud_ref", "").endswith(cloud_uuid)]

    return filtered_se  # Return the list of service engines

def wait_for_service_engines_deletion(controller, username, password, cloud_name, timeout=300, retry_interval=10):
    start_time = time.time()
    
    while True:
        service_engines = get_service_engines(controller, username, password, cloud_name)
        
        # If no Service Engines remain, exit with success
        if not service_engines:
            print("All Service Engines have been deleted.")
            return 0
        
        # Check if timeout has been reached
        elapsed_time = time.time() - start_time
        if elapsed_time >= timeout:
            print(f"Timeout reached after {timeout} seconds. Exiting with failure.", file=sys.stderr)
            return 1
        
        # Wait before retrying
        print(f"Please delete all Service Engines provisioned by the Cloud {cloud_name}. Retry in {retry_interval} seconds...")
        time.sleep(retry_interval)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Error: Missing config file argument.")
        sys.exit(1)

    config_file = sys.argv[1]

    try:
        with open(config_file, "r") as f:
            config = json.load(f)
    except Exception as e:
        print(f"Error reading config file: {e}")
        sys.exit(1)

    controller = config.get("controller")
    username = config.get("username")
    password = config.get("password")
    cloud_name = config.get("cloud_name")
    
    if not all([controller, username, password, cloud_name]):
        print("Missing required parameters: controller, username, password, or cloud.", file=sys.stderr)
        sys.exit(1)

    
    result = wait_for_service_engines_deletion(controller, username, password, cloud_name)
    sys.exit(result) 