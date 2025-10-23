<#
.SYNOPSIS
    Checks free space on the EFI System Partition and exits with status code.

.DESCRIPTION
    This script mounts the EFI System Partition, checks its free space, and exits with code 1 if less than 50 MB is available, otherwise exits with code 0.

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
    Remove-PSDrive -Name "efi"

    #remediation needed
    exit 1
} else {
    Write-Host "Sufficient free space on the EFI System Partition: $freespace MB" -ForegroundColor Green
    Remove-PSDrive -Name "efi"
    #no remediation needed
    exit 0
}