<#
    .SYNOPSIS
        Invite a user to Azure AD using email address
    .DESCRIPTION
        Invite a user to Azure AD by sending an email to specific email address. 
        If the email address already exists in the Azure AD, find the existing 
        user that has this email address.
    .INPUTS
        - targetEmailAddress: the email address that invitation should be sent to
        - azureAdTenantId: the Tenant ID of the Azure AD that the target user are invited to
        - azureAdLogin: the login of the Azure AD member user, used for connecting to Azure AD
        - azureAdPassword: the password of the Azure AD member user, used for connecting to azure AD
    .OUTPUTS
        - invitedUserId: the ObjectID of the invited user
        - invitedUserDisplayName: the DisplayName of the invited user
    .NOTES
        Created by: Ding Liu
        To-do list:
        - Parameter validation
        - Error handling
        - Customize message in invitation email, so user will get the context of it
#>

Param(
    # Email address of the new lab user
    [Parameter(Mandatory=$true, Position=0)]
    [string]$targetEmailAddress,

    # Tenant ID of the Azure AD
    [Parameter(Mandatory=$true)]
    [string]$azureAdTenantId,

    # Login of the Azure AD member user
    [Parameter(Mandatory=$true)]
    [string]$azureAdLogin,

    # password of the Azure AD member user
    # The value of the password comes from an encrypted variable in Visual Studio Team Service
    # so it doen't need to use "secureString" type.
    # If this script get ported to other environment, it should be modified accordingly.
    [Parameter(Mandatory=$true)]
    [string]$azureAdPassword
)


#region Connect to Azure AD
    Write-Host "Importing Azure AD module"
    $adModulePath = $PSScriptRoot + "\requiredModules\AzureAD\2.0.0.131\AzureAD.psd1"
    Import-Module -Name $adModulePath

    Write-Host " "
    Write-Host "Creating credential"
    $securePassword = ConvertTo-SecureString $azureAdPassword -AsPlainText -Force
    $creds = New-Object System.Management.Automation.PSCredential($azureAdLogin, $securePassword)

    Write-Host " "
    Write-Host "Connecting to Azure AD"
    Connect-AzureAD -TenantId $azureAdTenantId -Credential $creds | Out-Null
#endregion Connect to Azure AD


#region Invite target user
    [string]$invitedUserId = ""
    [string]$invitedUserPrincipalName = ""
    [string]$vmStudentUserName = ""

    # Splatting arguments of New-AzureADMSInvitation cmdlet
    $arguments = @{
        InvitedUserEmailAddress = $targetEmailAddress;
        SendInvitationMessage = $true;
        InviteRedirectUrl = "https://portal.azure.com";
        InvitedUserType = "Guest";
    }
    $invitedUser = New-AzureADMSInvitation @arguments

    $invitedUserId = $invitedUser.InvitedUser.Id
    $invitedUserPrincipalName = (get-azureaduser -ObjectId $invitedUserId).UserPrincipalName
    $vmStudentUserName = $targetEmailAddress.Split("@")[0]
#endregion Invite target user

#region Output variables
    Write-Host "##vso[task.setvariable variable=invitedUserId]$invitedUserId"
    Write-Host "##vso[task.setvariable variable=invitedUserPrincipalName]$invitedUserPrincipalName"
    Write-Host "##vso[task.setvariable variable=vmStudentUserName]$vmStudentUserName"
#endregion Output variables