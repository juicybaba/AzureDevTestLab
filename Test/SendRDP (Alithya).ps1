Param(
    #[string]$VMID,
    [string]$UserEmail,
    [string]$tenantID,
    [string]$userLogin,
    [string]$userPassword,
    [string]$SMTPServer,
    [string]$EmailFrom,
    [string]$LabName,
    [string]$VMName
)

$FilePath = "D:\$VMName.rdp"

$RGName = (Get-AzureRmVM | where-Object {$_.Name -eq $VMName -and $_.ID -like "*$LabName*"}).ResourceGroupName

Get-AzureRmRemoteDesktopFile -ResourceGroupName $RGName -Name $VMName -LocalPath $FilePath
dir d:\

$Password = ConvertTo-SecureString $userPassword -AsPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential $userLogin, $Password

[string[]]$CC = "henry.xu@alithya.com", "ding.liu@alithya.com"

$Subject = "Send From Alithya"

$Body = "This is sample email sent using Sendgrid account create on Microsoft Azure. The script written is easy to use."

Send-MailMessage -smtpServer $SMTPServer -Credential $credential -Usessl -Port 587 -from $EmailFrom -to $UserEmail -cc $CC -subject $Subject -Body $Body -BodyAsHtml -Attachments $FilePath
$SMTPServer

$credential 
