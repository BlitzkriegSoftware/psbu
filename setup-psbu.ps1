<#
    Setup windows scheduled taks to do backup
#>

if ( $PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "Must be running PS7 or higher";
    return 1;
}

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator);

if (-not $isAdmin) {
    Write-Error "Must be running as administrator";
    return 2;  
}

# minutes of random delay
[int32]$randomDelay = 9;

$taskName = "psbu-script";
$taskPath = "\blitzkrieg\"
$taskDescription = 'PS-BU Backup';

$config = Join-Path -Path $PSScriptRoot -ChildPath psbu-config.json
$jsonData = Get-Content -Path $config -Raw | ConvertFrom-Json

$at = $jsonData.at;
$everyNdays = $jsonData.everyNdays;

$ps7 = "C:\Program Files\PowerShell\7\pwsh.exe"
$script2run = Join-Path -Path $PSScriptRoot -ChildPath "invoke-psbu.ps1"

# 1. Define the action to run powershell.exe with arguments for the script path
$action = New-ScheduledTaskAction `
    -WorkingDirectory $PSScriptRoot `
    -Execute $ps7 `
    -Argument " -ExecutionPolicy Bypass -File ${script2run}"

# 2. Define the daily trigger to run at 
$trigger = New-ScheduledTaskTrigger `
    -Daily `
    -DaysInterval $everyNdays `
    -At $at `
    -RandomDelay (New-TimeSpan -Minutes  $randomDelay)

# 3. Define the principal (user context)
$principal = New-ScheduledTaskPrincipal `
    -UserID "NT AUTHORITY\SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

# 4. (Optional) Define task settings
$settings = New-ScheduledTaskSettingsSet -WakeToRun

# 5. Delete if exist
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($null -ne $task) {
    # Unregister (delete) the task without confirmation
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Scheduled task '$taskName' has been deleted."
}

# 6. Register the scheduled task
Register-ScheduledTask `
    -TaskName $taskName `
    -TaskPath $taskPath `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description $taskDescription;

# 7. List scheduled tasks
Get-ScheduledTask | Where-Object { $_.Taskname -match $taskName }

# 8. Tell how to run manually
Write-Output "To run immediately:"
Write-Output "   Start-ScheduledTask -TaskName $taskName"

return 0;