# 새로 설치된 앱 경로가 현재 프로세스에 아직 반영되지 않은 경우 보완합니다.
$extraCommandPaths = @()
$extraCommandPaths += (
    [Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';'
)
$extraCommandPaths += (
    [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
)
$extraCommandPaths += @(
    (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links')
    (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps')
)
$currentPathEntries = $env:Path -split ';'

foreach ($commandPath in ($extraCommandPaths | Select-Object -Unique)) {
    $commandPath = [Environment]::ExpandEnvironmentVariables(
        $commandPath
    )

    if (
        $commandPath -and
        (Test-Path -LiteralPath $commandPath) -and
        $commandPath -notin $currentPathEntries
    ) {
        $env:Path = "$env:Path;$commandPath"
    }
}

# lsd
function l { lsd -l $args }
function la { lsd -a $args }
function lla { lsd -la $args }
function lt { lsd --tree $args }

if (Get-Command lsd -ErrorAction SilentlyContinue) {
    Set-Alias -Name ls -Value lsd -Option AllScope -Force
}

# zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# fzf, PSFzf, CompletionPredictor, PSReadLine
Import-Module PSReadLine -ErrorAction SilentlyContinue

if (Get-Command fzf -ErrorAction SilentlyContinue) {
    Import-Module PSFzf -ErrorAction SilentlyContinue
}

Import-Module CompletionPredictor -ErrorAction SilentlyContinue

$env:FZF_DEFAULT_OPTS = "--bind 'double-click:accept' --height 40% --layout=reverse"

if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
    Set-PsFzfOption `
        -EnableAliasFuzzyKillProcess `
        -EnableAliasFuzzyEdit `
        -EnableAliasFuzzySetLocation `
        -EnableAliasFuzzyHistory
    Set-PsFzfOption `
        -PSReadlineChordProvider 'Ctrl+t' `
        -PSReadlineChordReverseHistory 'Ctrl+r'
}

if (
    (Get-Module PSReadLine) -and
    $Host.Name -eq 'ConsoleHost' -and
    -not [Console]::IsOutputRedirected
) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineOption -Colors @{
        InlinePrediction = "$([char]0x1b)[38;5;238m"
    }
}

# starship
if (
    (Get-Command starship -ErrorAction SilentlyContinue) -and
    $env:TERM -ne 'dumb' -and
    -not [Console]::IsOutputRedirected
) {
    Invoke-Expression (&starship init powershell)
}
