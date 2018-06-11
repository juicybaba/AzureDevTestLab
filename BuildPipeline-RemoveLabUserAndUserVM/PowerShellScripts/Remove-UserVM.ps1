<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>

Param(
    [string]$resourceGroupName,
    [string]$userEmailAddress
)


$userVms = Get-AzureRmResource -TagName "userEmailAddress" -TagValue $userEmailAddress -ResourceType 'Microsoft.DevTestLab/labs/virtualMachines' -ResourceGroupName $resourceGroupName

foreach ($userVm in $userVms) {
    Remove-AzureRmResource -ResourceId $userVm.ResourceId -Force
}

