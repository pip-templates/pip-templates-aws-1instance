#!/usr/bin/env pwsh

param
(
    [Alias("c", "Path")]
    [Parameter(Mandatory=$false, Position=0)]
    [string] $ConfigPath
)

$ErrorActionPreference = "Stop"

# Load support functions
$rootPath = $PSScriptRoot
if ($rootPath -eq "") { $rootPath = "." }
. "$($rootPath)/lib/include.ps1"
$rootPath = $PSScriptRoot
if ($rootPath -eq "") { $rootPath = "." }

# Read config and resources
$config = Read-EnvConfig -Path $ConfigPath
$resources = Read-EnvResources -Path $ConfigPath

switch ($config.env_type) {
    "cloud" { 
        . "$($rootPath)/cloud/install_vpc.ps1" $ConfigPath
        . "$($rootPath)/cloud/install_vm.ps1" $ConfigPath
        . "$($rootPath)/cloud/configure_vm.ps1" $ConfigPath
        . "$($rootPath)/cloud/install_k8s.ps1" $ConfigPath
        . "$($rootPath)/cloud/install_platform_services.ps1" $ConfigPath
     }
     Default {
         Write-Host "Platform type not specified in config file. Please add 'env_type' to config."
     }
}
