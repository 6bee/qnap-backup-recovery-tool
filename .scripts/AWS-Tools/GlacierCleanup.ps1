# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

<#
 .Synopsis
  Get AWS Glacier Vaults

 .Description
  Lists AWS Glacier Vaults.

 .Parameter AccountId
  AccountId

 .Parameter Region
  Region

 .Example
  Get-AwsGlacierVaults "123456789012" "us-central-1"
#>
Function Get-AwsGlacierVaults {
    [CmdletBinding()] Param (
      [string]$AccountId = $( Read-Host "Input AccountId, please" ),
      [string]$Region = $( Read-Host "Input Region, please" )
    )

    Write-Verbose "Get-AwsGlacierVaults AccountId: $AccountId, Region: $Region"

    $result = Send-AwsCommand glacier list-vaults `
      "--account-id=$AccountId" `
      "--region=$Region" `
      -JsonResult
    $PSCmdlet.WriteObject($result)	
  }

  <#
   .Synopsis
    Get AWS Glacier Vault Inventory

   .Description
    Retrieves the inventory (archives) of an AWS Glacier vault and returns the path of the inventory file. (This operation may take over a day.)

   .Parameter AccountId
    AccountId

   .Parameter Region
    Region

   .Parameter VaultName
    Vault name

   .Parameter WorkingDirectory
    Working Directory

   .Example
    Get-AwsGlacierVaultInventory "123456789012" "us-central-1" "vault_1" "1234" "1234/abcd" "working-dir"
  #>
  Function Get-AwsGlacierVaultInventory {
    [CmdletBinding()] Param (
      [string]$AccountId = $( Read-Host "Input Account Id, please" ),
      [string]$Region = $( Read-Host "Input Region, please" ),
      [string]$VaultName = $( Read-Host "Input VaultName, please" ),
      [string]$WorkingDirectory = $( Read-Host "Input Working Directory, please [default: '.working-dir']")
    )

    Write-Verbose "Get-AwsGlacierVaultInventory AccountId: $AccountId, Region: $Region, Vault: $VaultName"

    If ($WorkingDirectory.Length -eq 0){
      $WorkingDirectory = ".working-dir"
    }

    If (![System.IO.Path]::IsPathRooted($WorkingDirectory)){
      $WorkingDirectory = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $WorkingDirectory))
    }

    If (-Not (Test-Path -LiteralPath $WorkingDirectory)){
      New-Item -ItemType directory -Path $WorkingDirectory > $null
    }


    ### request inventory download
    Write-Host "Requesting inventory"
    $job = Send-AwsCommand glacier initiate-job `
      "--account-id=$AccountId" `
      "--region=$Region" `
      "--vault-name=$VaultName" `
      "--job-parameters=Type=inventory-retrieval" `
      -JsonResult
    If (!$job) {
      $errmsg = "Failed to initiate job for inventory retrieval"
      Write-Error $errmsg
      Throw $errmsg
    }
    $jobId = $job.jobId
    Write-Host "  inventory-retrieval-job-id $jobId"


    ### wait for inventory be ready for download
    Write-Host "Polling inventory"
    Do {
      $jobStatus = Send-AwsCommand glacier describe-job `
        "--account-id=$AccountId" `
        "--region=$Region" `
        "--vault-name=$VaultName" `
        "--job-id=$jobId" `
        -JsonResult
      If (!$jobStatus){
        Write-Host "Polling failure for job $($job.jobId)"
      }
      ElseIf ($jobStatus.Completed){
        If($jobStatus.StatusCode -eq "Succeeded"){
          Write-Host "Polling inventory '$VaultName' succeeded"
          break
        } Else  {
          Write-Error "Polling inventory '$VaultName' failed"
        }
      } Else {
        Write-Host "Polling inventory '$VaultName' ..."
      }

      Start-Sleep -s 900
    } While($True)


    ### download inventory
    Write-Host "Downloading inventory"
    $inventoryFilePath = Join-Path $WorkingDirectory "inventory-$jobId.json"
    $result = Send-AwsCommand glacier get-job-output `
      "--account-id=$AccountId" `
      "--region=$Region" `
      "--vault-name=$VaultName" `
      "--job-id=$jobId" `
      "$inventoryFilePath" `
      -JsonResult
    If ($result.status -ne 200){
      Write-Host "$status <> 200"
      Throw "Downloading inventory failed: $(ConvertFrom-Json -InputObject $(-join $result))"
    }

    $PSCmdlet.WriteObject($inventoryFilePath)	
  }

  <#
   .Synopsis
    Clear AWS Glacier Vault

   .Description
    Deletes all archives in an AWS Glacier Vault.

   .Parameter AccountId
    AccountId

   .Parameter Region
    Region

   .Parameter VaultName
    VaultName

   .Example
     Clear-AwsGlacierVault "123456789012" "us-central-1" "vault_1"
  #>
  Function Clear-AwsGlacierVault {
    [CmdletBinding()] Param (
      [string]$AccountId,
      [string]$Region,
      [string]$VaultName
    )

    Write-Verbose "Clear-AwsGlacierVault AccountId: $AccountId, Region: $Region, Vault: $VaultName"

    $InventoryFilePath = Get-AwsGlacierVaultInventory "$AccountId" "$Region" "$VaultName" (Get-Location)
    $InventoryJson = Get-Content $InventoryFilePath

    ConvertFrom-Json -InputObject $InventoryJson |
      Select-Object -ExpandProperty ArchiveList |
      ForEach-Object {
        Write-Host "Delete archive $($_.ArchiveId)"
        Send-AwsCommand glacier delete-archive `
          "--account-id=$AccountId" `
          "--region=$Region" `
          "--vault-name=$VaultName" `
          "--archive-id=$($_.ArchiveId)" `
          -JsonResult
      }
  }

  <#
   .Synopsis
    Remove AWS Glacier Vault

   .Description
    Deletes an AWS Glacier Vault. This requires the Vault to be empty since the last inventory was created,
    i.e. you may have to clear the vault first and wait about 24 hours until it can be deleted.

   .Parameter AccountId
    AccountId

   .Parameter Region
    Region

   .Parameter VaultName
    VaultName

   .Example
     Remove-AwsGlacierVault "123456789012" "us-central-1" "vault_1"
  #>
  Function Remove-AwsGlacierVault {
    [CmdletBinding()] Param (
      [string]$AccountId,
      [string]$Region,
      [string]$VaultName
    )

    Write-Verbose "Remove-AwsGlacierVault AccountId: $AccountId, Region: $Region, Vault: $VaultName"

    $result = Send-AwsCommand glacier delete-vault `
      "--account-id=$AccountId" `
      "--region=$Region" `
      "--vault-name=$VaultName" `
      -JsonResult
    $PSCmdlet.WriteObject($result)
  }