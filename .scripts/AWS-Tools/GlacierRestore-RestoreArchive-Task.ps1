# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

[CmdletBinding()]
Param (
  [string]$TaskDirectory
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module Utilities -Force -Verbose:$Verbose
Import-Module AWS-Tools -Force -Verbose:$Verbose

$env:Logger = "GlacierRestore-RestoreArchive-Task"
$PendingDirectory = Join-Path $TaskDirectory $env:pending
$ProcessingDirectory = Join-Path $TaskDirectory $env:processing
$SucceessDirectory = Join-Path $TaskDirectory $env:success
$FailureDirectory = Join-Path $TaskDirectory $env:failure
New-DirectoryIfNotExists $PendingDirectory $ProcessingDirectory $SucceessDirectory $FailureDirectory -Verbose:$Verbose

$RemoveSource = $false
$pattern = "restore-archive-*.json"
"Start watching folder '$PendingDirectory' for pattern '$pattern'..." | Out-Log -Level Information | Write-Host

While ($True) {
  Try {
    $files = Get-ChildItem $PendingDirectory -Filter $pattern
    If ($files.Count -gt 0) {
      $file = $(Move-Item -LiteralPath $files[0].FullName -Destination $ProcessingDirectory -Force -PassThru -Verbose:$Verbose).FullName
      Try {
        $config = Read-JsonFile -Path $file -Verbose:$Verbose
                
        $ArchivePath = $(ConvertFrom-Json -InputObject "`"$($config.ArchivePath)`"")
        "ArchivePath $ArchivePath" | Out-Log | Write-Host

        $RestoreDirectory = Get-IfTrue `
          -Test $([System.IO.Path]::IsPathRooted($config.RestoreDirectory)) `
          -IfTrue $config.RestoreDirectory `
          -IfFalse $(Join-Path $pwd $config.RestoreDirectory)
        $targetFile = Join-Path $RestoreDirectory $ArchivePath
        New-DirectoryIfNotExists $([System.IO.Path]::GetDirectoryName($targetFile)) -Verbose:$Verbose
        "Restore archive $targetFile" | Out-Log -Level Information | Write-Host

        If ($RemoveSource) {
          "Move archive $($ArchivePath)" | Out-Log | Write-Host
          Move-Item -LiteralPath $config.SourceFile -Destination $targetFile -Force -Verbose:$Verbose
        } Else {
          "Copy archive $($ArchivePath)" | Out-Log | Write-Host
          Copy-Item -LiteralPath $config.SourceFile -Destination $targetFile -Force -Verbose:$Verbose
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