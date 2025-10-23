<#
.SYNOPSIS
    This script is used to remediate built-in apps in Windows.

.DESCRIPTION
    Script to remediate installed windows built-in apps
    The list of built-in apps can be customized by modifying the $appxPackageList array in the script.

.NOTES
    File Name      : Remediate-Windows-Built-In-Apps.ps1
    Author         : Tobias Putman-Barth
#>

begin {
    Set-StrictMode -Version 3
    $appxPackageList = @(
        "MicrosoftCorporationII.QuickAssist"
        "Microsoft.MicrosoftOfficeHub"
    )
    function Test-InstalledAppxPackages() {
        foreach ($app in $appxPackageList) {
            try {
                $isAppInstalled = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
                if (-NOT[string]::IsNullOrEmpty($isAppInstalled)) {
                    Write-Output $app
                }
            }
            catch {
                Write-Output "[ERROR] Failed to retrieve the installed app: $_"
            }
        }
    }
    function Remove-InstalledAppxPackages() {
        param (
            [string]$appxPackage
        )
        try {
            Get-AppxPackage -Name $appxPackage | Remove-AppxPackage
            $global:remediationSuccess += $true
        }
        catch {
            Write-Output "[ERROR] Failed to remove the app: $_"
        }
    }
}

process {
    $global:needsRemediation = @()
    $global:remediationSuccess = @()
    $installedAppxPackages = Test-InstalledAppxPackages

    if (-NOT[string]::IsNullOrEmpty($installedAppxPackages)) {
        foreach ($app in $installedAppxPackages) {
            $global:needsRemediation += $true
            Remove-InstalledAppxPackages -appxPackage $app
        }
    }
}

end {
    if ($global:needsRemediation -contains $true -AND $global:remediationSuccess -notcontains $true) {
        Write-Output "[WARNING] Built-in apps found installed. Remediation is needed."
        exit 1
    }
    elseif ($global:remediationSuccess -contains $true -AND $global:remediationSuccess -notcontains $false) {
        Write-Output "[OK] Remediation was run successfully. Built-in apps were removed."
        exit 0
    }
    else {
        Write-Output "[OK] No built-in apps found. Doing nothing."
        exit 0
    }
}