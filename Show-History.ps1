<#
    Show Task History
#>

$Date = Get-Date;
$taskName = "psbu-script";

$error_file = Join-Path -Path $PSScriptRoot -ChildPath "psbu_Error.log";
$log_file = Join-Path -Path $PSScriptRoot -ChildPath "psbu_${taskName}.log";
$trans_file = Join-Path -Path $PSScriptRoot -ChildPath "psbu_Show-History.log";

If (-Not (Test-Path $log_file -PathType Leaf)) {
    New-Item $log_file 2>&1 $null;
}

Start-Transcript -Path $trans_file;

# Define the log path
$logPath = 'Microsoft-Windows-TaskScheduler/Operational';
# Calculate the date for one month ago
$oneMonthAgo = (Get-Date).AddMonths(-1);

try {
    $raw_events = @(
        Get-WinEvent `
            -FilterHashtable @{ 
            LogName   = $logPath;
            StartTime = $oneMonthAgo
        } `
            -ErrorAction Stop
    );
    $events = $raw_events | Where-Object { $_.TaskName -eq $taskName };
}
catch {
    $events = $null;
    $errmsg = $_.Exception.Message;
    Write-Warning -Message "Failed to query $($env:computername) because ${errmsg}" *> $error_file 
}

if ($events) {
    Add-Content $log_file "As of $Date :" 
    $events | Select-Object MachineName, TimeCreated, Id, TaskDisplayName | Out-File -Append $log_file 
}
else {
    Add-Content $log_file "No files found as of $Date `r" -Encoding UTF8
}

Stop-Transcript;
return 0;