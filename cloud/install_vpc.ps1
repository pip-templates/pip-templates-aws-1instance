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

# Skip if management VPC is preconfigured
if ($config.env_vpc -ne $null) {
    Write-Host "Management VPC is set. Skipping..."
    return
}

# Set default values for config parameters
Set-EnvConfigDefaults -Config $config

# Prepare Cloud-Formation template
Build-EnvTemplate -InputPath "$($path)/../templates/vpc_resources.yml" -OutputPath "$($path)/../temp/vpc_resources.yml" -Params1 $config -Params2 $resources

# Create AWS resources
Write-Host "Creating VPC resources..."
$stack_name = ("vpc-" + $config.env_name).Replace(".", "-")
aws cloudformation create-stack --region $config.aws_region --stack-name $stack_name --template-body file://$($path)/../temp/vpc_resources.yml

# Wait until stack creation is completed
Write-Host "Waiting for VPC resources to be created. It may take up to 10 minutes..."
aws cloudformation wait stack-create-complete --region $config.aws_region --stack-name $stack_name
Write-Host "VPC resources created."

# Read Management VPC parameters
Write-Host "Reading VPC parameters"

$out = (aws ec2 describe-vpcs --region $config.aws_region --filters "Name=tag:Name,Values=$($config.env_name)" --query "Vpcs[].VpcId" --output "text") | Out-String
$env_vpc = $out.Replace("`n", "").Replace("`t", " ").Split(" ")[0]

$out = (aws ec2 describe-subnets --region $config.aws_region --filters "Name=tag:Name,Values=$($config.env_name)" --query "Subnets[].SubnetId" --output "text") | Out-String
$env_subnet = $out.Replace("`n", "").Replace("`t", " ").Split(" ")[0]

# Write VPC resources
$resources.env_vpc = $env_vpc
$resources.env_subnet = $env_subnet

# Write VPC esources
Write-EnvResources -Path $ConfigPath -Resources $resources