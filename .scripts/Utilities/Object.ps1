# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

<#
 .Synopsis
  Create a copy

 .Description
  Creates a shallow copy of a PSObject

 .Parameter InputObject
  The object to copy

 .Example
  Get-ShallowCopy $obj
#>
Function Get-ShallowCopy {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]$InputObject,
    [Parameter()]
    [string[]]$ExcludeProperty = $Null
  )
  $NewObject = New-Object PSObject
  $InputObject.PSObject.Properties `
    | Where-Object { $_.Name -NotIn $ExcludeProperty } `
    | ForEach-Object {
        $NewObject | Add-Member -MemberType $_.MemberType -Name $_.Name -Value $_.Value
      }
  $PSCmdlet.WriteObject($NewObject)
}



<#
 .Synopsis
  Execute and forward

 .Description
  Executes a scriptblock. Input from pipe may be accessed using $_ variable.

 .Parameter InputObject
  The object

 .Parameter ScriptBlock
  Scriptblock to execute

 .Example
  'a','b','c' | Invoke-Script { Write-Host "Size: $($_.Count)" } | Foreach-Object { $_ }

  Size: 3
  a
  b
  c
#>
Function Invoke-Script {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromRemainingArguments=$false)]
    [object[]]$InputObject,
    [Parameter(Mandatory=$true,Position=0)]
    [ScriptBlock]$ScriptBlock
  )
  End {
    $_ = Get-Coalesce $input $InputObject
    $NewScriptBlock = [scriptblock]::Create($ScriptBlock)
    $NewScriptBlock.Invoke()
    $input
  }
}