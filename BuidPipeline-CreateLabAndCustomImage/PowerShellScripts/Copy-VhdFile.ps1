<#
.SYNOPSIS
    Copy VHD file to DevTest Lab
.DESCRIPTION
    Copy a VHD file to the DevTest Lab created in previous build pipeline task.
    The copied VHD file will be used to create custom image.
.INPUTS
    - srcResourceGroupName: the name of resource group where the rouce VHD file exists
    - srcStorageAccountName: the name of storage account where the source VHD file exists
    - vhdContainerName: the name of blob container where the VHD file exists
    - vhdFileName: the name of the VHD file
    - destResourceGroupName: the name of resource group where VHD file should be copied to
.OUTPUTS
    - vhdFileUri: the URI of the copied VHD file
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

    # Name of VHD file
    [Parameter(Mandatory=$true)]
    [string]$vhdFileName,

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


# Create VHD file container only if it doesn't already exit
$existingContainers = Get-AzureStorageContainer -Context $destStorageAccount.Context
if ( !($vhdContainerName -in $existingContainers.Name) ) {
    New-AzureStorageContainer -Name $vhdContainerName -Context $destStorageAccount.Context
}


# Copy VHD file from srouce to destination
# Splatting arguments for Start-AzureStorageBlobCopy cmdlet
    $arguments = @{
        SrcBlob = $vhdFileName;
        SrcContainer = $vhdContainerName;
        Context = $srcStorageAccount.Context;
        DestBlob = $vhdFileName;
        DestContainer = $vhdContainerName;
        DestContext = $destStorageAccount.Context;
        Force = $true; # overwrites the destination blob without asking confirmation
    }
Start-AzureStorageBlobCopy @arguments

# Monitor and report the progress of copying
do {
    # Splatting arguments for Get-AzureStorageBlobCopyState cmdlet
    $arguments = @{
        Blob = $vhdFileName;
        Container = $vhdContainerName;
        Context = $destStorageAccount.Context;
    }
    $status = Get-AzureStorageBlobCopyState @arguments

    $percentage = [int32](($status.BytesCopied / $status.TotalBytes)*100)
    $statusMsg = "Copying VHD file: " + $percentage + "% (" + $status.Status + ")"
    Write-Host $statusMsg

    Start-Sleep -Seconds 10
} while ($status.Status -eq "Pending")

# Get and output the URI of copied VHD file, which is required by next task
$arguments = @{
    Blob = $vhdFileName
    Container = $vhdContainerName
    Context = $destStorageAccount.Context
}
$vhdFileUri = (Get-AzureStorageBlob @arguments).ICloudBlob.Uri.AbsoluteUri


Write-Host "##vso[task.setvariable variable=vhdFileUri]$vhdFileUri"
