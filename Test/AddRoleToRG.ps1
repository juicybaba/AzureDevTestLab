#### Assign Role to external user on resource group

### Inputs
$RGName = "HenryDevLabTest"
$LabName = "SWI_DEV_LAB"
$VMName = "Test"
$Role = "DevTest Labs User"
$UserEmail = "henry.xu@alithya.com"

### Resource Group ID
$ScopeRG = (Get-AzureRmResourceGroup | Where-Object {$_.ResourceGroupName -eq $RGName}).ResourceId

### UserID of external users
$UserIDPrefix = $UserEmail -replace "@", "_"
$UserIDPostfix = "#EXT#@azuresilverplatformbulkswi.onmicrosoft.com"
$UserID = $UserIDPrefix + $UserIDPostfix

#############################################
$UserID
#############################################

### Assign permission on resource group
New-AzureRmRoleAssignment -Scope $ScopeRG -SignInName $UserID -RoleDefinitionName $Role




