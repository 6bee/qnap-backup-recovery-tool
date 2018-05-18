# Copyright (c) Christof Senn. All rights reserved. See license.txt in the project root for license information.
#
# GlacierRestore-Run-BackgroundTasks.ps1
# 
[CmdletBinding()]
Param ()

$Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent
Import-Module (Join-Path $PSScriptRoot "Utilities") -Force -Verbose:$Verbose
Import-Module (Join-Path $PSScriptRoot "AWS-Tools") -Force -Verbose:$Verbose

Start-AwsGlacierRestoreBackgroundTasks -Verbose:$Verbose