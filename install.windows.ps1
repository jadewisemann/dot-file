[CmdletBinding(SupportsShouldProcess = $true)]
param()

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
        [string]$Target,

        [ValidateSet('SymbolicLink', 'Junction')]
        [string]$LinkType
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Source not found: $Source"
    }

    $sourceItem = Get-Item `
        -LiteralPath $Source `
        -Force

    if (-not $LinkType) {
        $LinkType = if ($sourceItem.PSIsContainer) {
            'Junction'
        }
        else {
            'SymbolicLink'
        }
    }

    New-ParentDirectory -Path $Target

    if (Test-Path -LiteralPath $Target) {
        $item = Get-Item `
            -LiteralPath $Target `
            -Force

        $alreadyLinked = (
            $item.LinkType -eq $LinkType -and
            $item.Target -contains $Source
        )

        if ($alreadyLinked) {
            Write-Host "already linked: $Target -> $Source"
            return
        }

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

    if ($PSCmdlet.ShouldProcess($Target, "Link to $Source")) {
        New-Item `
            -ItemType $LinkType `
            -Path $Target `
            -Target $Source `
            -Force |
            Out-Null

        Write-Host "link: $Target -> $Source"
    }
}

function Add-Link {
    param(
        [Parameter(Mandatory)]
        [System.Collections.Generic.List[object]]$Links,

        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Target,

        [ValidateSet('SymbolicLink', 'Junction')]
        [string]$LinkType
    )

    if (Test-Path -LiteralPath $Source) {
        $link = @{
            Source = $Source
            Target = $Target
        }

        if ($LinkType) {
            $link.LinkType = $LinkType
        }

        $Links.Add($link)
    }
}

function Add-FileLinks {
    param(
        [Parameter(Mandatory)]
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
            $_.Extension -ne '.log' -and
            $_.FullName -notlike (
                Join-Path `
                    $repoRoot `
                    'AppData\Roaming\leopardwm\config\*'
            )
        } |
        ForEach-Object {
            $relativePath = $_.FullName
                .Substring($SourceRoot.Length)
                .TrimStart('\', '/')

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

# LeopardWM config directory: keep the repository as the source of truth.
Add-Link `
    -Links $links `
    -Source (Join-Path $repoRoot 'AppData\Roaming\leopardwm\config') `
    -Target (Join-Path $homeDir 'AppData\Roaming\leopardwm\config') `
    -LinkType 'SymbolicLink'

# Repository root files and directories
Get-ChildItem `
    -LiteralPath $repoRoot `
    -Force |
    Where-Object {
        $_.Name -notin @(
            '.config'
            'AppData'
            'PowerShell'
            'README.md'
            'install.windows.ps1'
        )
    } |
    ForEach-Object {
        if ($_.PSIsContainer) {
            Add-FileLinks `
                -Links $links `
                -SourceRoot $_.FullName `
                -TargetRoot (Join-Path $homeDir $_.Name)
        }
        else {
            Add-Link `
                -Links $links `
                -Source $_.FullName `
                -Target (Join-Path $homeDir $_.Name)
        }
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
