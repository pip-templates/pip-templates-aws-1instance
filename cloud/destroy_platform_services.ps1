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
$ansible_inventory += "`r`n[workers]"
$i = 0
foreach ($node in $resources.k8s_worker_ips) {
    $ansible_inventory += "worker$i ansible_host=$node ansible_ssh_user=$($config.cloud_instance_username) ansible_ssh_private_key_file=$($config.env_ssh_key)"
    $i++
}

Set-Content -Path "$path/../temp/cloud_k8s_ansible_hosts" -Value $ansible_inventory

# Whitelist nodes
Build-EnvTemplate -InputPath "$($path)/../templates/ssh_keyscan_playbook.yml" -OutputPath "$($path)/../temp/ssh_keyscan_playbook.yml" -Params1 $config -Params2 $resources
ansible-playbook -i "$path/../temp/cloud_k8s_ansible_hosts" "$path/../temp/ssh_keyscan_playbook.yml"

# Install platform services
Build-EnvTemplate -InputPath "$($path)/../templates/cloud_destroy_platform_services_playbook.yml" -OutputPath "$($path)/../temp/cloud_destroy_platform_services_playbook.yml" -Params1 $config -Params2 $resources
ansible-playbook -i "$path/../temp/cloud_k8s_ansible_hosts" "$path/../temp/cloud_destroy_platform_services_playbook.yml"
