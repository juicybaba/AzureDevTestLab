<#
.SYNOPSIS
    Send username, password and RDP file via SendGrid SMTP service. 
.DESCRIPTION
    Send username, password and RDP file via SendGrid SMTP service. 
.INPUTS

    - vmStudentUserName: lab student user account
    - vmStudentPassword: lab student user password
    - vmShortName: lab vm name
    - userEmailAddress: email address of lab user
    - sendGridUserName: username of SendGrid service
    - sendGridPassword: password of SendGrid service
    - sendGridSmtp: SMTP of SendGrid service
    - sendGridSenderEmail: Sender of the email from SendGrid.
    - labName: lab name
.OUTPUTS
    - N/A
.NOTES
    Email will be sent to lab user and cc to $CC.

    Created by: Henry.Xu
#>

Param(
    [string]$userEmailAddress,
    [string]$sendGridUserName,
    [string]$sendGridPassword,
    [string]$sendGridSmtp,
    [string]$sendGridSenderEmail,
    [string]$labName,
    [string]$vmShortName,
    [string]$vmStudentUserName,
    [string]$vmStudentPassword
)

$FilePath = "D:\$vmShortName.rdp"

$RGName = (Get-AzureRmVM | where-Object {$_.Name -eq $vmShortName -and $_.ID -like "*$labName*"}).ResourceGroupName

Get-AzureRmRemoteDesktopFile -ResourceGroupName $RGName -Name $vmShortName -LocalPath $FilePath

dir d:\

$securePassword = ConvertTo-SecureString $sendGridPassword -AsPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential $sendGridUserName, $securePassword

[string[]]$CC = "henry.xu@alithya.com", "ding.liu@alithya.com"

$Subject = "No-reply: Lab VM Information for $vmStudentUserName"

$Body = "Hi,<br/><br/>Please use the attached RDP file to login your lab VM.<br/><br/>The username is: $vmStudentUserName <br/>The password is: $vmStudentPassword <br/><br/>Please change your password as soon as possible.<br/><hr/><strong>NOTICE OF CONFIDENTIALITY:</strong><br/>This email and any attachments may contain information that is privileged, and/or confidential, and is meant only for the intended recipient(s). If the reader of this email is not the intended recipient, you are hereby notified that any unauthorized dissemination, distribution or reproduction of this email, or its attachments, is strictly prohibited. If you have received this email in error, please advise the sender immediately and destroy the email and any attachments.<hr/>"

Send-MailMessage -smtpServer $sendGridSmtp -Credential $credential -Usessl -Port 587 -from $sendGridSenderEmail -to $userEmailAddress -cc $CC -subject $Subject -Body $Body -BodyAsHtml -Attachments $FilePath
