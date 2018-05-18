# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

<# 
 .Synopsis
  Run background task for Glacier Vault Restore

 .Description
  Run inftrastructure for asynchronous and resumable restoring process of AWS Glacier Vaults

 .Example
  Start-AwsGlacierRestoreBackgroundTasks
#>
Function Start-AwsGlacierRestoreBackgroundTasks {
  [CmdletBinding()]
  Param ()
  
  #$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
  
  $GlacierRequestInventoryPending = Join-Path $GlacierRequestInventory $env:pending
  $GlacierRequestInventoryProcessing = Join-Path $GlacierRequestInventory $env:processing
  $GlacierRequestInventorySuccess = Join-Path $GlacierRequestInventory $env:success
  $GlacierRequestInventoryFailure = Join-Path $GlacierRequestInventory $env:failure
  
  $GlacierPollInventoryJobPending = Join-Path $GlacierPollInventoryJob $env:pending
  $GlacierPollInventoryJobProcessing = Join-Path $GlacierPollInventoryJob $env:processing
  $GlacierPollInventoryJobSuccess = Join-Path $GlacierPollInventoryJob $env:success
  $GlacierPollInventoryJobFailure = Join-Path $GlacierPollInventoryJob $env:failure
  
  $GlacierDownloadInventoryPending = Join-Path $GlacierDownloadInventory $env:pending
  $GlacierDownloadInventoryProcessing = Join-Path $GlacierDownloadInventory $env:processing
  $GlacierDownloadInventorySuccess = Join-Path $GlacierDownloadInventory $env:success
  $GlacierDownloadInventoryFailure = Join-Path $GlacierDownloadInventory $env:failure
  
  $GlacierRequestArchivePending = Join-Path $GlacierRequestArchive $env:pending
  $GlacierRequestArchiveProcessing = Join-Path $GlacierRequestArchive $env:processing
  $GlacierRequestArchiveSuccess = Join-Path $GlacierRequestArchive $env:success
  $GlacierRequestArchiveFailure = Join-Path $GlacierRequestArchive $env:failure
  
  $GlacierPollArchiveJobPending = Join-Path $GlacierPollArchiveJob $env:pending
  $GlacierPollArchiveJobProcessing = Join-Path $GlacierPollArchiveJob $env:processing
  $GlacierPollArchiveJobSuccess = Join-Path $GlacierPollArchiveJob $env:success
  $GlacierPollArchiveJobFailure = Join-Path $GlacierPollArchiveJob $env:failure
  
  $GlacierDownloadArchivePending = Join-Path $GlacierDownloadArchive $env:pending
  $GlacierDownloadArchiveProcessing = Join-Path $GlacierDownloadArchive $env:processing
  $GlacierDownloadArchiveSuccess = Join-Path $GlacierDownloadArchive $env:success
  $GlacierDownloadArchiveFailure = Join-Path $GlacierDownloadArchive $env:failure
  
  $GlacierDecryptArchivePending = Join-Path $GlacierDecryptArchive $env:pending
  $GlacierDecryptArchiveProcessing = Join-Path $GlacierDecryptArchive $env:processing
  $GlacierDecryptArchiveSuccess = Join-Path $GlacierDecryptArchive $env:success
  $GlacierDecryptArchiveFailure = Join-Path $GlacierDecryptArchive $env:failure
  
  $GlacierDecompressArchivePending = Join-Path $GlacierDecompressArchive $env:pending
  $GlacierDecompressArchiveProcessing = Join-Path $GlacierDecompressArchive $env:processing
  $GlacierDecompressArchiveSuccess = Join-Path $GlacierDecompressArchive $env:success
  $GlacierDecompressArchiveFailure = Join-Path $GlacierDecompressArchive $env:failure
  
  $GlacierRestoreArchivePending = Join-Path $GlacierRestoreArchive $env:pending
  $GlacierRestoreArchiveProcessing = Join-Path $GlacierRestoreArchive $env:processing
  $GlacierRestoreArchiveSuccess = Join-Path $GlacierRestoreArchive $env:success
  $GlacierRestoreArchiveFailure = Join-Path $GlacierRestoreArchive $env:failure
  
  $init = [ScriptBlock]::Create(@"
    Set-Location '$pwd'
"@)
  
Try {
  "Starting-up backgroud processes" | Out-Log -Logger "AwsGlacierRestoreBackgroundTasks" -Level Information
  "PWD: $pwd" | Out-Log -Logger "AwsGlacierRestoreBackgroundTasks"
    
  Start-Job `
    -Name "Request-Inventory" `
    -FilePath $(Join-Path $PSScriptRoot "GlacierRestore-RequestInventory-Task.ps1") `
      -InitializationScript $init `
      -ArgumentList @($GlacierRequestInventory, $GlacierPollInventoryJob ) 
    
    Start-Job `
      -Name "Poll-Inventory-Job" `
      -FilePath $(Join-Path $PSScriptRoot "GlacierRestore-PollInventoryJob-Task.ps1") `
      -InitializationScript $init `
      -ArgumentList @($GlacierPollInventoryJob, $GlacierDownloadInventory) 
    
    1..$NumberOfInventoryDownloadJobs | ForEach-Object {
    Start-Job `
      -Name "Download-Inventory #$_" `
      -FilePath $(Join-Path $PSScriptRoot "GlacierRestore-DownloadInventory-Task.ps1") `
      -InitializationScript $init `
      -ArgumentList @($GlacierDownloadInventory, $GlacierRequestArchive)
    }
    
    Start-Job `
    -Name "Request-Archive" `
    -FilePath $(Join-Path $PSScriptRoot "GlacierRestore-RequestArchive-Task.ps1") `
      -InitializationScript $init `
      -ArgumentList @($GlacierRequestArchive, $GlacierPollArchiveJob) 
    
    Start-Job `
      -Name "Poll-Archive-Job" `
      -FilePath $(Join-Path $PSScriptRoot "GlacierRestore-PollArchiveJob-Task.ps1") `
      -InitializationScript $init `
      -ArgumentList @($GlacierPollArchiveJob, $GlacierDownloadArchive) 
    
    1..$NumberOfArchiveDownloadJobs | ForEach-Object {
    Start-Job `
      -Name "Download-Archive #$_" `
      -FilePath $(Join-Path $PSScriptRoot "GlacierRestore-DownloadArchive-Task.ps1") `
      -InitializationScript $init `
      -ArgumentList @($GlacierDownloadArchive, $GlacierDecryptArchive)
    }
    
    Start-Job `
      -Name "Decrypt-Archive" `
      -FilePath $(Join-Path $PSScriptRoot "GlacierRestore-DecryptArchive-Task.ps1") `
      -InitializationScript $init `
      -ArgumentList @($GlacierDecryptArchive, $GlacierDecompressArchive) 
    
    Start-Job `
      -Name "Decompress-Archive" `
      -FilePath $(Join-Path $PSScriptRoot "GlacierRestore-DecompressArchive-Task.ps1") `
      -InitializationScript $init `
      -ArgumentList @($GlacierDecompressArchive, $GlacierRestoreArchive) 
    
    Start-Job `
      -Name "Restore-Archive" `
      -FilePath $(Join-Path $PSScriptRoot "GlacierRestore-RestoreArchive-Task.ps1") `
      -InitializationScript $init `
      -ArgumentList @($GlacierRestoreArchive) 
  

    "Begin monitoring task folders" | Out-Log -Logger "AwsGlacierRestoreBackgroundTasks" -Level Information
    
    While($True) {  
      $list = @(
        New-Object -TypeName PSObject -Property @{ 
          Task       = "Request-Inventory"
          Pending    = $(Get-ChildItemCount $GlacierRequestInventoryPending)
          InProgress = $(Get-ChildItemCount $GlacierRequestInventoryProcessing)
          Succeeded  = $(Get-ChildItemCount $GlacierRequestInventorySuccess)
          Failed     = $(Get-ChildItemCount $GlacierRequestInventoryFailure) }
        
        New-Object -TypeName PSObject -Property @{ 
          Task       = "Poll-Inventory-Job"
          Pending    = $(Get-ChildItemCount $GlacierPollInventoryJobPending)
          InProgress = $(Get-ChildItemCount $GlacierPollInventoryJobProcessing)
          Succeeded  = $(Get-ChildItemCount $GlacierPollInventoryJobSuccess)
          Failed     = $(Get-ChildItemCount $GlacierPollInventoryJobFailure) }
        
        New-Object -TypeName PSObject -Property @{ 
          Task       = "Download-Inventory"
          Pending    = $(Get-ChildItemCount $GlacierDownloadInventoryPending)
          InProgress = $(Get-ChildItemCount $GlacierDownloadInventoryProcessing)
          Succeeded  = $(Get-ChildItemCount $GlacierDownloadInventorySuccess)
          Failed     = $(Get-ChildItemCount $GlacierDownloadInventoryFailure) }
        
        New-Object -TypeName PSObject -Property @{ 
          Task       = "Request-Archive"
          Pending    = $(Get-ChildItemCount $GlacierRequestArchivePending)
          InProgress = $(Get-ChildItemCount $GlacierRequestArchiveProcessing)
          Succeeded  = $(Get-ChildItemCount $GlacierRequestArchiveSuccess)
          Failed     = $(Get-ChildItemCount $GlacierRequestArchiveFailure) }
        
        New-Object -TypeName PSObject -Property @{ 
          Task       = "Poll-Archive-Job"
          Pending    = $(Get-ChildItemCount $GlacierPollArchiveJobPending)
          InProgress = $(Get-ChildItemCount $GlacierPollArchiveJobProcessing)
          Succeeded  = $(Get-ChildItemCount $GlacierPollArchiveJobSuccess)
          Failed     = $(Get-ChildItemCount $GlacierPollArchiveJobFailure) }
        
        New-Object -TypeName PSObject -Property @{ 
          Task       = "Download-Archive"
          Pending    = $(Get-ChildItemCount $GlacierDownloadArchivePending)
          InProgress = $(Get-ChildItemCount $GlacierDownloadArchiveProcessing)
          Succeeded  = $(Get-ChildItemCount $GlacierDownloadArchiveSuccess)
          Failed     = $(Get-ChildItemCount $GlacierDownloadArchiveFailure) }
        
        New-Object -TypeName PSObject -Property @{ 
          Task       = "Decrypt-Archive"
          Pending    = $(Get-ChildItemCount $GlacierDecryptArchivePending)
          InProgress = $(Get-ChildItemCount $GlacierDecryptArchiveProcessing)
          Succeeded  = $(Get-ChildItemCount $GlacierDecryptArchiveSuccess)
          Failed     = $(Get-ChildItemCount $GlacierDecryptArchiveFailure) }
        
        New-Object -TypeName PSObject -Property @{ 
          Task       = "Decompress-Archive"
          Pending    = $(Get-ChildItemCount $GlacierDecompressArchivePending)
          InProgress = $(Get-ChildItemCount $GlacierDecompressArchiveProcessing)
          Succeeded  = $(Get-ChildItemCount $GlacierDecompressArchiveSuccess)
          Failed     = $(Get-ChildItemCount $GlacierDecompressArchiveFailure) }
         
        New-Object -TypeName PSObject -Property @{ 
          Task       = "Restore-Archive"
          Pending    = $(Get-ChildItemCount $GlacierRestoreArchivePending)
          InProgress = $(Get-ChildItemCount $GlacierRestoreArchiveProcessing)
          Succeeded  = $(Get-ChildItemCount $GlacierRestoreArchiveSuccess)
          Failed     = $(Get-ChildItemCount $GlacierRestoreArchiveFailure) }
      )
  
      Clear-Host  
      Write-Host
      Write-Host "Running QNAP-AWS-Backup-Recovery processes."
      $list | Format-Table -Property Task, Pending, InProgress, Succeeded, Failed
      Write-Host  
      Write-Host "$(Get-Date)"
      Write-Host "Use Start-Glacier-Vault-Restore.ps1 to trigger restore of Glacier Vault."
      Write-Host "Enter Ctrl+C to terminate"
      Write-Host    
      Start-Sleep -Milliseconds 2000
    }
  }
  Finally {
    Get-Job | Stop-Job
  }
}