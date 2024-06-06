# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.

<#
 .Synopsis
  Restore S3 Bucket to local folder

 .Description
  Restores files from S3 Buckets to a local folder

 .Parameter Configuration
  AWS Configuration object

 .Example
  Invoke-AwsS3BucketDownload $config
#>
Function Invoke-AwsS3Restore {
  [CmdletBinding()] Param (
    [object]$Configuration
  )

  Write-Verbose "Invoke-AwsS3Restore"

  $Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent

  $Tasks = Join-Path $WorkingDirectory "s3"
  $S3Sync = Join-Path $Tasks "sync"
  $S3Decrypt = Join-Path $Tasks "decrypt"
  $S3Decompress = Join-Path $Tasks "decompress"

  $ComporessedFileExt = ".qnap.bz2"

  If ($(Test-Path $Tasks) -And $(Get-ChildItem -LiteralPath $Tasks -Recurse -Verbose:$Verbose  | Where-Object { -Not $_.PSIsContainer }).Count -gt 0) {
    $title = "Working directory is not empty!"
    $message = "Delete existing files and continue?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Delete files and continue"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Continue without deleting files"
    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit", "Exist application"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $exit)
    $choice = $host.ui.PromptForChoice($title, $message, $options, 0)
    switch($choice) {
      0 { Remove-Directory -Path $Tasks -Recurse -Verbose:$Verbose }
      2 { return }
    }
  }

  New-DirectoryIfNotExists $S3Sync $S3Decrypt $S3Decompress $Configuration.RestoreDirectory -Verbose:$Verbose

  Set-AwsCredentials $Configuration.AccessKey $Configuration.SecretKey -Verbose:$Verbose
  $configuration.S3Buckets | ForEach-Object {
    Invoke-AwsS3BucketDownload `
      -S3Uri $_.S3Uri `
      -TargetDirectory $S3Sync `
      -Verbose:$Verbose
  }

  Get-ChildItem -LiteralPath $S3Sync -Recurse -Verbose:$Verbose `
    | Where-Object { -Not $_.PSIsContainer } `
    | ForEach-Object {
      $destinationFile = Join-Path $S3Decrypt $_.FullName.Substring($S3Sync.Length)
      New-DirectoryIfNotExists $(Split-Path -Parent $destinationFile) -Verbose:$Verbose
      Invoke-DecryptFile `
        -SourceFilePath $_.FullName `
        -DestinatonFilePath $destinationFile `
        -Key $(ConvertFrom-ProtectedString $configuration.ProtectedDecryptionPassword) `
        -Verbose:$Verbose
    }

  Get-ChildItem -LiteralPath $S3Decrypt -Recurse -Verbose:$Verbose `
    | Where-Object { -Not $_.PSIsContainer } `
    | ForEach-Object {
      $destinationFolder = Split-Path -Parent $(Join-Path $S3Decompress $_.FullName.Substring($S3Decrypt.Length))
      New-DirectoryIfNotExists $destinationFolder -Verbose:$Verbose
      If ($_.Name -like "*$ComporessedFileExt") {
        $outfile = Invoke-DecompressFile -SourceFilePath $_.FullName -DestinatonDirectory $destinationFolder -Verbose:$Verbose
        Rename-Item -LiteralPath $outfile -NewName $($_.Name -Replace "$ComporessedFileExt$", "") -Verbose:$Verbose
      } Else {
        Copy-Item -LiteralPath $_.FullName -Destination $destinationFolder -Force -Verbose:$Verbose
      }
    }

  Copy-Item -Path $(Join-Path $S3Decompress "*") -Destination $Configuration.RestoreDirectory -Recurse -Force -Verbose:$Verbose
}



<#
 .Synopsis
  Sync S3 Bucket to local folder

 .Description
  Sync S3 Buckets to a local folder

 .Parameter S3Uri
  S3 URI

 .Parameter TargetDirectory
  Target directory

 .Example
  Invoke-AwsS3BucketDownload "s3://my-bucket/foo/bar" "C:\foo\bar"
#>
Function Invoke-AwsS3BucketDownload {
  [CmdletBinding()] Param (
    [string]$S3Uri,
    [string]$TargetDirectory
  )

  Write-Verbose "Invoke-AwsS3BucketDownload S3Uri: $S3Uri, TargetDirectory: $TargetDirectory"

  Send-AwsCommand s3 sync "$S3Uri" "$TargetDirectory" -Verbose:$Verbose
}