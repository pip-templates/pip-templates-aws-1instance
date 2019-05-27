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

# Set default values for config parameters
Set-EnvConfigDefaults -Config $config -All

# Prepare Cloud-Formation template
Build-EnvTemplate -InputPath "$($path)/../templates/vm_resources.yml" -OutputPath "$($path)/../temp/vm_resources.yml" -Params1 $config -Params2 $resources

# Create key pair
if ($config.env_keyname_new) {
    # Create ssh key
    if ($config.env_ssh_new) {
        Remove-Item -Path "$($config.env_ssh_key)*"
        ssh-keygen -q -t rsa -f $config.env_ssh_key
    }

    # Register key pair
    $publicKey = (Get-Content -Path "$($config.env_ssh_key).pub" ) | Out-String
    aws ec2 import-key-pair --region $config.aws_region --key-name $config.env_keyname --public-key-material $publicKey

    Write-Host "Created keypair $($config.env_keyname)."
}

# Create vm resources
Write-Host "Creating vm resources..."
$stack_name = ("vm-" + $config.env_name).Replace(".", "-")
aws cloudformation create-stack --region $config.aws_region --stack-name $stack_name --template-body file://$($path)/../temp/vm_resources.yml

# Wait until stack creation is completed
Write-Host "Waiting for AWS resources to be created. It may take up to 10 minutes..."
aws cloudformation wait stack-create-complete --region $config.aws_region --stack-name $stack_name
Write-Host "vm resources created."

# Read Management vm IP addresses
Write-Host "Reading parameters of Management vm"

$out = (aws ec2 describe-instances --region $config.aws_region --filters "Name=tag:Name,Values=vm-$($config.env_name)" --query "Reservations[].Instances[].PublicIpAddress" "Name=instance-state-name,Values=running" --output "text") | Out-String
$vm_public_address = $out.Replace("`n", "").Replace("`t", " ").Split(" ")[0]
$vm_inventory = $vm_public_address + " ansible_ssh_user=ubuntu ansible_ssh_private_key_file=$($config.env_ssh_key)"

$out = (aws ec2 describe-instances --region $config.aws_region --filters "Name=tag:Name,Values=vm-$($config.env_name)" --query "Reservations[].Instances[].PrivateIpAddress" "Name=instance-state-name,Values=running" --output "text") | Out-String
$vm_private_address = $out.Replace("`n", "").Replace("`t", " ").Split(" ")[0]

# Write vm resources
$resources.vm_public_address = $vm_public_address
$resources.vm_private_address = $vm_private_address
$resources.vm_inventory = $vm_inventory

# Write vm resources
Write-EnvResources -Path $ConfigPath -Resources $resources