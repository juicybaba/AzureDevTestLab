<#
    .SYNOPSIS
        Create an Azure AD service principal for VSTS
    .DESCRIPTION

        Create an Azure AD service principal for Visual Studio Team Service, with 
        specified name and password.

        Optionally, you can also specify the role and name prefix of the service 
        principal. The default name prefix is 'VSTS-ServicePrinciple-', the default 
        role is 'contributor'.

        The role of the service princeple can be either "owner" or "contributor".
        The scope of the role can be a subscription, or specific resource group(s) 
        in the subscription.

        If the specified resource group(s) doesn't/don't exist, it/they will be 
        created. You will need to provide a valid location at this time.
    .EXAMPLE
        PS> .\New-VstsServicePrincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password (ConvertTo-SecureString –String "ThePassword" -AsPlainText -Force)
        Create only an Azure AD Application/Principal without any role grant
    .EXAMPLE
        PS> .\New-VstsServicePrincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password (ConvertTo-SecureString –String "ThePassword" -AsPlainText -Force) -resourceGroupNames "ResourceGroupName1","ResourceGroupName2","etc"
        Create an Azure AD Application/Principal and grants the Role on the specified 
        existing Resource Groups (if the Resource Groups do not exists no error will 
        be thrown, they will just be ignored)
    .EXAMPLE
        PS> .\New-VstsServicePrincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password (ConvertTo-SecureString –String "ThePassword" -AsPlainText -Force) -resourceGroupNames "ResourceGroupName1","ResourceGroupName2","etc" -createResourceGroups -location "Canada Central"
        Create an Azure AD Application/Principal and the specified Resource Groups at 
        the provided location, grants the Role to the Resource Groups
    .EXAMPLE
        PS> .\New-VstsServicePrincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password (ConvertTo-SecureString –String "ThePassword" -AsPlainText -Force) -resourceGroupNames "ResourceGroupName1","ResourceGroupName2","etc" -adGroupNames "AdGroupName1", "AdGroupName2", "etc" -createResourceGroups -location "Canada Central"
        Create an Azure AD Application/Principal and the specified Resource Groups at 
        the provided location, grants the Role to the Resource Groups. Also grants the 
        AD groups to the Resource Groups
    .EXAMPLE
        PS> .\New-VstsServicePrincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password (ConvertTo-SecureString –String "ThePassword" -AsPlainText -Force) -grantRoleOnSubscriptionLevel
        Create an Azure AD Application/Principal and grants the Role at subscription 
        level
    .EXAMPLE
        PS> .\New-VstsServicePrincipal.ps1 -subscriptionName "The Subscription Name" -applicationName "TheApplicationName" -password (ConvertTo-SecureString –String "ThePassword" -AsPlainText -Force) -passwordExpirationDateTime (Get-Date "1/1/2020 1:00 AM")
        The default value for the password expiration is 1/1/2099 1:00 AM, you can 
        provide another value like this
    .NOTES
        You'll need to be a Subscription owner to use this function.

        Adopted from Marco Mansi's blog post and GitHub repo:
            - https://bit.ly/2J1bMd2
            - https://bit.ly/2kzRDff
        
        Created by Ding Liu
#>

param (
    [Parameter(HelpMessage="Enter Azure Subscription name. You need to be a Subscription owner to use this function")]
    [Parameter(ParameterSetName="CreateVSTSPrincipalSubscriptionLevel", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalAndResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalWithExistingResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalOnly", Mandatory=$true)]
    [string] $subscriptionName,

    [Parameter(HelpMessage="Provide a name for the SPN that you would create")]
    [Parameter(ParameterSetName="CreateVSTSPrincipalSubscriptionLevel", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalAndResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalWithExistingResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalOnly", Mandatory=$true)]
    [string] $applicationName,

    [Parameter(HelpMessage="Provide a password for SPN application that you would create")]
    [Parameter(ParameterSetName="CreateVSTSPrincipalSubscriptionLevel", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalAndResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalWithExistingResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalOnly", Mandatory=$true)]
    [System.Security.SecureString] $password,

    [Parameter(HelpMessage="The ResourceGroup Name to apply the role")]
    [Parameter(ParameterSetName="CreateVSTSPrincipalAndResourceGroups", Mandatory=$true)]
    [Parameter(ParameterSetName="CreateVSTSPrincipalWithExistingResourceGroups", Mandatory=$true)]
    [string[]] $resourceGroupNames,

    [Parameter(HelpMessage="The names of the Azure Active Directory Groups that should have access")]
    [string[]] $adGroupNames,

    [Parameter(HelpMessage="Create the Resource Groups if they not exists")]    
    [Parameter(ParameterSetName="CreateVSTSPrincipalAndResourceGroups", Mandatory=$true)]
    [switch] $createResourceGroups,

    [Parameter(HelpMessage="The location to create the Resource Groups")] 
    [Parameter(ParameterSetName="CreateVSTSPrincipalAndResourceGroups", Mandatory=$true)]   
    [string] $location,

    [Parameter(Mandatory=$false, HelpMessage="Provide a SPN role assignment")]
    [string] $spnRole = "contributor",

    [Parameter(ParameterSetName="CreateVSTSPrincipalSubscriptionLevel", Mandatory=$true)]
    [Parameter(HelpMessage="Grant the role on the whole subscription")]
    [switch] $grantRoleOnSubscriptionLevel,

    [Parameter(HelpMessage="The prefix for the Application Name", Mandatory=$false)]
    [string] $applicationNamePrefix = "VSTS-ServicePrinciple-",

    [Parameter(HelpMessage="The end datetime when the password expires, default 1/1/2099 1:00 AM", Mandatory=$false)]
    [datetime] $passwordExpirationDateTime = (Get-Date "1/1/2099 1:00 AM")
)


#Initialize
$ErrorActionPreference = "Stop"
$VerbosePreference = "SilentlyContinue"
$displayName = [String]::Format("$applicationNamePrefix{0}", $applicationName)
$homePage = "http://" + $displayName
$identifierUri = $homePage


# Initialize subscription
$isAzureRmModulePresent = Get-Module -Name AzureRM* -ListAvailable
if ([String]::IsNullOrEmpty($isAzureRmModulePresent) -eq $true)
{
    Write-Output "Script requires AzureRM modules to be present. Obtain AzureRM from https://github.com/Azure/azure-powershell/releases. Please refer https://github.com/Microsoft/vsts-tasks/blob/master/Tasks/DeployAzureResourceGroup/README.md for recommended AzureRM versions." -Verbose
    return
}
$isAzureAdModulePresent = Get-Module -Name AzureAD* -ListAvailable
if ([String]::IsNullOrEmpty($isAzureAdModulePresent) -eq $true)
{
    Write-Output "Script requires Azure AD module v2.0 or above to be present. Obtain Azure AD module from https://docs.microsoft.com/powershell/azuread/v2/azureactivedirectory. Please refer https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2?view=azureadps-2.0 for recommended AzureRM versions." -Verbose
    return
}

Import-Module -Name AzureRM.Profile

#When not already logged in, login
if (((get-azurermcontext).Account) -eq $null)
{
    Write-Output "Provide your credentials to access Azure subscription $subscriptionName" -Verbose	
    Login-AzureRmAccount -subscriptionname $subscriptionName
}

$azureSubscription = Get-AzureRmSubscription -SubscriptionName $subscriptionName
$tenantId = $azureSubscription.TenantId
$id = $azureSubscription.Id

#When not already connected to Azure AD, establish a connection as an Azure AD Global Admin
[boolean]$isAzureAdGlobalAdmin = $false
do {
    # For now I still can't find a way to get the current account used to connect Azure AD directly.
    # So for safe and consistency, disconnect from Azure AD first
    Disconnect-AzureAD
    try {
        $context = Connect-AzureAD -TenantId $tenantId
    }
    catch { # An error will only be catched here when user cancel the login
        Write-Host "`nUser canceled login.`nAn Azure AD Global Admin is required to use this script. Stop executing.`n" -ForegroundColor Yellow
        throw "An Azure AD Global Admin is required to use this script. Stop executing." # Will stop executing the whole script
    }
    $loginEmailAddress = $context.Account.Id

    try {
        $azureAdUsers = Get-AzureADUser
    }
    catch [Microsoft.Open.AzureAD16.Client.ApiException] { # Can't get Azure AD users, not an Admin (most likely a guest)
        Write-Host "`nCurrent user is not an Azure AD Global Admin.`nPlease try again as an Azure AD Global Admin.`n" -ForegroundColor Yellow
        Continue
    }

    foreach ($azureAdUser in $azureAdUsers) {
        if ( $azureAdUser.OtherMails -contains $loginEmailAddress ) {
            $currentUser = $azureAdUser
        }
    }
    $currentMembership = Get-AzureADUserMembership -ObjectId $currentUser.ObjectId

    if ( $currentMembership.DisplayName -contains "Company Administrator" ) {
        # "Company Admin" in Azure AD PowerShell is "Global Admin" in Azure Portal
        $isAzureAdGlobalAdmin = $true
        Write-Host "`nSuccessfully connected to Azure AD as a Global Admin.`n" -ForegroundColor Yellow
    } else {
        Write-Host "`nCurrent user is not an Azure AD Global Admin.`nPlease try again as an Azure AD Global Admin.`n" -ForegroundColor Yellow
        Continue
    }
} until ( $isAzureAdGlobalAdmin )



#Check if the application already exists
$app = Get-AzureRmADApplication -IdentifierUri $homePage

if (![String]::IsNullOrEmpty($app) -eq $true)
{
    $appId = $app.ApplicationId
    Write-Output "An Azure AAD Appication with the provided values already exists, skipping the creation of the application..."
}
else
{
    # Create a new AD Application
    Write-Output "Creating a new Application in AAD (App URI - $identifierUri)" -Verbose
    $azureAdApplication = New-AzureRmADApplication -DisplayName $displayName -HomePage $homePage -IdentifierUris $identifierUri -Password $password -EndDate $passwordExpirationDateTime  -Verbose
    $appId = $azureAdApplication.ApplicationId
    Write-Output "Azure AAD Application creation completed successfully (Application Id: $appId)" -Verbose
}


# Check if the principal already exists
$spn = Get-AzureRmADServicePrincipal -ServicePrincipalName $appId

if (![String]::IsNullOrEmpty($spn) -eq $true)
{
    Write-Output "An Azure AAD Appication Principal for the application already exists, skipping the creation of the principal..."
}
else
{
    # Create new SPN
    Write-Output "Creating a new SPN" -Verbose
    $spn = New-AzureRmADServicePrincipal -ApplicationId $appId
    $spnName = $spn.ServicePrincipalNames
    Write-Output "SPN creation completed successfully (SPN Name: $spnName)" -Verbose
    
    Write-Output "Waiting for SPN creation to reflect in Directory before Role assignment"
    Start-Sleep 30
}


# Add the principal role to the Resource Groups (if provided)
if ($resourceGroupNames)
{
    foreach ($resourceGroupName in $resourceGroupNames)
    {
        $rg = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue         

        if ([String]::IsNullOrEmpty($rg) -eq $true)
        {
            if ($createResourceGroups)
            {
                Write-Output "The ResourceGroup $resourceGroupName was NOT found, CREATING it..."
                New-AzureRmResourceGroup -Name $resourceGroupName -Location $location
            }
            else
            {
                Write-Output "The ResourceGroup $resourceGroupName was NOT found, skipping role assignment for this ResourceGroup..."
                continue
            }
        }

        # Check if the role is already assigned
        # If I use the parameter ResourceGroupName, it's not working correctly, it seems to apply a "like" search, so if I have
        # two resourceGroups, i.e. : Test and Test1, the "Get-AzureRmRoleAssignment -ResourceGroupName Test1" is getting both the roles for Test and Test1,
        # that's why I am using a where filtering
        # I have submitted an issue about this, see: https://github.com/Azure/azure-powershell/issues/3414
        $role = Get-AzureRmRoleAssignment -ServicePrincipalName $appId -RoleDefinitionName $spnRole | where {$_.Scope -eq [String]::Format("/subscriptions/{0}/resourceGroups/{1}", $id, $resourceGroupName)}

        if (![String]::IsNullOrEmpty($role) -eq $true)
        {
            Write-Output "The AAD Appication Principal already has the role $spnRole assigned to ResourceGroup $resourceGroupName, skipping role assignment..."
        }
        else
        {
            # Assign role to SPN to the provided ResourceGroup
            Write-Output "Assigning role $spnRole to SPN App $appId and ResourceGroup $resourceGroupName" -Verbose
            New-AzureRmRoleAssignment -RoleDefinitionName $spnRole -ServicePrincipalName $appId -ResourceGroupName $resourceGroupName
            Write-Output "SPN role assignment completed successfully" -Verbose
        }

        if ($adGroupNames)
        {
            foreach ($adGroupName in $adGroupNames)
            {  
                $adGroup = Get-AzureRmADGroup -SearchString $adGroupName
                if ([String]::IsNullOrEmpty($adGroup) -eq $true)
                {
                    Write-Output "The AAD Group $adGroupName Cannot be found. Due to this, skipping the role assignment"
                }
                else
                {
                    $adGroupAssignment = Get-AzureRmRoleAssignment -ObjectId $adGroup.Id -ResourceGroupName $resourceGroupName | where {$_.Scope -eq [String]::Format("/subscriptions/{0}/resourceGroups/{1}", $id, $resourceGroupName)}
                    $adGroupAssignment
                    if (![String]::IsNullOrEmpty($adGroupAssignment) -eq $true)
                    {
                        Write-Output "The AAD Group $adGroupName is already assigned to ResourceGroup $resourceGroupName, skipping role assignment..."
                    }
                    else
                    {
                        # Assign role to ad group to the provided ResourceGroup
                        Write-Output "Assigning role $adGroupName the RoleDefinition $spnRole on ResourceGroup $resourceGroupName" -Verbose
                        New-AzureRmRoleAssignment -ObjectId $adGroup.Id -ResourceGroupName $resourceGroupName -RoleDefinitionName $spnRole
                        Write-Output "Ad Group assignment completed successfully" -Verbose
                    }
                }
            }
        }
    }
}

if ($grantRoleOnSubscriptionLevel)
{
    # Assign role to SPN to the whole subscription
    Write-Output "Assigning role $spnRole to SPN App $appId for subscription $subscriptionName" -Verbose
    New-AzureRmRoleAssignment -RoleDefinitionName $spnRole -ServicePrincipalName $appId 
    Write-Output "SPN role assignment completed successfully" -Verbose
}


$resAccess1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess"
# Microsoft Graph application permissions: User.Invite.All
$resAccess1.Id = "09850681-111b-4a89-9bed-3f2cae46d706"
$resAccess1.Type = "Role"

$requiredResourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
# Microsoft Graph (API) App
$requiredResourceAccess.ResourceAppId = "00000003-0000-0000-c000-000000000000"
$requiredResourceAccess.ResourceAccess = $resAccess1

# The ObjectId belongs to the Azure AD application for the service principal
Set-AzureADApplication -ObjectId $app.ObjectId -RequiredResourceAccess $requiredResourceAccess


# Print the values
Write-Output "`nCopy and Paste below values for Service Connection" -Verbose
Write-Output "***************************************************************************"
Write-Output "Subscription Id: $id"
Write-Output "Subscription Name: $subscriptionName"
Write-Output "Service Principal Client (Application) Id: $appId"
Write-Output "Service Principal key: <Password that you typed in>"
Write-Output "Tenant Id: $tenantId"
Write-Output "Service Principal Display Name: $displayName"
Write-Output "Service Principal Names:"
foreach ($spnname in $spn.ServicePrincipalNames)
{
    Write-Output "   *  $spnname"
}
Write-Output "***************************************************************************"
