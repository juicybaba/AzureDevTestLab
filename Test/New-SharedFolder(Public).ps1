<#
    .SYNOPSIS
        Link the shared folder on Azure 
    .DESCRIPTION
        Utilize WinRM to run powershell script remotely on target vm.
		Link the shared folder to share the public file to lab users.
		Shared folder is under resource group - Alithya-DevTestLabs-Src-rg, storage account - alithyadevtestlabs
		The $command part is generated automatically by Azure.
    .INPUTS
        - labAdminUserName: local admin account
		- labAdminPassword: local admin password
		- vmShortName: lab vm name
    .OUTPUTS
        - Z: will be created on the target vm.
    .NOTES
        Created by: Henry.Xu

#>

Param(
	[string]$labAdminUserName,
	[string]$labAdminPassword,
	[string]$vmShortName
)

### Define the command for remote session.
### Passing multiple commands and local varibles.
### Check if local admin is already existed.
$command = {
write-host "#### Inside $env:computername ####";`
write-host "Adding Shared Folder - devtestlab-public as P:";`
cmdkey /add:alithyadevtestlabs.file.core.windows.net\devtestlab-public /user:Azure\alithyadevtestlabs /pass:KSPCEuJPVFro+1AiLGyqKQrs8TLactguRN127nBOvYA++Oyq3InBEd4co+DfFkS+Y/KHkAdeT+/JCUL9626VdQ==;`
net use P: \\alithyadevtestlabs.file.core.windows.net\devtestlab-public /persistent:yes;`
get-psdrive;`
write-host "###############";`
cd P:\;`
write-host "###############";`
dir;`
write-host "###############";`
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
