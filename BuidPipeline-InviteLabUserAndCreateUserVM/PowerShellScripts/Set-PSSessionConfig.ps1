<#
.SYNOPSIS
    Set PSSessionConfigure on target vm.
.DESCRIPTION
    Utilize WinRM to run powershell script remotely on target vm.
	Set PSSessionConfigure on target vm to allow local admin to use WinRM in rest part of pipeline and future tasks.
.INPUTS
    - labStudentUserName: local admin account
    - vmStudentUserName: lab student user account
    - vmStudentPassword: lab student user password
    - vmShortName: lab vm name
.OUTPUTS
    - N/A
.NOTES
    - This is a temporate solution to bypass the access deny bug when running PowerShell
    script remotely on target vm using non-pre-setup student account.
    - All the reference of this script can be found in wiki page -
    "How to run PowerShell script on remote vm via VSTS".
    - This is the last step that the PowerShell script will be run remotely on target vm 
    by student account.

    Created by: Henry.Xu

#>

Param(
	[string]$vmStudentUserName,
	[string]$vmStudentPassword,
	[string]$labAdminUserName,
	[string]$vmShortName
)

$command = {
Param([string]$labAdminUserName)`
Function Set-SessionConfig{`
 Param([string]$labAdminUserName);`
 $account = New-Object Security.Principal.NTAccount $labAdminUserName;`
 $sid = $account.Translate([Security.Principal.SecurityIdentifier]).Value;`
 $config = Get-PSSessionConfiguration -Name "Microsoft.PowerShell";`
 $existingSDDL = $Config.SecurityDescriptorSDDL;`
 $isContainer = $false;`
 $isDS = $false;`
 $SecurityDescriptor = New-Object -TypeName Security.AccessControl.CommonSecurityDescriptor -ArgumentList $isContainer,$isDS, $existingSDDL;`
 $accessType = "Allow";`
 $accessMask = 268435456;`
 $inheritanceFlags = "none";`
 $propagationFlags = "none";`
 $SecurityDescriptor.DiscretionaryAcl.AddAccess($accessType,$sid,$accessMask,$inheritanceFlags,$propagationFlags);`
 $SecurityDescriptor.GetSddlForm("All");`
}`
write-host "#### Inside session ####"; `
$newSDDL = Set-SessionConfig -labAdminUserName $labAdminUserName;`
Set-PSSessionConfiguration -name Microsoft.PowerShell -SecurityDescriptorSddl $newSDDL -force;`
}

write-host "#### Outside session ####" 
write-host "Following commands will be run on the remote machine under account $vmStudentUserName."

### Lab user credential for remote session, password has to be encryted.
$RemoteSessionPassword = ConvertTo-SecureString $vmStudentPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($vmStudentUserName, $RemoteSessionPassword) 

### Setup session option to skip certificate check and invoke the command in script block.
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

$vmFqdn = $vmShortName + ".canadacentral.cloudapp.azure.com"

Invoke-Command -ComputerName $vmFqdn -UseSSL -SessionOption $so -Credential $credential -ScriptBlock $command -argumentlist ($labAdminUserName)
