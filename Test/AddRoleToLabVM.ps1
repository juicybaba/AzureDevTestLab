


#### Assign Role to external user on lab vm

### Inputs
$RGName = "HenryDevLabTest"
$LabName = "SWI_DEV_LAB"
$VMName = "Test"
$Role = "DevTest Labs User"
$UserEmail = "henry.xu@alithya.com"

### LabVM ID
$LabVMName = $LabName + "/" + $VMName
$ScopeLabVM = (Get-AzureRmResource | Where-Object {$_.Name -eq $LabVMName}).ResourceId

### UserID of external users
$UserIDPrefix = $UserEmail -replace "@", "_"
$UserIDPostfix = "#EXT#@azuresilverplatformbulkswi.onmicrosoft.com"
$UserID = $UserIDPrefix + $UserIDPostfix

#############################################
$UserID
#############################################

### Add role to lab vm.
Get-AzureRmResource -ResourceId $ScopeLabVM

New-AzureRmRoleAssignment -Scope $ScopeLabVM -SignInName $UserID -RoleDefinitionName $Role

Get-AzureRmRoleAssignment -Scope $ScopeLabVM -RoleDefinitionName $Role