# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

$Tasks = Join-Path $WorkingDirectory "glacier"

$GlacierRequestInventory = Join-Path $Tasks "request-inventory"
$GlacierPollInventoryJob = Join-Path $Tasks "poll-inventory-job"
$GlacierDownloadInventory = Join-Path $Tasks "download-inventory"
$GlacierGenerateArchiveRequests = Join-Path $Tasks "generate-archive-requests"
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

  $result = Send-AwsCommand glacier list-jobs `
    "--account-id=$AccountId" `
    "--region=$Region" `
    "--vault-name=$VaultName" `
    -JsonResult
  $PSCmdlet.WriteObject($result)
}



<#
 .Synopsis
  Get Job Output

 .Description
  Downloads the result of a job

 .Parameter AccountId
  AccountId

 .Parameter Region
  Region

 .Parameter VaultName
  VaultName

 .Parameter JobId
  JobId

 .Parameter Outfile
  Outfile

 .Example
  Get-JobOutput "123456789012" "us-central-1" "vault_1" "abcdefghijklmopqrstuvwxyz"
#>
Function Get-JobOutput {
  [CmdletBinding()] Param (
    [string]$AccountId,
    [string]$Region,
    [string]$VaultName,
    [string]$JobId,
    [string]$Outfile,
    [int]$Size,
    [int]$PartSizeMb = 50
  )

  Write-Verbose "Get-JobOutput AccontId: $AccountId, Region: $Region, Vault: $VaultName, JobId: $JobId, Outfile:$Outfile, PartSizeMb:$PartSizeMb"

  $Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
  $PartSize = $PartSizeMb * 1024 * 1024

  If ((-Not $Size) -Or ($PartSize -le 0) -Or ($PartSize -ge $Size)) {
    $result = Send-AwsCommand glacier get-job-output `
      "--account-id=$AccountId" `
      "--region=$Region" `
      "--vault-name=$VaultName" `
      "--job-id=$JobId" `
      "$Outfile" `
      -JsonResult `
      -Verbose:$Verbose

    If ($result.status -ne 200) {
      Throw "Download failed (jobid=$JobId): $result"
    }
  } Else {
    $n = -1
    Do {
      $rangeFrom = ++$n * $PartSize
      $rangeTo = ($rangeFrom + $PartSize) - 1
      # increase part size if left over less than 5 percent of the part size
      If (($Size - $rangeTo - 1) -lt ($PartSize * 0.05)) {
        $rangeTo = $Size-1
      }

      $result = Send-AwsCommand glacier get-job-output `
        "--account-id=$AccountId" `
        "--region=$Region" `
        "--vault-name=$VaultName" `
        "--job-id=$JobId" `
        "--range=bytes=$rangeFrom-$rangeTo" `
        "$Outfile.part$n" `
        -JsonResult `
        -Verbose:$Verbose

      If ($result.status -notin 200, 206 ) {
        Throw "Download failed for part $n (jobid=$JobId): $result"
      }
      If (-Not (Test-Path -LiteralPath "$Outfile.part$n")) {
        Throw "Download failed for part $n (jobid=$JobId): no output file: $result"
      }
    } While ($rangeTo -lt $Size-1)

    If (Test-Path $Outfile) {
      Remove-Item -LiteralPath $Outfile
    }

    0..$n | ForEach-Object {
      Get-Content -LiteralPath "$Outfile.part$_" -Encoding Byte -ReadCount 512 | Add-Content -LiteralPath $Outfile -Encoding Byte
    }

    $size = (Get-Item -LiteralPath $Outfile).Length
    If ($size -eq $Size) {
      "Deleting part 0 to $n of file '$Outfile'" | Out-Log | Write-Verbose
      0..$n | ForEach-Object {
        Remove-Item -LiteralPath "$Outfile.part$_"
      }
    }
  }

  $PSCmdlet.WriteObject($result)
}