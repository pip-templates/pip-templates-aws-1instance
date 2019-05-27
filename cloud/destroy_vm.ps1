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

# Read config and resources
$config = Read-EnvConfig -Path $ConfigPath
$resources = Read-EnvResources -Path $ConfigPath

# Set default values for config parameters
Set-EnvConfigDefaults -Config $config

# Delete vm resources
Write-Host "Destroying vm resources..."
$stack_name = ("vm-" + $config.env_name).Replace(".", "-")
aws cloudformation delete-stack --region $config.aws_region --stack-name $stack_name | Out-Null
Write-Host "VM resources destroyed."

# Delete key pair
if ($config.env_keyname_new) {
    aws ec2 delete-key-pair --region $config.aws_region --key-name $config.env_keyname

    Write-Host "Destroyed keypair $($config.env_keyname)."
}

# Clear vm resources
$resources.vm_public_address = $null
$resources.vm_private_address = $null
$resources.vm_inventory = $null

# Write vm resources
Write-EnvResources -Path $ConfigPath -Resources $resources