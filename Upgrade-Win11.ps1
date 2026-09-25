param(
    [string]$MediaPath
)

$SetupExe = Join-Path $MediaPath "setup.exe"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

# Log File Info
$logName = "Upgrade-Win11"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Write-LogEntry {
  param (
    [parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Value,
    [parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$FileName = "$logName.log",
    [switch]$Stamp
  )

  # Create log file and append the Date/Time
  $LogFile = Join-Path -Path $env:SystemRoot -ChildPath $("Temp\$FileName")
  $tzBias = (Get-CimInstance Win32_TimeZone).Bias
  $Time   = "$(Get-Date -Format 'HH:mm:ss.fff') $tzBias"
  $Date   =  (Get-Date -Format 'MM-dd-yyyy')

  Write-Host -ForegroundColor Yellow $Value

  If ($Stamp) {
    $LogText = "<$($Value)> <time=""$($Time)"" date=""$($Date)"">"
  }
  else {
    $LogText = "$($Value)"   
  }

  Try {
    Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFile -ErrorAction Stop
  }
  Catch [System.Exception] {
    Write-Warning -Message "Unable to add log entry to $LogFile.log file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
  }
}


#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-LogEntry -Value "##################################"
Write-LogEntry -Stamp -Value "Starting script!"
Write-LogEntry -Value "##################################"
Write-LogEntry -Value "Script started at $(Get-Date -Format 'HH:mm:ss') on $(Get-Date -Format 'MM-dd-yyyy')"
Write-LogEntry -Value "Hostname: $($env:COMPUTERNAME)"
$procArch = $env:PROCESSOR_ARCHITECTURE
Write-LogEntry -Value "Processor Architecture: $procArch"
$scriptStartTime = Get-Date

if (!(Test-Path $SetupExe)) {
    Write-LogEntry -Value "ERROR: setup.exe not found at $SetupExe"
    exit 1
}

# Get current windows version, build and edition
$winVersion = [version](Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").LCUVer
$winEdition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
Write-LogEntry -Value "Current Windows Edition: $winEdition"
Write-LogEntry -Value "Current Windows Version: $winVersion"

# If LCUVer is already 26200, exit the script
if ($winVersion -ge [version]"10.0.26200.0") {
  Write-LogEntry -Value "Device already running Windows 11 25H2. Exiting. (Version detected: $winVersion)"
  exit 0
}

$SetupExe = Join-Path $PSScriptRoot "setup.exe"
if (!(Test-Path $SetupExe)) {
  Write-LogEntry -Value "ERROR: setup.exe not found at $SetupExe"
  exit 1
}

Start-Process `
    -FilePath $SetupExe `
    -ArgumentList @(
        "/auto","upgrade",
        "/quiet",
        "/noreboot",
        "/eula","accept",
        "/dynamicupdate","disable",
        "/copylogs","C:\Windows\Temp\25H2Logs"
    ) `
-PassThru

Write-LogEntry -Value "Setup launched successfully. PID: $($Process.Id)"

$scriptEndTime = Get-Date
$scriptDuration = $scriptEndTime - $scriptStartTime
Write-LogEntry -Value "Script completed at $($scriptEndTime.ToString('HH:mm:ss')) on $($scriptEndTime.ToString('MM-dd-yyyy'))"
Write-LogEntry -Value ("Execution Duration: {0} minutes, {1} seconds" -f $scriptDuration.Minutes, $scriptDuration.Seconds)
Write-LogEntry -Value "##################################"
Write-LogEntry -Value "Windows Setup started successfully."
Write-LogEntry -Value "Further progress will be available in Panther logs."
Write-LogEntry -Value "##################################"
