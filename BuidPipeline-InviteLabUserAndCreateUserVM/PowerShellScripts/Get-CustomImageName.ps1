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
    [string]$module
)

$customImages = Get-AzureRmResource -ResourceType 'Microsoft.Compute/images' -ResourceGroupName $resourceGroupName

$candidateNames = $customImages.Name.Where({ $_ -like "*$module*" })

if ($candidateNames.count -eq 1) {
    $customImageName = $candidateNames
} else {
    $customImageName = ($candidateNames | Sort-Object -Descending)[0]
}

Write-Output $("The custom image used to create VM is `"" + $customImageName + "`"")

Write-Host "##vso[task.setvariable variable=customImageName]$customImageName"
