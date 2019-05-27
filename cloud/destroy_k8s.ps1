#!/usr/bin/env pwsh

param
(
    [Alias("c", "Path")]
    [Parameter(Mandatory=$false, Position=0)]
    [string] $ConfigPath
)

$ErrorActionPreference = "Stop"

# Load support functions
$path = $PSScriptRoot
if ($path -eq "") { $path = "." }
. "$($path)/../lib/include.ps1"
$path = $PSScriptRoot
if ($path -eq "") { $path = "." }

# Read config and resources
$config = Read-EnvConfig -Path $ConfigPath
$resources = Read-EnvResources -Path $ConfigPath

# Prepare hosts file
$ansible_inventory = @("[masters]")
$ansible_inventory += "master ansible_host=$($resources.vm_public_address) ansible_ssh_user=$($config.cloud_instance_username) ansible_ssh_private_key_file=$($config.env_ssh_key)"

Set-Content -Path "$path/../temp/cloud_k8s_ansible_hosts" -Value $ansible_inventory

# Whitelist nodes
Build-EnvTemplate -InputPath "$($path)/../templates/ssh_keyscan_playbook.yml" -OutputPath "$($path)/../temp/ssh_keyscan_playbook.yml" -Params1 $config -Params2 $resources
ansible-playbook -i "$path/../temp/cloud_k8s_ansible_hosts" "$path/../temp/ssh_keyscan_playbook.yml"

# Destroy k8s cluster
Build-EnvTemplate -InputPath "$($path)/../templates/cloud_k8s_uninstall_playbook.yml" -OutputPath "$($path)/../temp/cloud_k8s_uninstall_playbook.yml" -Params1 $config -Params2 $resources
ansible-playbook -i "$path/../temp/cloud_k8s_ansible_hosts" "$path/../temp/cloud_k8s_uninstall_playbook.yml"
