## Disable Firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

## Change Time Zone
Set-TimeZone -Name "Eastern Standard Time"

## Disable IE Enhanced Security
$AdminKey = “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}”
$UserKey = “HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}”
Set-ItemProperty -Path $AdminKey -Name “IsInstalled” -Value 0
Set-ItemProperty -Path $UserKey -Name “IsInstalled” -Value 0
Stop-Process -Name Explorer

## Setup File Share On Azure
$acctKey = ConvertTo-SecureString -String "WjUHJ80Fh7VMlYUBP61+PDPcf8Zl4WRxLRHt5jfu0J4l4jNUMNQqXqfCKdsGhmJKswkkTWGNB3IFCyhYEDOAsw==" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList "Azure\hxuscripts", $acctKey
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\hxuscripts.file.core.windows.net\scripts" -Credential $credential -Persist