# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

$Tasks = Join-Path $WorkingDirectory "glacier"

$GlacierRequestInventory = Join-Path $Tasks "request-inventory"
$GlacierPollInventoryJob = Join-Path $Tasks "poll-inventory-job"
$GlacierDownloadInventory = Join-Path $Tasks "download-inventory"
$GlacierRequestArchive = Join-Path $Tasks "request-archive"
$GlacierPollArchiveJob = Join-Path $Tasks "poll-archive-job"
$GlacierDownloadArchive = Join-Path $Tasks "download-archive"
$GlacierDecryptArchive = Join-Path $Tasks "decrypt-archive"
$GlacierDecompressArchive = Join-Path $Tasks "decompress-archive"
$GlacierRestoreArchive = Join-Path $Tasks "restore-archive"

<# 
 .Synopsis
  Get AWS Glacier Vault Jobs

 .Description
  Lists jobs initiated for an AWS Glacier Vault.

 .Parameter AccountId
  AccountId

 .Parameter Region
  Region

 .Parameter VaultName
  VaultName

 .Example
  Get-AwsGlacierJobs "123456789012" "us-central-1" "vault_1"
#>
Function Get-AwsGlacierJobs {
  [CmdletBinding()] Param (
    [string]$AccountId,
    [string]$Region,
    [string]$VaultName
  )

  Write-Verbose "Get-AwsGlacierJobs AccontId: $AccountId, Region: $Region, Vault: $VaultName"

  $result = Send-AwsCommand glacier list-jobs --account-id $AccountId --region $Region --vault-name $VaultName -JsonResult
  $PSCmdlet.WriteObject($result)
}

