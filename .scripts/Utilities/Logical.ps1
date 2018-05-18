# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

<# 
 .Synopsis
  Coalesce

 .Description
  Returns the value if it's not null, else returns the defaul value
  
 .Parameter Value
  The value the be returned if not null

 .Parameter Defaul
  The value the be returned if value parameter is null

 .Example
  Get-Coalesce $Foo $Bar
#>
Function Get-Coalesce {
    [CmdletBinding()] Param (
      [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
      [object]$Value,
      [Parameter(Mandatory=$true)]
      [object]$Default
    )
    $Result = If($Value) { $Value } Else { $Default }
    $PSCmdlet.WriteObject($Result)
  }
  
  #New-Alias "??" Coalesce
  
  
  <# 
   .Synopsis
    IfTrue
  
   .Description
    Returns one or the other value based on whether the condition evaluates to true 
    
   .Parameter Test
    The condition to be evaluated
    
   .Parameter IfTrue
    The value to be returned if the condition evaluates to true
  
   .Parameter IfFalse
    The value to be returned if the condition evaluates to false
  
   .Example
    Get-IfTrue $Test $Foo $Bar
  #>
  Function Get-IfTrue {
    [CmdletBinding()] Param (
      [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
      [bool]$Test,
      [Parameter(Mandatory=$true)]
      [object]$IfTrue,
      [Parameter(Mandatory=$true)]
      [object]$IfFalse
    )
    $Result = If($Test) { $IfTrue } Else { $IfFalse }
    $PSCmdlet.WriteObject($Result)
  }
  
  #New-Alias "?:" IfTrue
  