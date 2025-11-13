<#
.SYNOPSIS
    Get the current AutoPilot Group Tag for a device and set a new Group Tag if desired.

.DESCRIPTION
    Get the current AutoPilot Group Tag for a device based on Serial number and device model information. 
    Fill the parameter 'desiredGroupTag' to update the goup tag.

.EXAMPLE
    Get-Set-AutoPilotGroupTag.ps1 -SerialNumber "ABC4567890" -Model "Surface Pro 7"

.EXAMPLE
    Get-Set-AutoPilotGroupTag.ps1 -SerialNumber "ABC4567890" -Model "Surface Pro 7" -DesiredGroupTag "Sales"

.NOTES
    Author: Tobias Putman-Barth
    Created: 2025-11
    Website: https://www.ConfigChronicles.com

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$serialNumber,

    [Parameter(Mandatory = $true)]
    [string]$hardwareModel,

    [Parameter(Mandatory = $true)]
    [string]$clientId,

    [Parameter(Mandatory = $true)]
    [string]$tenantId,

    [Parameter(Mandatory = $true)]
    [string]$clientSecret,

    [Parameter(Mandatory = $false)]
    [string]$desiredGroupTag
)

#Variables
$Credential = [PSCredential]::new($clientId, (ConvertTo-SecureString($clientSecret) -AsPlainText -Force))
$changeConfirmed = $false
$finalGroupTag = ""

#Global settings
$ErrorActionPreference = "Stop"

#Import required modules
try {
    Import-Module Microsoft.Graph.DeviceManagement.Enrollment
}
catch {
    Write-Host "Failed to import Microsoft Graph Device Management Enrollment module. Please ensure the Microsoft.Graph module is installed." -ForegroundColor Red
    exit 1
}


#Connect to Microsoft Graph
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $Credential -NoWelcome


#Get AutoPilot Device Information
try {
    $AutoPilotDevice = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity | Where-Object { $_.SerialNumber -eq $serialNumber -and $_.Model -eq $hardwareModel }
    Write-Host "Found '$($AutoPilotDevice.Model)' device with serial: $($AutoPilotDevice.SerialNumber)"  -ForegroundColor Green
    $finalGroupTag = $AutoPilotDevice.GroupTag
}
catch {
    Write-Host "Failed to retrieve AutoPilot device information. Please ensure the provided Serial Number and Model are correct and the device is registered in AutoPilot." -ForegroundColor Red
    exit 1
}

if($desiredGroupTag){
    #Get current Group Tag to compare
    $currentGrouptag = $AutoPilotDevice.GroupTag

    if($currentGrouptag -ne $desiredGroupTag){
        try {
            Set-MgDeviceManagementWindowsAutopilotDeviceIdentityUserToDeviceIdentity -WindowsAutopilotDeviceIdentityId $AutoPilotDevice.Id -GroupTag $desiredGroupTag
        }
        catch {
            Write-Host "Could not set the new group tag." -ForegroundColor Red
            exit 1
        }
    } else{
        Write-Host "The device already has the desired Group Tag: '$desiredGroupTag'. No changes made." -ForegroundColor Yellow
    }

    while(!$changeConfirmed){
        #verify the new Group Tag has been set
        $updatedAutoPilotDevice = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $AutoPilotDevice.Id
        if ($updatedAutoPilotDevice.GroupTag -eq $desiredGroupTag){
            Write-Host "Group Tag changed from '$($currentGrouptag)' to '$($updatedAutoPilotDevice.GroupTag)'" -ForegroundColor Green
            $finalGroupTag = $AutoPilotDevice.GroupTag

            $changeConfirmed = $true
            break
        }
        Write-Host "Group Tag update not yet processed... Waiting..."
        Start-Sleep -Seconds 60
    }
}

Write-Host "Final Group Tag is '$($finalGroupTag)'" -ForegroundColor Green
Return $finalGroupTag