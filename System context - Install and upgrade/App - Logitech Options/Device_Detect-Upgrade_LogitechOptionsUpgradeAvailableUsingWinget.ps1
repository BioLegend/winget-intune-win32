﻿#Requires -Version 5.1
<#
    .SYNOPSIS
        Uses Winget to see if a new version is available for Logitech Options.

    .NOTES
        Author:   Olav Rønnestad Birkeland
        Created:  211120
        Modified: 220506

    .EXAMPLE
        & $psISE.CurrentFile.FullPath; $LASTEXITCODE
#>


# Input parameters
[OutputType($null)]
Param()


# PowerShell preferences
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'


# Assets
## Scenario specific
$FileDetectPath  = [string] '{0}\Logitech\LogiOptions\LogiOptions.exe' -f $env:ProgramW6432
$WingetPackageId = [string] 'Logitech.Options'

## Find winget-cli
### Find directory
$WingetDirectory = [string](
    $(
        if ([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value' -eq 'S-1-5-18') {
            (Get-Item -Path ('{0}\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe' -f $env:ProgramW6432)).'FullName' | Select-Object -First 1                
        }
        else {
            '{0}\Microsoft\WindowsApps' -f $env:LOCALAPPDATA
        }
    )
)
### Find file name
$WingetCliFileName = [string](
    $(
        [string[]](
            'AppInstallerCLI.exe',
            'winget.exe'
        )
    ).Where{
        [System.IO.File]::Exists(
            ('{0}\{1}' -f $WingetDirectory, $_)
        )
    } | Select-Object -First 1
)
### Combine and file name
$WingetCliPath = [string] '{0}\{1}' -f $WingetDirectory, $WingetCliFileName


# Check for things that should return exit code 1 to show correts stats in Intune. The Win32 requirement rules should take care of these scenarios.
## Check if installed, exit 1 if not
if (-not [System.IO.File]::Exists($FileDetectPath)) {
    Write-Output -InputObject 'Not installed, so no upgrade available.'
    Exit 1
}

## Check if $WingetCli exists, exit 1 if not
if (-not [System.IO.File]::Exists($WingetCliPath)) {
    Write-Output -InputObject 'Did not find Winget.'
    Exit 1
}


# Fix winget output encoding
$null = cmd /c '' # Workaround for PowerShell ISE "Exception setting "OutputEncoding": "The handle is invalid.""
$Global:OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()


# Check if update available with Winget
$WingetResult = [string[]](cmd /c ('"{0}" list --exact --id {1} --accept-source-agreements'-f $WingetCliPath, $WingetPackageId))


# View output from Winget
Write-Information -MessageData ($WingetResult[-3 .. -1] -join [System.Environment]::NewLine)


# Check if update was available, exit 0 if not
if ($WingetResult[-3] -like '*available*') {
    Write-Error -ErrorAction 'Continue' -Exception 'Update available.' -Message 'Update available.'
    Exit 1
}
else {
    Write-Output -InputObject 'No update available.'
    Exit 0
}
