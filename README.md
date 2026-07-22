# dot file

## winget

- vscode: 'winget install Microsoft.VisualStudioCode'
- node js: 'winget install -e --id OpenJS.NodeJS'
- glaze wm: `winget install GlazeWM`
- leopard wm: `winget install jcardama.LeopardWM`
- yasb: `winget install AmN.yasb`
- flow launcher: 'winget install "Flow Launcher'
- windows terminal: 'winget install --id Microsoft.WindowsTerminal -e'
- power shell 7:  
  - 'winget install --id Microsoft.PowerShell --source winget'
  - 'winget search --id Microsoft.PowerShell --exact'
- git: `winget install --id Git.Git -e --source winget `
- oh my posh: 'winget install oh-my-posh'
- lsd: 'winget install --id lsd-rs.lsd'
- fzf: 'winget install fzf'
- zoxide: 'winget install ajeetdsouza.zoxide'
- powershell-modules
  - PSFzf: `Install-Module -Name PSFzf -RequiredVersion 2.7.10`
  - CompletionPrediction: `Install-Module -Name CompletionPredictor`

- [vs code](https://code.visualstudio.com/)

## asset

- font
  - lilex
  - Sarasa Fixed K
  - interop


## Windows setup

저장소 구조는 Windows 홈 디렉터리 기준 대상 경로를 그대로 따릅니다.

| Source | Target |
| --- | --- |
| `.config\*` files | `%USERPROFILE%\.config\*` |
| `.glzr` files | `%USERPROFILE%\.glzr\*` |
| `komorebi*.json`, `applications.json` | `%USERPROFILE%\...` |
| `AppData\...` files | `%USERPROFILE%\AppData\...` |
| `AppData\Roaming\leopardwm\config\config.toml` | `%APPDATA%\leopardwm\config\config.toml` |

아래 명령은 위 대상 파일과 PowerShell 프로필을 모두 심볼릭 링크로 연결합니다.

```powershell
.\install.windows.ps1
```

이미 대상 파일이 있으면 제거하고 저장소 파일을 가리키는 심볼릭 링크로 다시 만듭니다. 실행 중인 앱이 잡고 있을 수 있는 로그 파일은 링크 대상에서 제외합니다.

LeopardWM 설정을 바꾼 뒤에는 `lwm reload`로 실행 중인 프로세스에 반영할 수 있습니다.
