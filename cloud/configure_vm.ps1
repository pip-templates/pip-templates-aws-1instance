#!/usr/bin/env pwsh

param
(
    [Alias("c", "Path")]
    [Parameter(Mandatory=$false, Position=0)]
    [string] $ConfigPath
)

# Load support functions
$path = $PSScriptRoot
if ($path -eq "") { $path = "." }
. "$($path)/../lib/include.ps1"
$path = $PSScriptRoot
if ($path -eq "") { $path = "." }

# Read config and resources
$config = Read-EnvConfig -Path $ConfigPath
$resources = Read-EnvResources -Path $ConfigPath

# Skip if Management is disabled
if ($resources.vm_public_address -eq $null) {
    Write-Host "Management vm hasn't been created. Exiting..."
    return
}

# Wait until Management instance is running
Write-Host "Waiting for Management vm to run..."
aws ec2 wait instance-running --region $config.aws_region --filters "Name=tag:Name,Values=vm-$($config.env_name)"

# Prepare hosts file
$inventory = @("[vms]")
$inventory += $resources.vm_inventory

Set-Content -Path "$path/../temp/hosts" -Value $inventory

# Whitelist vm
Build-EnvTemplate -InputPath "$($path)/../templates/ssh_keyscan_playbook.yml" -OutputPath "$($path)/../temp/ssh_keyscan_playbook.yml" -Params1 $config -Params2 $resources
ansible-playbook -i "$path/../temp/hosts" "$path/../temp/ssh_keyscan_playbook.yml"

# Configure vm
Build-EnvTemplate -InputPath "$($path)/../templates/vm_playbook.yml" -OutputPath "$($path)/../temp/vm_playbook.yml" -Params1 $config -Params2 $resources
ansible-playbook -i "$path/../temp/hosts" "$path/../temp/vm_playbook.yml"
