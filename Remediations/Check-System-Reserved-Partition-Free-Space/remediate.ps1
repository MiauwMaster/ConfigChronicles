<#
.SYNOPSIS
    Checks free space on the EFI System Partition and cleans font files.

.DESCRIPTION
    This script mounts the EFI System Partition, checks its free space, and clean font files if less than 50 MB is available.

.NOTES
    Author:  Tobias Putman-Barth
    Date: 2025-09
#>

$freespaceNeeded = 50

#find the EFI System Partition
$SystemPartition = Get-Partition | Where-Object {$_.IsSystem -eq $true} 
#Mount the EFI partition to a temporary PSDrive
New-PSDrive -Name "efi" -PSProvider "FileSystem" -Root ($SystemPartition.AccessPaths)[0]
#Get the drive info
$drive = Get-CimInstance -Class Win32_Volume | Where-Object {$_.Name -eq $((Get-psdrive efi).root)}
#Get the free space in MB
$freespace = [math]::round($drive.FreeSpace / 1MB, 2)

if ($freespace -lt $freespaceNeeded) {
    Write-Host "Not enough free space on the EFI System Partition. At least $freespaceNeeded MB is required." -ForegroundColor Red

    # Remove Font Files
    $fontPath = "efi:\EFI\Microsoft\Boot\Fonts\"
    $fontFiles = Get-ChildItem -Path $fontPath -Include *.ttf -Recurse
    foreach ($file in $fontFiles) {
        try {
            Remove-Item -Path $file.FullName -Force
            Write-Host "Removed font file: $($file.FullName)" -ForegroundColor Yellow
        } catch {
            Write-Host "Failed to remove font file: $($file.FullName). Error: $_" -ForegroundColor Red
        }
    }
   
} else {
    Remove-PSDrive -Name "efi"
    Write-Host "Sufficient free space on the EFI System Partition: $freespace MB" -ForegroundColor Green
    #no remediation needed
    exit 0
}

# Recheck free space after remediation

#Get the drive info
$drive = Get-CimInstance -Class Win32_Volume | Where-Object {$_.Name -eq $((Get-psdrive efi).root)}
#Get the free space in MB
$freespace = [math]::round($drive.FreeSpace / 1MB, 2)
if ($freespace -lt 50) {
    Remove-PSDrive -Name "efi"
    Write-Host "Not enough free space on the EFI System Partition after cleaning font files. At least $freespaceNeeded MB is required." -ForegroundColor Red
    exit 1
}

Remove-PSDrive -Name "efi"
Write-host "Enough free space to update "
exit 0