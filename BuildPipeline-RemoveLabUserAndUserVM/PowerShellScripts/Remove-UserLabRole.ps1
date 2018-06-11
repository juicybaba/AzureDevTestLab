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
    [string]$labName,
    [string]$userEmailAddress,
    [string]$azureAdTenantId,
    [string]$azureAdLogin,
    [string]$azureAdPassword
)

$resourceType = 'Microsoft.DevTestLab/labs'
$roleDefinitionName = 'DevTest Labs User'


#region Connect to Azure AD
    # Write-Host "Importing Azure AD module"
    # $adModulePath = $PSScriptRoot + "\requiredModules\AzureAD\2.0.0.131\AzureAD.psd1"
    # Import-Module -Name $adModulePath -Verbose

    Write-Host " "
    Write-Host "Creating credential"
    $securePassword = ConvertTo-SecureString $azureAdPassword -AsPlainText -Force
    $creds = New-Object System.Management.Automation.PSCredential($azureAdLogin, $securePassword)

    Add-AzureRmAccount -TenantId $azureAdTenantId -Credential $creds 

    Write-Host " "
    Write-Host "Connecting to Azure AD"
    Connect-AzureAD -TenantId $azureAdTenantId -Credential $creds -Verbose
#endregion Connect to Azure AD

$user = $(Get-AzureADUser).where({ $_.Mail -eq $userEmailAddress })

Start-Sleep 2
# $arguments = @{
#     ObjectId = $user.ObjectId;
#     ResourceGroupName = $resourceGroupName;
#     ResourceName = $labName;
#     ResourceType = $resourceType;
# }
# $existingRoleAssignments = Get-AzureRmRoleAssignment @arguments

# if ($existingRoleAssignments.RoleDefinitionName -contains $roleDefinitionName) {
    $arguments = @{
        ObjectId = $user.ObjectId;
        ResourceGroupName = $resourceGroupName;
        ResourceName = $labName;
        ResourceType = $resourceType;
        RoleDefinitionName = $roleDefinitionName;
    }
    Remove-AzureRmRoleAssignment @arguments
# }