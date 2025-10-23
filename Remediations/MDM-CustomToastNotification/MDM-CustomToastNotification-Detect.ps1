<#
.SYNOPSIS
    This script is used to notify users with a custom toast notification.

.DESCRIPTION
    Script to notify users.
    Displays a windows toast notification to the user.

.NOTES
    File Name      : MDM-CustomToastNotification-Detect.ps1
    Author         : Tobias Putman-Barth
    
.LINK
	https://github.com/MiauwMaster/ConfigChronicles
#>


begin{
    # Image header format base 64
    $Picture_Base64 = 'YOUR_BASE64_ENCODED_IMAGE_STRING_HERE'

    # Header image export path
    $HeroImage = "$env:TEMP\logo.png"
    [byte[]]$Bytes = [convert]::FromBase64String($Picture_Base64)
    [System.IO.File]::WriteAllBytes($HeroImage,$Bytes)	

    Function Register-NotificationApp($AppID,$AppDisplayName) {
        [int]$ShowInSettings = 0

        [int]$IconBackgroundColor = 0
        $IconUri = "C:\Windows\ImmersiveControlPanel\images\logo.png"
        
        $AppRegPath = "HKCU:\Software\Classes\AppUserModelId"
        $RegPath = "$AppRegPath\$AppID"
        
        $Notifications_Reg = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings'
        If(!(Test-Path -Path "$Notifications_Reg\$AppID")) 
            {
                New-Item -Path "$Notifications_Reg\$AppID" -Force
                New-ItemProperty -Path "$Notifications_Reg\$AppID" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force
            }

        If((Get-ItemProperty -Path "$Notifications_Reg\$AppID" -Name 'ShowInActionCenter' -ErrorAction SilentlyContinue).ShowInActionCenter -ne '1') 
            {
                New-ItemProperty -Path "$Notifications_Reg\$AppID" -Name 'ShowInActionCenter' -Value 1 -PropertyType 'DWORD' -Force
            }	
            
        try {
            if (-NOT(Test-Path $RegPath)) {
                New-Item -Path $AppRegPath -Name $AppID -Force | Out-Null
            }
            $DisplayName = Get-ItemProperty -Path $RegPath -Name DisplayName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DisplayName -ErrorAction SilentlyContinue
            if ($DisplayName -ne $AppDisplayName) {
                New-ItemProperty -Path $RegPath -Name DisplayName -Value $AppDisplayName -PropertyType String -Force | Out-Null
            }
            $ShowInSettingsValue = Get-ItemProperty -Path $RegPath -Name ShowInSettings -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ShowInSettings -ErrorAction SilentlyContinue
            if ($ShowInSettingsValue -ne $ShowInSettings) {
                New-ItemProperty -Path $RegPath -Name ShowInSettings -Value $ShowInSettings -PropertyType DWORD -Force | Out-Null
            }
            
            New-ItemProperty -Path $RegPath -Name IconUri -Value $IconUri -PropertyType ExpandString -Force | Out-Null	
            New-ItemProperty -Path $RegPath -Name IconBackgroundColor -Value $IconBackgroundColor -PropertyType ExpandString -Force | Out-Null		
            
        }
        catch {}
    }

    $Title = "YOUR_TITLE_HERE"
    $Advice = "NOTIFICATION_MESSAGE_HERE"
    $Text_AppName = "APP_HEADER_HERE"

    $showToast = $false
    $toastExpirationTime = 30 #minutes
}

process{
    Set-StrictMode -Version 3.0

    #Determine if we need to show the toast
    $checkToShowToast = $true
    if ($checkToShowToast) {
        $showToast = $true
    }

    $Scenario = 'reminder' 

    [xml]$splat = @"
<toast scenario="$Scenario">
    <visual>
    <binding template="ToastGeneric">
        <image placement="hero" src="$HeroImage"/>
        <text>$Title</text>
        <group>
            <subgroup>     
                <text hint-style="body" hint-wrap="true" >$Advice</text>
            </subgroup>
        </group>		
    </binding>
    </visual>
<actions>
        <action activationType="protocol" arguments="Dismiss" content="Dismiss" />
</actions>
</toast>
"@

    $AppID = $Text_AppName
    $AppDisplayName = $Text_AppName
    Register-NotificationApp -AppID $Text_AppName -AppDisplayName $Text_AppName

    # Toast creation and display
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
    $ToastXml = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
    $ToastXml.LoadXml($splat.OuterXml)

    $toast = [Windows.UI.Notifications.ToastNotification]::new($ToastXml)
    $toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes($toastExpirationTime)
}

end{
    if($showToast){
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AppID).Show($toast)
        exit 1
    }
}