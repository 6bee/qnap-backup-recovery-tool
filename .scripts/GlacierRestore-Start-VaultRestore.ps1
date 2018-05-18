# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.
#
# GlacierRestore-Start-VaultRestore.ps1
# 
[CmdletBinding()]
Param (
  [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
  [string[]]$ParameterFile
)

If (-Not $ParameterFile -Or $ParameterFile.Length -eq 0){
  $ParameterFile = @($(Read-Host "Input parameter file path, please"))
}

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module (Join-Path $PSScriptRoot "Utilities") -Force -Verbose:$Verbose
Import-Module (Join-Path $PSScriptRoot "AWS-Tools") -Force -Verbose:$Verbose

$ParameterFile | ForEach-Object {
  $configuration = Read-JsonFile -Path $_ -Verbose:$Verbose


  Write-Host "Start-Glacier-Vault-Restore"
  Write-Host "***************************"
  Write-Host "Account Id: '$($configuration.AccountId)'"
  Write-Host "Region:     '$($configuration.Region)'"
  Write-Host "Vaults:     $(($configuration.Vaults | % {"'$($_.VaultName)'"}) -join ", ")"
  Write-Host ""
  Write-Host "Hit Enter to continue..."
  Read-Host


  Invoke-TriggerAwsGlacierVaultRestore $configuration -Verbose:$Verbose
}