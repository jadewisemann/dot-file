[CmdletBinding(SupportsShouldProcess = $true)]
param()

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSCommandPath
$homeDir = [Environment]::GetFolderPath('UserProfile')

function Assert-SymbolicLinkSupport {
    $testRoot = Join-Path ([System.IO.Path]::GetTempPath()) "dot-file-link-test-$PID"
    $testSource = Join-Path $testRoot 'source.txt'
    $testTarget = Join-Path $testRoot 'target.txt'

    try {
        New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
        Set-Content -LiteralPath $testSource -Value 'test'
        New-Item -ItemType SymbolicLink -Path $testTarget -Target $testSource -Force | Out-Null
    } catch {
        throw "Cannot create symbolic links. Run this script as Administrator or enable Windows Developer Mode. $($_.Exception.Message)"
    } finally {
        if (Test-Path -LiteralPath $testRoot) {
            Remove-Item -LiteralPath $testRoot -Recurse -Force
        }
    }
}

function New-ParentDirectory {
    param([string]$Path)

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
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
        $item = Get-Item -LiteralPath $Target -Force
        $alreadyLinked = $item.LinkType -eq 'SymbolicLink' -and $item.Target -eq $Source

        if ($alreadyLinked) {
            Write-Host "already linked: $Target -> $Source"
            return
        }

        if ($item.PSIsContainer) {
            Remove-Item -LiteralPath $Target -Recurse -Force
        } else {
            Remove-Item -LiteralPath $Target -Force
        }
        Write-Host "remove: $Target"
    }

    if ($PSCmdlet.ShouldProcess($Target, "Link to $Source")) {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
        Write-Host "link: $Target -> $Source"
    }
}

function Add-Link {
    param(
        [System.Collections.Generic.List[object]]$Links,
        [string]$Source,
        [string]$Target
    )

    if (Test-Path -LiteralPath $Source) {
        $Links.Add(@{
            Source = $Source
            Target = $Target
        })
    }
}

function Add-FileLinks {
    param(
        [System.Collections.Generic.List[object]]$Links,
        [string]$SourceRoot,
        [string]$TargetRoot
    )

    if (-not (Test-Path -LiteralPath $SourceRoot)) {
        return
    }

    Get-ChildItem -LiteralPath $SourceRoot -File -Recurse -Force |
        Where-Object { $_.Extension -ne '.log' } |
        ForEach-Object {
            $relativePath = $_.FullName.Substring($SourceRoot.Length).TrimStart('\', '/')
            Add-Link -Links $Links -Source $_.FullName -Target (Join-Path $TargetRoot $relativePath)
        }
}

$links = [System.Collections.Generic.List[object]]::new()

Add-FileLinks `
    -Links $links `
    -SourceRoot (Join-Path $repoRoot '.config') `
    -TargetRoot (Join-Path $homeDir '.config')

Add-FileLinks `
    -Links $links `
    -SourceRoot (Join-Path $repoRoot 'AppData') `
    -TargetRoot (Join-Path $homeDir 'AppData')

Get-ChildItem -LiteralPath $repoRoot -Force | Where-Object {
    $_.Name -notin @('.config', 'AppData', 'PowerShell', 'README.md', 'install.windows.ps1')
} | ForEach-Object {
    if ($_.PSIsContainer) {
        Add-FileLinks -Links $links -SourceRoot $_.FullName -TargetRoot (Join-Path $homeDir $_.Name)
    } else {
        Add-Link -Links $links -Source $_.FullName -Target (Join-Path $homeDir $_.Name)
    }
}

Add-Link -Links $links `
    -Source (Join-Path $repoRoot 'PowerShell\Microsoft.PowerShell_profile.ps1') `
    -Target $PROFILE.CurrentUserCurrentHost

Assert-SymbolicLinkSupport

foreach ($link in $links) {
    Install-Link @link
}
