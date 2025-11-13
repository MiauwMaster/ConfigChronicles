<#
.SYNOPSIS
    Get the current AutoPilot Group Tag for a device and set a new Group Tag if desired with pure REST methods.

.DESCRIPTION
    Get the current AutoPilot Group Tag for a device based on Serial number and device model information. 
    Fill the parameter 'DesiredGroupTag' to update the goup tag.
    This script uses pure REST methods so that the script can run in environments where the Microsoft Graph PowerShell module is not available.

.EXAMPLE
    Get-Set-AutoPilotGroupTagREST.ps1 -SerialNumber "ABC4567890" -Model "Surface Pro 7"

.EXAMPLE
    Get-Set-AutoPilotGroupTagREST.ps1 -SerialNumber "ABC4567890" -Model "Surface Pro 7" -DesiredGroupTag "Sales"

.NOTES
    Author: Tobias Putman-Barth
    Created: 2025-11
    Website: https://www.ConfigChronicles.com

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$SerialNumber,

    [Parameter(Mandatory = $true)]
    [string]$HardwareModel,

    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$ClientSecret,

    [Parameter(Mandatory = $false)]
    [string]$DesiredGroupTag
)

#Variables
$serialNumber       =   $SerialNumber
$hardwareModel      =   $HardwareModel
$clientId           =   $ClientId
$tenantId           =   $TenantId
$clientSecret       =   $ClientSecret
$desiredGroupTag    =   $DesiredGroupTag

$graphURI           =   "graph.microsoft.com"
$graphVersion       =   "v1.0"
$accessToken        =   $null
$changeConfirmed    =   $false
$finalGroupTag      =   [string]::Empty

#Global settings
$ErrorActionPreference = "Stop"

#Connect to Microsoft Graph

#Create the body of the Authentication of the request for the OAuth Token
$body = @{client_id=$clientId;client_secret=$clientSecret;grant_type="client_credentials";scope="https://$graphURI/.default";}
#Get the OAuth Token 
$oAuthReq = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -body $body
#Set your access token as a variable
$accessToken = $oAuthReq.access_token

#Get AutoPilot Device Information
try {
    $autoPilotDevice = (Invoke-RestMethod -Method GET -Uri "https://$($graphURI)/$($graphVersion)/deviceManagement/windowsAutopilotDeviceIdentities" -Headers @{Authorization = "Bearer $($accessToken)"}).Value | Where-Object { $_.SerialNumber -eq $serialNumber -and $_.model -eq $hardwareModel }

    Write-Host "Found '$($autoPilotDevice.Model)' device with serial: $($autoPilotDevice.SerialNumber)"  -ForegroundColor Green
    $finalGroupTag = $autoPilotDevice.GroupTag
}
catch {
    Write-Host "Failed to retrieve AutoPilot device information. Please ensure the provided Serial Number and Model are correct and the device is registered in AutoPilot." -ForegroundColor Red
    exit 1
}

if($DesiredGroupTag){
    #Get current Group Tag to compare
    $currentGrouptag = $autoPilotDevice.GroupTag

    if($currentGrouptag -ne $desiredGroupTag){
        try {
            #prepare body to send to the API
            $body = @{
                "groupTag" = $desiredGroupTag
            } | ConvertTo-Json

            Invoke-RestMethod -Method POST -Uri "https://$graphURI/$graphVersion/deviceManagement/windowsAutopilotDeviceIdentities/$($autopilotDevice.id)/updateDeviceProperties" -Headers @{Authorization = "Bearer $accessToken"; 'Content-Type' = 'application/json'} -body $body
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
        $updatedAutoPilotDevice = Invoke-RestMethod -Method GET -Uri "https://$graphURI/$graphVersion/deviceManagement/windowsAutopilotDeviceIdentities/$($autopilotDevice.id)" -Headers @{Authorization = "Bearer $accessToken"}
        if ($updatedAutoPilotDevice.GroupTag -eq $desiredGroupTag){
            Write-Host "Group Tag changed from '$($currentGrouptag)' to '$($updatedAutoPilotDevice.GroupTag)'" -ForegroundColor Green
            $finalGroupTag = $updatedAutoPilotDevice.GroupTag

            $changeConfirmed = $true
            break
        }
        Write-Host "Group Tag update not yet processed... Waiting..." -foregroundColor Yellow
        Start-Sleep -Seconds 60
    }
}

Write-Host "Final Group Tag is '$($finalGroupTag)'" -ForegroundColor Green
Return $finalGroupTag