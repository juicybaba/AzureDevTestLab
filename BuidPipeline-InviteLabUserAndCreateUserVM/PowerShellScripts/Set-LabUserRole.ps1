<#
.SYNOPSIS
    Assgin "DevTest Lab User" role to invited user
.DESCRIPTION
    Assgin "DevTest Lab User" role to invited user, if it is not assigned yet
.INPUTS
    - resourceGroupName: the name of resource group that the DevTest Lab resides
    - labName: the name of the DevTest Lab
    - invitedUserId: the object ID of the invited user
    - azureAdTenantId: the Tenant ID of the Azure AD where the user is invited to
    - azureAdLogin: the username of an Azure AD member that is owner of the lab
    - azureAdPassword: the password of an Azure AD member that is owner of the lab
.OUTPUTS
    none
.NOTES
    To do list: find out how to assign role without lab owner's credential

    Created by: Henry.Xu
    Last modified by: Ding Liu
#>

#### Assign DevTest Labs User Role to external user on lab vm
Param(
    [string]$resourceGroupName,
    [string]$labName,
    [string]$invitedUserId,
    [string]$azureAdTenantId,
    [string]$azureAdLogin,
    [string]$azureAdPassword
)

#region Login with owner account
    $securePassword = ConvertTo-SecureString $azureAdPassword -AsPlainText -Force
    $creds = New-Object System.Management.Automation.PSCredential($azureAdLogin, $securePassword)
    Add-AzureRmAccount -Credential $creds -TenantId $azureAdTenantId | Out-Null
#endregion Login with owner account


$roleName = "DevTest Labs User"
$resourceTypeName = 'Microsoft.DevTestLab/labs'


# Splatting arguments for Get-AzureRmRoleAssignment cmdlet
    $arguments = @{
        ObjectId = $invitedUserId;
        ResourceGroupName = $resourceGroupName;
        ResourceName = $labName;
        ResourceType = $resourceTypeName;
    }
$existingRoleAssignments = Get-AzureRmRoleAssignment @arguments


# Check if role assignment already exists first
if ( ($existingRoleAssignments).RoleDefinitionName -contains $roleName ) {
    Write-Host "Role assignment already exists..."
} else {
    # Splatting arguments for New-AzureRmRoleAssignment cmdlet
        $arguments = @{
            ObjectID = $invitedUserId;
            RoleDefinitionName = $roleName;
            ResourceGroupName = $resourceGroupName;
            ResourceName = $labName;
            ResourceType = 'Microsoft.DevTestLab/labs';
        }
    New-AzureRmRoleAssignment @arguments
}