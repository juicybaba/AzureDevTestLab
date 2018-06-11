
$vmShortNameSeed = $(Get-Date).ToUniversalTime().ToString() -replace "[^a-zA-Z0-9]", ""

Write-Output $("The seed for generating VM shortname is: `"" + $vmShortNameSeed + "`"")

Write-Host "##vso[task.setvariable variable=vmShortNameSeed]$vmShortNameSeed"