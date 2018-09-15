# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

<# 
 .Synopsis
  Read file content into json object

 .Description
  Reads file and returns content as json object

 .Parameter Path
  File path

 .Example
  Read-JsonFile "sample.json"
#>
Function Read-JsonFile {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$Path
  )
  $json = -join $(Get-Content -LiteralPath $Path)
  $obj = ConvertFrom-Json $json
  $PSCmdlet.WriteObject($obj)
}



<# 
  .Synopsis
  Write object as json file

  .Description
  Saves an object into a json file

  .Parameter InputObject
  The PSObject to be serialized as json

  .Parameter Path
  File path

  .Example
  Write-JsonFile "sample.json"
#>
Function Write-JsonFile {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [object]$InputObject,
    [Parameter(Mandatory=$true)]
    [string]$Path
  )
  Split-Path -Parent $Path | New-DirectoryIfNotExists
  $InputObject `
    | ConvertTo-Json -Depth 99 `
    | Out-File -LiteralPath $Path
}



<# 
  .Synopsis
  Ensure existance of direcotry

  .Description
  Creates the specified directory in case it does not exists yet

  .Parameter Path
  List of direcotries

  .Example
  New-DirectoryIfNotExists "C:\Foo" "D:\Bar"
#>
Function New-DirectoryIfNotExists {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
    [AllowEmptyString()]
    [string[]]$Path
  )
  $Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
  $Path `
    | Where-Object { -Not ([string]::IsNullOrEmpty($_) -Or $(Test-Path -LiteralPath $_)) } `
    | ForEach-Object { New-Item -ItemType Directory -Path $_ -Verbose:$Verbose | Out-Null }
}



<# 
  .Synopsis
  Get child items count

  .Description
  
  .Parameter Directory
  Directory

  .Example
  Get-ChildItemCount "C:\Foo"
#>
Function Get-ChildItemCount {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string[]]$Directory
  )
  $count = If (Test-Path -LiteralPath $Directory) {
    $(Get-ChildItem $Directory).Count
  } Else {
    0
  }
  $PSCmdlet.WriteObject($count)
}



<# 
  .Synopsis
  Delete directory

  .Description
  Delete directory

  .Parameter Path
  Diretory path

  .Example
  Remove-Directory "C:\foo\bar"
#>
Function Remove-Directory {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$Path,
    [switch]$Recurse
  )
  $IsRecurse = $PSCmdlet.MyInvocation.BoundParameters["Recurse"].IsPresent
  [System.IO.Directory]::Delete($Path, $IsRecurse)
}



<# 
  .Synopsis
  Move item to directory

  .Description
  Move item to directory and create the directory if not exists

  .Parameter LiteralPath
  Item path

  .Parameter Destinaton
  Destination directory

  .Parameter PassThru
  Returns an object representing the file which was moved. By default, this cmdlet does not generate any output.

  .Parameter Force
  Forces the command to run without asking for user confirmation.

  .Example
  Move-ItemToDirectory "C:\foo\bar.txt" "C:\foo"
#>
Function Move-ItemToDirectory {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$LiteralPath,
    [string]$Destination,
    [switch]$PassThru,
    [switch]$Force
  )    
  $IsVerbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
  $IsPassThru = $PSCmdlet.MyInvocation.BoundParameters["PassThru"].IsPresent
  $IsForce = $PSCmdlet.MyInvocation.BoundParameters["Force"].IsPresent
  New-DirectoryIfNotExists $Destination
  If (-Not [string]::IsNullOrEmpty($LiteralPath) -And $(Test-Path -Path $LiteralPath)) {
    Move-Item -LiteralPath $LiteralPath -Destination $Destination -Force:$IsForce -PassThru:$IsPassThru -Verbose:$IsVerbose
  } ElseIf ($IsVerbose) {
    Write-Verbose "Cannot 'Move-ItemToDirectory' because parameter 'LiterlaPath' is an empty string" -Verbose
  }
}