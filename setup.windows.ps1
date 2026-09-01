[CmdletBinding()]
param(
    [switch]$Upgrade,
    [switch]$SkipPackages,
    [switch]$SkipModules,
    [switch]$SkipFonts,
    [switch]$SkipVscodeExtensions,
    [switch]$SkipHelium,
    [switch]$SkipLinks,
    [switch]$NoBackup
)

$ErrorActionPreference = 'Stop'

if (
    $PSVersionTable.PSEdition -ne 'Core' -or
    $PSVersionTable.PSVersion.Major -lt 7
) {
    throw 'This setup must be run with PowerShell 7 (pwsh). Run setup.windows.cmd instead.'
}

$repoRoot = Split-Path -Parent $PSCommandPath

function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable(
        'Path',
        'Machine'
    )
    $userPath = [Environment]::GetEnvironmentVariable(
        'Path',
        'User'
    )

    $env:Path = "$machinePath;$userPath"
}

function Assert-LastExitCode {
    param(
        [Parameter(Mandatory)]
        [string]$Action
    )

    if ($LASTEXITCODE -ne 0) {
        throw "$Action failed with exit code $LASTEXITCODE."
    }
}

function Test-WingetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    & winget list `
        --id $Id `
        --exact `
        --source winget `
        --accept-source-agreements `
        --disable-interactivity |
        Out-Null

    return $LASTEXITCODE -eq 0
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if (Test-WingetPackage -Id $Id) {
        if (-not $Upgrade) {
            Write-Host "already installed: $Name ($Id)"
            return
        }

        Write-Host "upgrade: $Name ($Id)"
        & winget upgrade `
            --id $Id `
            --exact `
            --source winget `
            --accept-package-agreements `
            --accept-source-agreements `
            --disable-interactivity

        if ($LASTEXITCODE -notin @(0, -1978335189)) {
            Assert-LastExitCode -Action "Upgrading $Name"
        }

        return
    }

    Write-Host "install: $Name ($Id)"
    & winget install `
        --id $Id `
        --exact `
        --source winget `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity

    Assert-LastExitCode -Action "Installing $Name"
}

function Install-RequiredModule {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [version]$RequiredVersion
    )

    $installed = Get-Module `
        -ListAvailable `
        -Name $Name |
        Where-Object {
            -not $RequiredVersion -or
            $_.Version -eq $RequiredVersion
        } |
        Select-Object -First 1

    if ($installed) {
        Write-Host "already installed: PowerShell module $Name $($installed.Version)"
        return
    }

    $parameters = @{
        Name = $Name
        Repository = 'PSGallery'
        Scope = 'CurrentUser'
        Force = $true
        AllowClobber = $true
    }

    if ($RequiredVersion) {
        $parameters.RequiredVersion = $RequiredVersion
    }

    Write-Host "install: PowerShell module $Name"
    Install-Module @parameters
}

function Test-UserFont {
    param(
        [Parameter(Mandatory)]
        [string]$RegistryName
    )

    $fontRegistryPath = (
        'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    )

    if (-not (Test-Path -LiteralPath $fontRegistryPath)) {
        return $false
    }

    $fontProperties = Get-ItemProperty `
        -LiteralPath $fontRegistryPath

    return [bool](
        $fontProperties.PSObject.Properties.Name |
        Where-Object { $_ -like "$RegistryName*" } |
        Select-Object -First 1
    )
}

function Merge-Hashtable {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Target,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Source
    )

    foreach ($key in $Source.Keys) {
        if (
            $Source[$key] -is [System.Collections.IDictionary] -and
            $Target.Contains($key) -and
            $Target[$key] -is [System.Collections.IDictionary]
        ) {
            Merge-Hashtable `
                -Target $Target[$key] `
                -Source $Source[$key]
            continue
        }

        $Target[$key] = $Source[$key]
    }
}

function Install-HeliumPreferences {
    $heliumProcess = Get-Process `
        -Name 'helium' `
        -ErrorAction SilentlyContinue

    if ($heliumProcess) {
        Write-Warning 'Helium is running. Close it and rerun setup to apply Helium preferences.'
        return
    }

    $templatePath = Join-Path `
        $repoRoot `
        'Helium\preferences.portable.json'
    $preferencesPath = Join-Path `
        $env:LOCALAPPDATA `
        'imput\Helium\User Data\Default\Preferences'

    if (-not (Test-Path -LiteralPath $preferencesPath)) {
        Write-Warning 'Helium preferences were not found. Start and close Helium once, then rerun setup.'
        return
    }

    $preferences = Get-Content `
        -Raw `
        -LiteralPath $preferencesPath |
        ConvertFrom-Json -AsHashtable
    $portablePreferences = Get-Content `
        -Raw `
        -LiteralPath $templatePath |
        ConvertFrom-Json -AsHashtable

    $before = $preferences | ConvertTo-Json -Depth 100 -Compress
    Merge-Hashtable `
        -Target $preferences `
        -Source $portablePreferences
    $after = $preferences | ConvertTo-Json -Depth 100 -Compress

    if ($before -eq $after) {
        Write-Host 'already applied: Helium portable preferences'
        return
    }

    if (-not $NoBackup) {
        $backupPath = Join-Path `
            ([Environment]::GetFolderPath('UserProfile')) `
            ".dot-file-backups\$(Get-Date -Format 'yyyyMMdd-HHmmss')\AppData\Local\imput\Helium\User Data\Default\Preferences"
        $backupParent = Split-Path -Parent $backupPath

        New-Item `
            -ItemType Directory `
            -Path $backupParent `
            -Force |
            Out-Null
        Copy-Item `
            -LiteralPath $preferencesPath `
            -Destination $backupPath `
            -Force

        Write-Host "backup: $preferencesPath -> $backupPath"
    }

    $preferences |
        ConvertTo-Json -Depth 100 |
        Set-Content `
            -LiteralPath $preferencesPath `
            -Encoding utf8NoBOM

    Write-Host "apply: Helium portable preferences -> $preferencesPath"
}

$packages = @(
    @{ Name = 'Visual Studio Code'; Id = 'Microsoft.VisualStudioCode' }
    @{ Name = 'Node.js'; Id = 'OpenJS.NodeJS' }
    @{ Name = 'GlazeWM'; Id = 'glzr-io.glazewm' }
    @{ Name = 'LeopardWM'; Id = 'jcardama.LeopardWM' }
    @{ Name = 'YASB'; Id = 'AmN.yasb' }
    @{ Name = 'Flow Launcher'; Id = 'Flow-Launcher.Flow-Launcher' }
    @{ Name = 'Windows Terminal'; Id = 'Microsoft.WindowsTerminal' }
    @{ Name = 'PowerShell 7'; Id = 'Microsoft.PowerShell' }
    @{ Name = 'Oh My Posh'; Id = 'JanDeDobbeleer.OhMyPosh' }
    @{ Name = 'Starship'; Id = 'Starship.Starship' }
    @{ Name = 'lsd'; Id = 'lsd-rs.lsd' }
    @{ Name = 'fzf'; Id = 'junegunn.fzf' }
    @{ Name = 'zoxide'; Id = 'ajeetdsouza.zoxide' }
    @{ Name = 'komorebi'; Id = 'LGUG2Z.komorebi' }
)

if (-not $SkipPackages) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget was not found. Install or update App Installer from Microsoft Store.'
    }

    foreach ($package in $packages) {
        Install-WingetPackage @package
    }

    Refresh-Path
}

if (-not $SkipModules) {
    Install-RequiredModule `
        -Name 'PSFzf' `
        -RequiredVersion '2.7.10'
    Install-RequiredModule -Name 'CompletionPredictor'
}

if (-not $SkipFonts) {
    Refresh-Path

    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        throw 'oh-my-posh was not found, so Nerd Fonts could not be installed.'
    }

    $fonts = @(
        @{ InstallerName = 'Lilex'; RegistryName = 'Lilex Nerd Font Regular' }
        @{ InstallerName = 'JetBrainsMono'; RegistryName = 'JetBrainsMono NFM Regular' }
    )

    foreach ($font in $fonts) {
        if (Test-UserFont -RegistryName $font.RegistryName) {
            Write-Host "already installed: Nerd Font $($font.InstallerName)"
            continue
        }

        Write-Host "install: Nerd Font $($font.InstallerName)"
        & oh-my-posh font install $font.InstallerName --plain
        Assert-LastExitCode `
            -Action "Installing Nerd Font $($font.InstallerName)"
    }
}

if (-not $SkipVscodeExtensions) {
    Refresh-Path

    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        throw 'The VS Code CLI was not found, so extensions could not be installed.'
    }

    $extensionListPath = Join-Path $repoRoot 'vscode.extensions.txt'
    $installedExtensions = @(& code --list-extensions)
    Assert-LastExitCode -Action 'Listing VS Code extensions'

    Get-Content -LiteralPath $extensionListPath |
        Where-Object {
            $_ -and
            -not $_.StartsWith('#')
        } |
        ForEach-Object {
            $extension = $_.Trim()

            if ($extension -in $installedExtensions) {
                Write-Host "already installed: VS Code extension $extension"
                return
            }

            Write-Host "install: VS Code extension $extension"
            & code --install-extension $extension
            Assert-LastExitCode `
                -Action "Installing VS Code extension $extension"
        }
}

if (-not $SkipHelium) {
    Install-HeliumPreferences
}

if (-not $SkipLinks) {
    $linkInstaller = Join-Path $repoRoot 'install.windows.ps1'
    $linkParameters = @{}

    if ($NoBackup) {
        $linkParameters.NoBackup = $true
    }

    & $linkInstaller @linkParameters
}

Write-Host ''
Write-Host 'Setup complete. Close and reopen Windows Terminal before using the new PATH and profile.'
Write-Host 'Start only one window manager (GlazeWM, komorebi, or LeopardWM) at a time.'
