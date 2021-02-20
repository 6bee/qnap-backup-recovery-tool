# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

<#
 .Synopsis
  Start random sleep

 .Description
  Puts the current session in sleep for an random number of milliseconds

 .Parameter Minimum
  Minimum

 .Parameter Maximum
  Maximum

 .Example
  Start-RandomSleep
#>
Function Start-RandomSleep{
  [CmdletBinding()] Param (
    [Parameter()]
    [int]$Minimum = 100,
    [Parameter()]
    [int]$Maximum = 5000
  )
  Start-Sleep -Milliseconds $(Get-Random -Minimum $Minimum -Maximum $Maximum)
}