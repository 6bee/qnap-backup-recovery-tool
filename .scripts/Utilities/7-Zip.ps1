# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

<#
  Parts of this module use the 7-Zip program.
  7-Zip is licensed under the GNU LGPL license.
  www.7-zip.org
#>

# setup
If (-Not (Test-Path -LiteralPath Variable:7z)) {
  $OSArchitecture = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty OSArchitecture
  $7z = Join-Path $Tools "7-Zip\Bin\$OSArchitecture\7za.exe"
}


<#
 .Synopsis
  Decompress

 .Description
  Decompress

 .Parameter SourceFilePath
  Source file

 .Parameter DestinatonFilePath
  Destinatoin file

 .Example
  Invoke-DecompressFile "C:\Compressed.dat.bz2" "C:\Decompressed.dat"
#>
Function Invoke-DecompressFile {
  [CmdletBinding()] Param (
    [Parameter(Mandatory=$true)]
    [string]$SourceFilePath,
    [Parameter(Mandatory=$false)]
    [string]$DestinatonDirectory = $null
  )

  If (-Not $DestinatonDirectory) {
    $DestinatonDirectory = $pwd.Path
  }

  $result = & "$7z" "x" "$SourceFilePath" "-o$DestinatonDirectory"
  "$result" | Out-Log | Write-Verbose

  $filepath = [System.IO.Path]::Combine($DestinatonDirectory, [System.IO.Path]::GetFileNameWithoutExtension($SourceFilePath))

  If (-Not (Test-Path -LiteralPath $filepath)) {
    $message = "Decompression failed for '$SourceFilePath'"
    $message | Out-Log | Write-Verbose
    Throw $message
  }

  "Decompressed '$SourceFilePath' -> '$filepath'" | Out-Log | Write-Verbose
  $PSCmdlet.WriteObject($filepath)
}