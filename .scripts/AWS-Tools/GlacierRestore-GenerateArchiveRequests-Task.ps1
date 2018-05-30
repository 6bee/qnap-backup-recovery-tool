# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

[CmdletBinding()]
Param (
  [string]$TaskDirectory,
  [string]$NextTaskDirectory = $null
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module Utilities -Force -Verbose:$Verbose
Import-Module AWS-Tools -Force -Verbose:$Verbose

$env:Logger = "GlacierRestore-GenerateArchiveRequests-Task"
$PendingDirectory = Join-Path $TaskDirectory $env:pending
$ProcessingDirectory = Join-Path $TaskDirectory $env:processing
$SucceessDirectory = Join-Path $TaskDirectory $env:success
$FailureDirectory = Join-Path $TaskDirectory $env:failure
If ($NextTaskDirectory) {
  $NextTaskDirectory = Join-Path $NextTaskDirectory $env:pending
}
New-DirectoryIfNotExists $PendingDirectory $ProcessingDirectory $SucceessDirectory $FailureDirectory $NextTaskDirectory -Verbose:$Verbose

$pattern = "generate-archive-requests-*.json"
"Start watching folder '$PendingDirectory' for pattern '$pattern'..." | Out-Log -Level Information | Write-Host

While ($true) {
  Try {
    $files = Get-ChildItem $PendingDirectory -Filter $pattern
    If ($files.Count -gt 0) {
      $file = $(Move-Item -LiteralPath $files[0].FullName -Destination $ProcessingDirectory -Force -PassThru -Verbose:$Verbose).FullName
      Try {
        $config = Read-JsonFile -Path $file -Verbose:$Verbose
        
        Read-JsonFile $config.InventoryFile `
          | Select-Object -ExpandProperty ArchiveList `
          | ForEach-Object { @{Archive=$_; Description=$(ConvertFrom-Json -InputObject $_.ArchiveDescription)} } `
          | Where-Object { $_.Description.type -eq 'file' } `
          | Invoke-Script { 
            "Retieved inventory of vault '$($config.VaultName)' containing $($_.Count) archives" | Out-Log -Level Information | Write-Host
            } `
          | ForEach-Object {
            $nextTaskFile = Join-Path $NextTaskDirectory "request-archive-[obj#$(Get-StringStart -InputString $_.Archive.ArchiveId -Length $env:MaxIdSize)].json"
            "Creating Task File: $nextTaskFile" | Out-Log -Level Information | Write-Host
            $config `
              | Get-ShallowCopy -ExcludeProperty @("JobId", "InventoryFile") `
              | Add-Member ArchivePath $_.Description.path -PassThru -Verbose:$Verbose `
              | Add-Member ArchiveId $_.Archive.ArchiveId -PassThru -Verbose:$Verbose `
              | Add-Member Size $_.Archive.Size -PassThru -Verbose:$Verbose `
              | Add-Member SHA256Hash $_.Archive.SHA256TreeHash -PassThru -Verbose:$Verbose `
              | Write-JsonFile -Path $nextTaskFile -Verbose:$Verbose
            }
        
        Move-Item -LiteralPath $file -Destination $SucceessDirectory -Force -Verbose:$Verbose
      }
      Catch {
        Move-Item -LiteralPath $file -Destination $FailureDirectory -Force -Verbose:$Verbose
        Throw $_.Exception
      }
    } Else {
      Start-RandomSleep -Verbose:$Verbose
    }
  }
  Catch {
    "Exception: '$($_.Exception.Message)'" | Out-Log -Level Error | Write-Error
    Start-Sleep -Seconds 10 -Verbose:$Verbose
  }
}