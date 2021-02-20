# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

<#
 .Synopsis
  Log

 .Description

 .Parameter InputObject
  Input object

 .Parameter Level
  Log level

 .Parameter Logger
  Logger name

 .Example
  Out-Log $logmessage -Level Info
#>
Function Out-Log {
   [CmdletBinding()] Param (
    [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
    [object]$InputObject,
    [Parameter(Mandatory=$false)]
    [string]$Level = "Debug",
    [Parameter(Mandatory=$false)]
    [string]$Logger = $null
  )
  $logfile = $env:LogFile
  If ($logfile) {
    try {
      $folder = Split-Path $logfile -Parent
      If (-Not $(Test-Path -LiteralPath $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
      }
      If (-Not $Logger) {
        $Logger = $env:Logger
      }
      Out-File -FilePath $logfile -Append -InputObject "$(Get-Date) [$Level] [$Logger] $InputObject"
    } Catch {
      Write-Warning "Failed appending logfile '$logfile': $($_.Exception.Message)"
    }
  }
  $PSCmdlet.WriteObject($InputObject)
}