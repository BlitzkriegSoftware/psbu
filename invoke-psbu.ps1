<#
    PS-BU

    .DESCRIPTION
        Do a backup using provided configuration file to a drive
#>

function Get-RandomString {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Int32]
        $Count = 9
    )

    $gs = -join ($okChars | Get-Random -Count $Count | ForEach-Object { $_ })

    return $gs
}

$okChars = @(
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "m", "n", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    "A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
);

if ( $PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "Must be running PS7 or higher";
    return 1;
}

$config = Join-Path -Path $PSScriptRoot -ChildPath psbu-config.json
$jsonData = Get-Content -Path $config -Raw | ConvertFrom-Json

$backup_to = $jsonData.backup_to;

if (-not (Test-Path -Path $backup_to -PathType Container)) {
    New-Item -Path $backup_to -ItemType Directory | Out-Null
}

$backup_from = $jsonData.backup_from;
if (-not $backup_from -is [array]) {
    Write-Error "$backup_from needs to be an array of folders"
    return 2;
}

if ( $backup_from.Count -le 0) {
    Write-Error "$backup_from array can't be empty"
    return 3;   
}

$dts = Get-Date -Format "yyyyMMdd_HHmmss";
$bu_target_root = Join-Path -Path $backup_to -ChildPath $dts
New-Item -Path $bu_target_root -ItemType Directory -Force | Out-Null

foreach ($bu_from_folder in $backup_from) {
    if (-not (Test-Path -Path $bu_from_folder -PathType Container)) {
        Write-Warning "$bu_from_folder does not exist, skipping";
        continue;
    }

    $folderItem = Get-Item -Path $bu_from_folder
    $folderName = $folderItem.Name
    $ncs = Get-RandomString -Count 9
    $buFile = "${folderName}_${ncs}.zip"
    $bu_target_filename = Join-Path -Path $bu_target_root -ChildPath $buFile 

    # Backup
    Write-Output "Backing up ${bu_from_folder} to ${bu_target_filename}"
    Compress-Archive -Path "${bu_from_folder}\*" -DestinationPath $bu_target_filename
}

return 0;