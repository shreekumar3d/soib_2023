#!../py/bin/python3
# Takes all the compute nodes and gives them azure rights to
# manage themselves.  This ensures that each node can deallocate
# itself, stopping billing
import subprocess
import json
from pprint import pprint

def run_az_command(command):
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        result = json.loads(result.stdout)
        return result
    except subprocess.CalledProcessError as e:
        print(f"Error executing Azure CLI command: {e}")
        print(f"Stderr: {e.stderr}")
        raise RuntimeError("Failed to run AZ command")
    except json.JSONDecodeError:
        print("Error decoding JSON output from Azure CLI.")
        raise RuntimeError("Bad JSON from AZ command")


node_list = run_az_command(["az", "vm", "list", "-d"])
for node in node_list:
    if node['name']=='vm-head-node':
        continue
    print(node['name'])
    print(f"  id={node['id']}")
    print("  Setting identity...")
    sid_result = run_az_command([
                   "az", "vm", "identity", "assign",
                   "--resource-group", node["resourceGroup"],
                   "--name", node["name"]])
    sid = sid_result["systemAssignedIdentity"]
    #pprint(sid_result)
    print("  Allowing self management for deallocate rights...")
    assign_role = run_az_command([
                   "az", "role", "assignment", "create",
                   "--assignee", sid,
                   "--role", 'Virtual Machine Contributor',
                   "--scope", node["id"]])
    #pprint(assign_role)
    print("  Current role:", assign_role["roleDefinitionName"])
#pprint(result)
