<#
.SYNOPSIS
    This script is used to detect built-in apps in Windows.

.DESCRIPTION
    Script to detect installed windows built-in apps
    The list of built-in apps can be customized by modifying the $appxPackageList array in the script.

.NOTES
    File Name      : Detect-Windows-Built-In-Apps.ps1
    Author         : Tobias Putman-Barth
    
.LINK
	https://github.com/MiauwMaster/ConfigChronicles
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
}

process {
    $global:needsRemediation = @()
    $global:remediationSuccess = @()
    $installedAppxPackages = Test-InstalledAppxPackages

    if (-NOT[string]::IsNullOrEmpty($installedAppxPackages)) {
        foreach ($app in $installedAppxPackages) {
            $global:needsRemediation += $true
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