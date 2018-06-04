
Param(
	[string]$labAdminUserName,
	[string]$labAdminPassword,
	[string]$vmStudentUserName,
	[string]$vmShortName
)

### Define the command for remote session.
### Passing multiple commands and local varibles.
### Check if local admin is already existed.
$command = {
param(`
	$vmStudentUserName`
)`
write-host "#### Inside $env:computername ####";`
$user=[ADSI]"WinNT://localhost/$vmStudentUserName";`
$user.passwordExpired = 1;`
$user.setinfo();`
Get-LocalUser -name $vmStudentUserName | fl;`
}

write-host "#### Outside session ####" 
write-host "Following commands will be run on the remote machine under account $labAdminUserName."
write-host "#####################`n$command`n#####################`n"

write-host "admin password is coming"
write-host $labAdminPassword
write-host "admin password has came"

### Create credential for remote session, password has to be encryted.
$RemoteSessionPassword = ConvertTo-SecureString $labAdminPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($labAdminUserName, $RemoteSessionPassword) 

### Setup session option to skip certificate check and invoke the command in script block.
$so = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck

$vmFqdn = $vmShortName + ".canadacentral.cloudapp.azure.com"
write-host "FQDN is coming"
write-host $vmFqdn
write-host "admin password is coming again"
write-host $labAdminPassword
write-host "admin password has came"
Invoke-Command -ComputerName $vmFqdn -UseSSL -SessionOption $so -Credential $credential -ScriptBlock $command -argumentlist ($vmStudentUserName)



