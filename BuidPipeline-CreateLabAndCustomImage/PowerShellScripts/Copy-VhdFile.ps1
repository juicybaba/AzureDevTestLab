<#
.SYNOPSIS
    Copy VHD files to DevTest Lab
.DESCRIPTION
    Copy VHD files to the DevTest Lab created in previous build pipeline task.
    The copied VHD files will be used to create custom images.
.INPUTS
    - srcResourceGroupName: the name of resource group where the rouce VHD file exists
    - srcStorageAccountName: the name of storage account where the source VHD file exists
    - vhdContainerName: the name of blob container where the VHD file exists
    - destResourceGroupName: the name of resource group where VHD file should be copied to
.OUTPUTS
    - vhdFileUris: array, the URI of the copied VHD file
.NOTES
    The destination storage account should be the only storage account in the 
    DevTest Lab resource group. The script will stop running if there is more 
    than one storage account.

    Created by: Ding Liu
#>

Param(
    # Resource group name of the source storage account
    [Parameter(Mandatory=$true)]
    [string]$srcResourceGroupName,

    # Source storage account name
    [Parameter(Mandatory=$true)]
    [string]$srcStorageAccountName,

    # Name of blob container
    [Parameter(Mandatory=$true)]
    [string]$vhdContainerName,

    # Resource group name of the destination storage account
    [Parameter(Mandatory=$true)]
    [string]$destResourceGroupName
)


# Get storage accounts
$srcStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $srcResourceGroupName -Name $srcStorageAccountName
$destStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $destResourceGroupName


# There should be one storage account in destination resource group
if ( ($destStorageAccount).Length -gt 1 ) {
    throw "Error: can't determine destination location. There are more than one storage account in the resource group."
}


# Create VHD file container only if it doesn't already exist
$existingContainers = Get-AzureStorageContainer -Context $destStorageAccount.Context
if ( !($vhdContainerName -in $existingContainers.Name) ) {
    New-AzureStorageContainer -Name $vhdContainerName -Context $destStorageAccount.Context
}


$vhdFileBlobs = Get-AzureStorageBlob -Container $vhdContainerName -Context $srcStorageAccount.Context

# TODO: try to change it to parallel processing using PowerShell jobs
foreach ($vhdFileBlob in $vhdFileBlobs) {
    # Copy VHD file only when it doesn't already exist
    $existingVhdFileBlobs = Get-AzureStorageBlob -Container 'vhd-file' -Context $destStorageAccount.Context
    if ( !($vhdFileBlob.Name -in $existingVhdFileBlobs.Name) ) {
        # Splatting arguments for Start-AzureStorageBlobCopy cmdlet
            $arguments = @{
                SrcBlob = $vhdFileBlob.Name;
                SrcContainer = $vhdContainerName;
                Context = $srcStorageAccount.Context;
                DestBlob = $vhdFileBlob.Name;
                DestContainer = $vhdContainerName;
                DestContext = $destStorageAccount.Context;
            }
        Start-AzureStorageBlobCopy @arguments

        # Get the status of the current blob copy activity
        do {
            # Splatting arguments for Get-AzureStorageBlobCopyState cmdlet
                $arguments = @{
                    Blob = $vhdFileBlob.Name;
                    Container = $vhdContainerName;
                    Context = $destStorageAccount.Context;
                }
            $status = Get-AzureStorageBlobCopyState @arguments
        
            $percentage = [int32](($status.BytesCopied / $status.TotalBytes)*100)
            $statusMsg = "Copying VHD file: " + $percentage + "% (" + $status.Status + ")"
            Write-Host $statusMsg
        
            Start-Sleep -Seconds 10
        } while ($status.Status -eq "Pending")
    }
}


# Get and output the URIs of copied VHD files, which are required by next task
    $arguments = @{
        Container = $vhdContainerName
        Context = $destStorageAccount.Context
    }
$vhdFileUris = (Get-AzureStorageBlob @arguments).ICloudBlob.Uri.AbsoluteUri
$vhdFileUris = ConvertTo-Json $vhdFileUris -Compress

$customImageNames = (Get-AzureStorageBlob @arguments).Name.Replace('.vhd', '').Replace('Module', 'VM-Image-Module')
$customImageNames = ConvertTo-Json $customImageNames -Compress

Write-Host "##vso[task.setvariable variable=vhdFileUris]$vhdFileUris"
Write-Host "##vso[task.setvariable variable=customImageNames]$customImageNames"
