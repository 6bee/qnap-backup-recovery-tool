# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.
#
# Clear-Glacier-Vault.ps1
# 
[CmdletBinding()]
Param (
  [string]$ParameterFile = $( Read-Host "Input parameter file path, please" )
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module (Join-Path $PSScriptRoot "Utilities") -Force -Verbose:$Verbose
Import-Module (Join-Path $PSScriptRoot "AWS-Tools") -Force -Verbose:$Verbose

$configuration = Read-JsonFile -Path $ParameterFile -Verbose:$Verbose


Write-Host "Clear-Glacier-Vault"
Write-Host "*******************"
Write-Host "Account Id: '$($configuration.AccountId)'"
Write-Host "Region:     '$($configuration.Region)'"
Write-Host "Vaults:     '$(($configuration.Vaults | % {$_.VaulName}) -join ", ")'"
Write-Host ""
Write-Host "Hit Enter to continue..."


Set-AwsCredentials $configuration.AccessKey $configuration.SecretKey -Verbose:$Verbose

$configuration.Vaults | ForEach-Object {
  Clear-AwsGlacierVault $configuration.AccountId $configuration.Region $_.VaultName -Verbose:$Verbose
}