# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.
#
# Restore-S3-Bucket.ps1
# 
[CmdletBinding()]
param (
  [string]$ParameterFile = $( Read-Host "Input parameter file path, please" )
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module (Join-Path $PSScriptRoot "Utilities") -Force -Verbose:$Verbose
Import-Module (Join-Path $PSScriptRoot "AWS-Tools") -Force -Verbose:$Verbose

$configuration = Read-JsonFile -Path $ParameterFile -Verbose:$Verbose


Write-Host "Restore-S3-Bucket"
Write-Host "*****************"
Write-Host "Buckets:     $(($configuration.S3Buckets | % {"'$($_.S3Uri)'"}) -join ", ")"
Write-Host ""
Write-Host "Hit Enter to continue..."
Read-Host


Invoke-AwsS3Restore -Configuration $configuration -Verbose:$Verbose