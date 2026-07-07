# 1. lsd 관련 함수 정의
function l { lsd -l $args }
function la { lsd -a $args }
function lla { lsd -la $args }
function lt { lsd --tree $args }

# 2. ls 명령어를 lsd로 대체
if (Get-Command lsd -ErrorAction SilentlyContinue) {
    Set-Alias -Name ls -Value lsd -Option AllScope -Force
} else {
    Write-Host "경고: lsd가 설치되어 있지 않습니다." -ForegroundColor Yellow
}

# 3. zoxide 초기화
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# ==========================================
# 4. fzf (PSFzf) 및 PSReadLine 최적화 설정
# ==========================================
Import-Module PSReadLine
Import-Module PSFzf
Import-Module CompletionPredictor


$env:FZF_DEFAULT_OPTS = "--bind 'double-click:accept' --height 40% --layout=reverse"

# [핵심 1] 단축 명령어(Alias) 활성화
# fkill(프로세스 종료), fe(파일 에디터로 열기), fd(폴더 퍼지 검색 후 이동), fh(히스토리 실행)
Set-PsFzfOption -EnableAliasFuzzyKillProcess -EnableAliasFuzzyEdit -EnableAliasFuzzySetLocation -EnableAliasFuzzyHistory

# [핵심 2] fzf 핵심 단축키 바인딩
# - Ctrl+t : 파일/폴더 경로 퍼지 검색 및 자동 완성
# - Ctrl+r : 명령어 기록(History) 역방향 퍼지 검색
# (Alt+c 와 Alt+a 는 PSFzf 모듈 로드 시 기본 할당되므로 별도 옵션 지정 불필요)
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
# Set-PSReadLineOption -PredictionSource None
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -Colors @{
    InlinePrediction = "$([char]0x1b)[38;5;238m" # 제안 텍스트를 진한 회색으로
}
