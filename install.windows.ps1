[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$NoBackup
)

$ErrorActionPreference = 'Stop'

if (
    $PSVersionTable.PSEdition -ne 'Core' -or
    $PSVersionTable.PSVersion.Major -lt 7
) {
    throw 'This installer must be run with PowerShell 7 (pwsh).'
}

$repoRoot = Split-Path -Parent $PSCommandPath
$homeDir = [Environment]::GetFolderPath('UserProfile')
$documentsDir = [Environment]::GetFolderPath('MyDocuments')
$backupRoot = Join-Path `
    $homeDir `
    ".dot-file-backups\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$backupCreated = $false

function Backup-Target {
    param(
        [Parameter(Mandatory)]
        [string]$Target
    )

    if ($NoBackup) {
        return
    }

    $relativePath = [System.IO.Path]::GetRelativePath(
        $homeDir,
        $Target
    )
    $backupTarget = Join-Path $backupRoot $relativePath

    New-ParentDirectory -Path $backupTarget
    Copy-Item `
        -LiteralPath $Target `
        -Destination $backupTarget `
        -Recurse `
        -Force

    $script:backupCreated = $true
    Write-Host "backup: $Target -> $backupTarget"
}

function Assert-SymbolicLinkSupport {
    $testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "dot-file-link-test-$PID"
    $testSource = Join-Path $testRoot 'source.txt'
    $testTarget = Join-Path $testRoot 'target.txt'

    try {
        New-Item `
            -ItemType Directory `
            -Path $testRoot `
            -Force |
            Out-Null

        Set-Content `
            -LiteralPath $testSource `
            -Value 'test'

        New-Item `
            -ItemType SymbolicLink `
            -Path $testTarget `
            -Target $testSource `
            -Force |
            Out-Null
    }
    catch {
        throw @"
Cannot create symbolic links.

Run this script as Administrator or enable Windows Developer Mode.

$($_.Exception.Message)
"@
    }
    finally {
        if (Test-Path -LiteralPath $testRoot) {
            Remove-Item `
                -LiteralPath $testRoot `
                -Recurse `
                -Force
        }
    }
}

function New-ParentDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $parent = Split-Path -Parent $Path

    if (
        $parent -and
        -not (Test-Path -LiteralPath $parent)
    ) {
        New-Item `
            -ItemType Directory `
            -Path $parent `
            -Force |
            Out-Null
    }
}

function Install-Link {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Target
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Source not found: $Source"
    }

    New-ParentDirectory -Path $Target

    if (Test-Path -LiteralPath $Target) {
        $item = Get-Item `
            -LiteralPath $Target `
            -Force

        $alreadyLinked = (
            $item.LinkType -eq 'SymbolicLink' -and
            $item.Target -contains $Source
        )

        if ($alreadyLinked) {
            Write-Host "already linked: $Target -> $Source"
            return
        }

        if (-not $PSCmdlet.ShouldProcess(
            $Target,
            "Replace with symbolic link to $Source"
        )) {
            return
        }

        Backup-Target -Target $Target

        if ($item.PSIsContainer) {
            Remove-Item `
                -LiteralPath $Target `
                -Recurse `
                -Force
        }
        else {
            Remove-Item `
                -LiteralPath $Target `
                -Force
        }

        Write-Host "remove: $Target"
    }

    if (
        -not (Test-Path -LiteralPath $Target) -and
        -not $PSCmdlet.ShouldProcess($Target, "Link to $Source")
    ) {
        return
    }

    New-Item `
        -ItemType SymbolicLink `
        -Path $Target `
        -Target $Source `
        -Force |
        Out-Null

    Write-Host "link: $Target -> $Source"
}

function Add-Link {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Links,

        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Target
    )

    if (Test-Path -LiteralPath $Source) {
        $Links.Add(
            @{
                Source = $Source
                Target = $Target
            }
        )
    }
}

function Add-FileLinks {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Links,

        [Parameter(Mandatory)]
        [string]$SourceRoot,

        [Parameter(Mandatory)]
        [string]$TargetRoot
    )

    if (-not (Test-Path -LiteralPath $SourceRoot)) {
        return
    }

    Get-ChildItem `
        -LiteralPath $SourceRoot `
        -File `
        -Recurse `
        -Force |
        Where-Object {
            $_.Extension -ne '.log'
        } |
        ForEach-Object {
            $relativePath = $_.FullName.Substring(
                $SourceRoot.Length
            ).TrimStart('\', '/')

            Add-Link `
                -Links $Links `
                -Source $_.FullName `
                -Target (Join-Path $TargetRoot $relativePath)
        }
}

$links = [System.Collections.Generic.List[object]]::new()

# ~/.config
Add-FileLinks `
    -Links $links `
    -SourceRoot (Join-Path $repoRoot '.config') `
    -TargetRoot (Join-Path $homeDir '.config')

# ~/AppData
Add-FileLinks `
    -Links $links `
    -SourceRoot (Join-Path $repoRoot 'AppData') `
    -TargetRoot (Join-Path $homeDir 'AppData')

# ~/.glzr
Add-FileLinks `
    -Links $links `
    -SourceRoot (Join-Path $repoRoot '.glzr') `
    -TargetRoot (Join-Path $homeDir '.glzr')

# Repository root configuration files
foreach ($fileName in @(
    'applications.json'
    'komorebi.bar.json'
    'komorebi.json'
)) {
    Add-Link `
        -Links $links `
        -Source (Join-Path $repoRoot $fileName) `
        -Target (Join-Path $homeDir $fileName)
}

# PowerShell 7 profile
$powerShellProfile = Join-Path `
    $documentsDir `
    'PowerShell\Microsoft.PowerShell_profile.ps1'

Add-Link `
    -Links $links `
    -Source (
        Join-Path `
            $repoRoot `
            'PowerShell\Microsoft.PowerShell_profile.ps1'
    ) `
    -Target $powerShellProfile

Assert-SymbolicLinkSupport

foreach ($link in $links) {
    Install-Link @link
}

if ($backupCreated) {
    Write-Host "backup root: $backupRoot"
}
