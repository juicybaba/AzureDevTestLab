<#
.SYNOPSIS
    Setup timezone for vm.
.DESCRIPTION
    Utilize WinRM to run powershell script remotely on target vm.
	Setup timezone for vm.
.INPUTS
    - labAdminUserName: local admin account
    - labAdminPassword: local admin password
    - timezone: Time zone name
    - vmShortName: lab vm name
.OUTPUTS
    - N/A
.NOTES
    The timezone will be reset to UTC after sysprep.

    Created by: Henry.Xu
#>


Param(
	[string]$labAdminUserName,
	[string]$labAdminPassword,
	[string]$timezone,
	[string]$vmShortName
)

### Define the command for remote session.
### Passing multiple commands and local varibles.
### Check if local admin is already existed.
$command = {
param(`
	$timezone`
)`
write-host "#### Inside $env:computername ####";`
write-host "Changing timezone to $timezone";`
set-timezone $timezone;`
get-timezone;`
}

write-host "#### Outside session ####" 
write-host "Following commands will be run on the remote machine under account $labAdminUserName."

write-host $labAdminPassword
write-host $labAdminUserName
write-host "$vmShortName\$labAdminUserName"
### Create credential for remote session, password has to be encryted.
$RemoteSessionPassword = ConvertTo-SecureString $labAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($labAdminUserName, $RemoteSessionPassword) 

### Setup session option to skip certificate check and invoke the command in script block.
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

$vmFqdn = $vmShortName + ".canadacentral.cloudapp.azure.com"
write-host $vmFqdn
Invoke-Command -ComputerName $vmFqdn -UseSSL -SessionOption $so -Credential $credential -ScriptBlock $command -argumentlist ($timezone)
