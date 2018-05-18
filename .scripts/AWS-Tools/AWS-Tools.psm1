# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

# set PSScriptRoot (if run from ISE)
If (-Not $PSScriptRoot) {
  $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

$AppScriptRoot = Split-Path $PSScriptRoot -Parent
If ($($env:PSModulePath -split ";" | Where-Object { (Join-Path $_ "") -eq $AppScriptRoot }).Count -eq 0) {
  $env:PSModulePath = "$($env:PSModulePath);$AppScriptRoot"
}

# configuration start ##########################################
$AppName = "qnap-backup-recovery-tool"
If ($env.WorkingDirectory) {
  $WorkingDirectory = $env.WorkingDirectory
} ElseIf ($env:Temp){
  $WorkingDirectory = $env:Temp
} Else {
  $WorkingDirectory = Join-Path $env:LOCALAPPDATA "temp"
}
If ($WorkingDirectory -notlike "*$AppName*") {
  $WorkingDirectory = Join-Path $WorkingDirectory $AppName
}
$NumberOfInventoryDownloadJobs = 2
$NumberOfArchiveDownloadJobs = 4
$env:MaxIdSize = 50
$env:pending = "pending"
$env:processing = "processing"
$env:success = "success"
$env:failure = "failure"
$env:data = "data"
$env:LogFile = Join-Path $WorkingDirectory "$AppName.log"
# configuration end ##########################################


. (Join-Path $PSScriptRoot "Common.ps1")
. (Join-Path $PSScriptRoot "Common-Glacier.ps1")
. (Join-Path $PSScriptRoot "Common-S3.ps1")
. (Join-Path $PSScriptRoot "GlacierRestore-Run-BackgroundTasks.ps1")
. (Join-Path $PSScriptRoot "GlacierRestore-Start-VaultRestore.ps1")
. (Join-Path $PSScriptRoot "GlacierCleanup.ps1")