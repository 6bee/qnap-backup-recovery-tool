# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

<# 
 .Synopsis
  Get a substring at the begining of the input string

 .Description
  Returns the first n characters of the input string
  
 .Parameter InputString
  Input string

 .Example
  Get-StringStart "FooBar" 3

  Returns "Foo"
#>
Function Get-StringStart {
    [CmdletBinding()] Param (
      [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
      [string]$InputString,
      [Parameter(Mandatory=$true)]
      [int]$Length
    )
    If($Length -gt $InputString.Length) {
      $Length = $InputString.Length
    }
    $NewString = $InputString.Substring(0, $Length)
    $PSCmdlet.WriteObject($NewString)
  }



  <# 
 .Synopsis
  Get a substring at the end of the input string

 .Description
  Returns the last n characters of the input string
  
 .Parameter InputString
  Input string

 .Example
  Get-StringEnd "FooBar" 3

  Returns "Bar"
#>
Function Get-StringEnd {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$InputString,
    [Parameter(Mandatory=$true)]
    [int]$Length
  )
  If($Length -gt $InputString.Length) {
    $Length = $InputString.Length
  }
  $NewString = $InputString.Substring($InputString.Length - $Length, $Length)
  $PSCmdlet.WriteObject($NewString)
}
