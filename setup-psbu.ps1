<#
    Setup windows scheduled taks to do backup
#>

if ( $PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "Must be running PS7 or higher";
    return 1;
}

$taskName = "psbu-script";
$taskDescription = 'PS-BU Backup';

$config = Join-Path -Path $PSScriptRoot -ChildPath psbu-config.json
$jsonData = Get-Content -Path $config -Raw | ConvertFrom-Json

$schedule_text = $jsonData.schedule; 
$schedule = [timespan]::Parse($schedule_text);

$ps7 = "C:\Program Files\PowerShell\7\pwsh.exe"
$script2run = Join-Path -Path $PSScriptRoot -ChildPath "invoke-psbu.ps1"

# 1. Define the action to run powershell.exe with arguments for the script path
$action = New-ScheduledTaskAction `
    -Execute $ps7 `
    -Argument "" `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File $script2run

# 2. Define the daily trigger to run at 
$trigger = New-ScheduledTaskTrigger RepetitionDuration $schedule

# 3. Define the principal (user context)
$principal = New-ScheduledTaskPrincipal `
    -UserID "NT AUTHORITY\SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

# 4. (Optional) Define task settings
$settings = New-ScheduledTaskSettingsSet -WakeToRun

# 5. Register the scheduled task
Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description $taskDescription;

# 6. List scheduled tasks
Get-ScheduledTask | Where-Object { $_.Taskname -match $taskName }

#7 Tell how to run manually
Write-Output "To run immediately:"
Write-Output "   Start-ScheduledTask -TaskName $taskName"

return 0;