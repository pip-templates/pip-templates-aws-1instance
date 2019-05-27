function Set-EnvConfigDefaults
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [hashtable] $Config,
        [Parameter(Mandatory=$false, Position=1)]
        [switch] $All
    )
    
    # Set environment variables
    $env:AWS_ACCESS_KEY_ID = $config.aws_access_id
    $env:AWS_SECRET_ACCESS_KEY = $config.aws_access_key 
    
    if ($Config.aws_region -eq $null) {
        $Config.aws_region = "us-east-1"
    }

    if ($Config.env_network_cidr -eq $null) {
        $Config.env_network_cidr = "10.0.0.0/24"
    }

    if ($Config.env_keyname -eq $null) {
        $Config.env_keyname_new = $true
        $Config.env_keyname = $Config.env_name
        
        if ($Config.env_ssh_key -eq $null) {
            $Config.env_ssh_key  = "~/.ssh/id_rsa"
        }
        if ($Config.env_ssh_key -eq "new") {
            $Config.env_ssh_new = $true
            $keyParent = Split-Path -Path $ConfigPath -Parent
            $keyFile = $config.env_name.Replace('.', '-')
            $config.env_ssh_key = "$keyParent/$keyFile"
        }
    } else {
        if ($Config.env_ssh_key -eq $null) {
            $keyParent = Split-Path -Path $ConfigPath -Parent
            $config.env_ssh_key = "$keyParent/$($config.env_keyname).pem"                
        }
    }
    
    if ($Config.vm_instance_type -eq $null) {
        $Config.vm_instance_type = "t2.medium"
    }
    if ($Config.vm_ami -eq $null -and $All) {
        $out = (aws ec2 describe-images --region $Config.aws_region --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-20180126" --query "Images[].ImageId" --output "text") | Out-String
        $Config.vm_ami = $out.Replace("`n", "").Replace("`t", " ").Split(" ")[0]
    }                        
        
}
