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

# Skip if management VPC is preconfigured
if ($config.env_vpc -ne $null) {
    Write-Host "Management VPC is preset. Skipping..."
    return
}

# Set default values for config parameters
Set-EnvConfigDefaults -Config $config

# Delete VPC resources
Write-Host "Destroying VPC resources..."
$stack_name = ("vpc-" + $config.env_name).Replace(".", "-")
aws cloudformation delete-stack --region $config.aws_region --stack-name $stack_name | Out-Null
Write-Host "VPC resources destroyed."

# Clear Management resources
$resources.env_vpc = $null
$resources.env_subnet = $null

# Write Management resources
Write-EnvResources -Path $ConfigPath -Resources $resources