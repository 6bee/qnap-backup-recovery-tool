# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.
#
# Generate-AWS-Configuration-Template.ps1
#
[CmdletBinding()]
Param (
  [string]$File = "aws-job-configuration-template.json"
)

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module (Join-Path $PSScriptRoot "Utilities") -Force -Verbose:$Verbose
Import-Module (Join-Path $PSScriptRoot "AWS-Tools") -Force -Verbose:$Verbose

Write-AwsConfigurationTemplate $File -Verbose:$Verbose