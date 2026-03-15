<#
    Show Task History
#>
# Source - https://superuser.com/a/1749186
# Posted by DawgFather
# Retrieved 2026-03-15, License - CC BY-SA 4.0
# Modified 2026-03-15 - Stuart Williams

$Date = Get-Date;
$taskName = "psbu-script";

$error_file = Join-Path -Path $PSScriptRoot -ChildPath "psbu_Error.log";
$log_file = Join-Path -Path $PSScriptRoot -ChildPath "psbu_${taskName}.log";
$trans_file = Join-Path -Path $PSScriptRoot -ChildPath "psbu_Show-History.log";

Start-Transcript -Path $trans_file

If (-Not (Test-Path $log_file -PathType Leaf)) {
    New-Item $log_file 2>&1 $null;
}

#Filter xml to pull task scheduler events

#Task scheduler common event IDs to ignore (treat as good/success)
$notin = 100, 102, 107, 110, 129, 140, 200, 201;

# Get XML for query
$xml_file = Join-Path -Path $PSScriptRoot -ChildPath "Show-History.xml";
if (-not (Test-Path -Path $xml_file)) {
    Write-Error "Can't find XML file: ${xml_file}";
    return 3;
}

$token = '###TASKNAME###';
$xml = Get-Content -Path $xml_file -Raw
$shxml = $xml.Replace($token, $taskName);

try {

    #Command to execute locally
    $events = Invoke-Command  -ScriptBlock {

        #Pulls task scheduler, only events with the job (task's) name for events in the last 24 hours
        $events = @(
            Get-WinEvent  -FilterXml $shxml -ErrorAction Stop
        );
        Return $events;

    } -ArgumentList $taskName;
}

catch {
    # If events exist from last 24 hours for this task, append the text (log) file with those events
    Write-Warning -Message "Failed to query $($env:computername) because $($_.Exception.Message)" *> $error_file 
}

if ($events) {
    Add-Content $log_file "As of $Date :" #-Encoding UTF8
    $events | Select-Object MachineName, TimeCreated, Id, TaskDisplayName | Out-File -Append $log_file #-Encoding UTF8
}
else {
    Add-Content $log_file "No files found for last 24 hours as of $Date `r" -Encoding UTF8
}

Stop-Transcript
return 0;