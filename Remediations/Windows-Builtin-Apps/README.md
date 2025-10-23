# Windows-Builtin-Apps
Remediation to remove Windows BuiltIn apps.

Add apps to be removed to the list `$appxPackageList` on line `16`
```
$appxPackageList = @(
        "MicrosoftCorporationII.QuickAssist"
    )
```