# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

# Set PSScriptRoot (if run from ISE)
If (-Not $PSScriptRoot) {
  $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

$Tools = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\..\.tools"))

. (Join-Path $PSScriptRoot "7-Zip.ps1")
. (Join-Path $PSScriptRoot "Encryption.ps1")
. (Join-Path $PSScriptRoot "FileSystem.ps1")
. (Join-Path $PSScriptRoot "Logger.ps1")
. (Join-Path $PSScriptRoot "Logical.ps1")
. (Join-Path $PSScriptRoot "Object.ps1")
. (Join-Path $PSScriptRoot "Process.ps1")
. (Join-Path $PSScriptRoot "String.ps1")
