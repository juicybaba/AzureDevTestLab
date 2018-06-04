<#
.SYNOPSIS
    Create and add a generic local account to local administrators group for maintenance purpose.
.DESCRIPTION
    Utilize WinRM to run powershell script remotely on target vm.
	Create and add a generic local account to local administrators group for maintenance purpose.
.INPUTS
    - labAdminUserName: local admin account
    - labAdminPassword: local admin password
    - vmStudentUserName: lab student user account
    - vmStudentPassword: lab student user password
    - vmShortName: lab vm name
.OUTPUTS
    - N/A
.NOTES
    If the generic local account has been added already, skip the step.

    Created by: Henry.Xu
#>

Param(
	[string]$labAdminUserName,
	[string]$labAdminPassword,
    [string]$vmStudentUserName,
	[string]$vmStudentPassword,
	[string]$vmShortName
)

### Encrypt local admin password.
$LabAdminDefaultPassword = ConvertTo-SecureString $labAdminPassword -AsPlainText -Force

### Define the command for remote session.
### Passing multiple commands and local varibles.
### Check if local admin is already existed.
$command = {
param(`
	$labAdminUserName,`
	$LabAdminDefaultPassword,`
	$vmShortName`
) `
write-host "#### Inside $env:computername ####";`
$currentLocalAdmins = (Get-LocalGroupMember -Name administrators).name;`
write-host "The current administrators are $currentLocalAdmins";`
write-host "Adding $vmShortName\$labAdminUserName";`
if(("$vmShortName\$labAdminUserName") -in $currentLocalAdmins){`
	write-host "$labAdminUserName is already existed, skip adding."`
}`
else {`
	write-host "Creating $labAdminUserName....";`
	New-LocalUser $labAdminUserName -Password $LabAdminDefaultPassword -FullName $labAdminUserName -Description $labAdminUserName | Add-LocalGroupMember -Group "Administrators";`
};`
Get-LocalGroupMember -Name "Administrators";`
}

write-host "#### Outside session ####" 
write-host "Commands will be run on the remote machine under account $vmStudentUserName."

### Lab user credential for remote session, password has to be encryted.
$RemoteSessionPassword = ConvertTo-SecureString $vmStudentPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($vmStudentUserName, $RemoteSessionPassword) 

### Setup session option to skip certificate check and invoke the command in script block.
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

$vmFqdn = $vmShortName + ".canadacentral.cloudapp.azure.com"

Invoke-Command -ComputerName $vmFqdn -UseSSL -SessionOption $so -Credential $credential -ScriptBlock $command -argumentlist ($labAdminUserName, $LabAdminDefaultPassword, $vmShortName)
