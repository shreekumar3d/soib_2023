# HOWTO Deallocate Azure Node from Itself

Azure VMs continue being billed even after shutdown.  This is a problem,
because we don't want to pay them any more than we use.  To stop billing,
VMs have to be "deallocated".  Azure provides a method to deallocate nodes
based on time of day or something like that (scheduled deallocation), but
that's not what we need.

In an ideal world, VMs could be configured to deallocate at shutdown. But
guess what... Azure belonging to MS whose OS likes restarting dozens of
times - hardly a company that would think of adding such a scenario.

So, how to get a node to shoot itself in the head... err deallocate
itself ? (not exactly - I don't see a physical equivalent)

## Solution

Luckily found this article

https://gist.github.com/weltonrodrigo/6540cac402536c8a771ee4f92f5fdc9e

which is what we want.  Basically turns out, to deallocate itself, a VM
needs to be given the role to "manage" itself first. Almost perfect but
the article wanted me to go clicking on the UI for this step.

Luckily Google AI was able to help with "azure cli give a vm permission
to manage itself". Here are the contents:

To give an Azure Virtual Machine (VM) the permission to manage itself
using the Azure CLI, you primarily utilize Managed Identities for Azure
Resources. This allows the VM to authenticate to Azure AD and access
other Azure resources without needing to manage credentials directly.

Here's a breakdown of the process:

- Enable System-Assigned Managed Identity on the VM: This assigns a
unique identity to the VM within Azure AD, managed by Azure.

    az vm identity assign --resource-group <your-resource-group> --name <your-vm-name>

- Replace <your-resource-group> with the name of your resource group
  and <your-vm-name> with the name of your VM. Assign Roles to the
  Managed Identity. Once the system-assigned identity is enabled,
  you can assign Azure roles to it, granting the VM specific
  permissions to manage itself or other resources. For a VM to
  manage itself, you would assign roles that grant permissions over
  its own resource group or specific resources within that group.
  For example, to allow the VM to restart itself, you would assign a
  role that includes the Microsoft.Compute/virtualMachines/restart/action
  permission. The "Virtual Machine Contributor" built-in role includes a
  broad set of permissions for managing VMs, including restart, start, and stop.
  To assign a role to the VM's managed identity:

    az role assignment create --assignee <managed-identity-object-id> --role "Virtual Machine Contributor" --scope /subscriptions/<your-subscription-id>/resourceGroups/<your-resource-group>/providers/Microsoft.Compute/virtualMachines/<your-vm-name>

- Adjust the --role and --scope as needed based on the specific management
  actions you want the VM to perform. For broader self-management capabilities,
  you might assign the role at a higher scope (e.g., the resource group).
  (yeah, that sounds nifty, but I am not doing it yet)

By following these steps, the Azure VM's managed identity will have the
necessary permissions to interact with Azure resources, including its
own management operations, based on the assigned roles.

## Implementation

The assign identity command returns JSON that looks like this:

    {
      "systemAssignedIdentity": "<identity>",
      "userAssignedIdentities": {}
    }

You basically plug the identity, subscriber id, resource group name (soib-cluster),
and VM name (e.g. vm-compute-node-1), and the node will be ready to manage itself.
Each of these az commands return JSON.

After that it's a breeze. You need to goto the compute node, and

Install Azure CLI

    $ curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

650 MB download on minimal ubuntu installs. Eeks!

When you want the node to shutdown and deallocate itself, use this:

    $ az login --identity && az vm deallocate -g soib-cluster -n `hostname`

That's it!