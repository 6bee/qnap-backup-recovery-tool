# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

[CmdletBinding()]
Param (
  [string]$TaskDirectory,
  [string]$NextTaskDirectory = $null
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module Utilities -Force -Verbose:$Verbose
Import-Module AWS-Tools -Force -Verbose:$Verbose

$env:Logger = "GlacierRestore-DecryptArchive-Task"
$PendingDirectory = Join-Path $TaskDirectory $env:pending
$ProcessingDirectory = Join-Path $TaskDirectory $env:processing
$SucceessDirectory = Join-Path $TaskDirectory $env:success
$FailureDirectory = Join-Path $TaskDirectory $env:failure
$DataDirectory = Join-Path $TaskDirectory $env:data
If ($NextTaskDirectory) {
  $NextTaskDirectory = Join-Path $NextTaskDirectory $env:pending
}
New-DirectoryIfNotExists $PendingDirectory $ProcessingDirectory $SucceessDirectory $FailureDirectory $DataDirectory $NextTaskDirectory -Verbose:$Verbose

$pattern = "decrypt-archive-*.json"
"Start watching folder '$PendingDirectory' for pattern '$pattern'..." | Out-Log -Level Information | Write-Host

While ($True) {
  Try {
    $files = Get-ChildItem $PendingDirectory -Filter $pattern
    If ($files.Count -gt 0) {
      $file = $(Move-ItemToDirectory -LiteralPath $files[0].FullName -Destination $ProcessingDirectory -Force -PassThru -Verbose:$Verbose).FullName
      Try {
        $config = Read-JsonFile -Path $file -Verbose:$Verbose
        
        $outfile = Join-Path $DataDirectory "archive-[obj#$(Get-StringStart -InputString $config.ArchiveId -Length $env:MaxIdSize)].dat"

        Invoke-DecryptFile `
          -SourceFilePath $config.SourceFile `
          -DestinatonFilePath $outfile `
          -Key $(ConvertFrom-ProtectedString $config.ProtectedDecryptionPassword) `
          -Verbose:$Verbose
        
        If (-Not (Test-Path -LiteralPath $outfile)) {
          Throw "Decryption task failed for file '$($config.SourceFile)' (archiveid=$($config.ArchiveId))"
        }

        If ($NextTaskDirectory) {
          $nextTaskFile = Join-Path $NextTaskDirectory "decompress-archive-[obj#$(Get-StringStart -InputString $config.ArchiveId -Length $env:MaxIdSize)].json"
          "Creating Task File: $nextTaskFile" | Out-Log -Level Information | Write-Host 
          @{
            ArchiveId = $config.ArchiveId
            ArchivePath = $config.ArchivePath
            RestoreDirectory = $config.RestoreDirectory
            VaultName = $config.VaultName
            SourceFile = $outfile
          } | Write-JsonFile -Path $nextTaskFile -Verbose:$Verbose
        }
          
        Move-ItemToDirectory -LiteralPath $file -Destination $SucceessDirectory -Force -Verbose:$Verbose
      }
      Catch {
        Move-ItemToDirectory -LiteralPath $file -Destination $FailureDirectory -Force -Verbose:$Verbose
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