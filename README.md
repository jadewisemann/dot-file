# Windows dotfiles

Windows 11에서 PowerShell, Windows Terminal, YASB와 세 가지 타일링 창 관리자의 설정을 한 번에 준비하는 저장소입니다. 설치 스크립트는 필요한 프로그램과 PowerShell 모듈, Nerd Font를 설치한 뒤 저장소의 설정 파일을 사용자 홈에 심볼릭 링크로 연결합니다.

## 빠른 시작

필수 조건은 인터넷 연결과 Windows의 `winget`(Microsoft Store의 **App Installer**)입니다. 심볼릭 링크를 만들려면 **Windows 개발자 모드**를 켜거나 관리자 권한 터미널에서 실행해야 합니다.

명령 프롬프트에서 다음을 실행합니다. PowerShell 7이 없으면 배치 파일이 먼저 설치합니다.

```bat
setup.windows.cmd
```

PowerShell 7이 이미 있으면 다음 명령을 직접 실행해도 됩니다.

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\setup.windows.ps1
```

설치 후 Windows Terminal을 완전히 닫았다가 다시 여세요. 새 `PATH`와 PowerShell 프로필은 새 터미널부터 적용됩니다.

## 설치되는 항목

| 용도 | 패키지 | winget ID |
| --- | --- | --- |
| 편집기 | Visual Studio Code | `Microsoft.VisualStudioCode` |
| 런타임 | Node.js | `OpenJS.NodeJS` |
| 터미널 | Windows Terminal | `Microsoft.WindowsTerminal` |
| 셸 | PowerShell 7 | `Microsoft.PowerShell` |
| 런처 | Flow Launcher | `Flow-Launcher.Flow-Launcher` |
| 창 관리자 | GlazeWM | `glzr-io.glazewm` |
| 창 관리자 | komorebi | `LGUG2Z.komorebi` |
| 창 관리자 | LeopardWM | `jcardama.LeopardWM` |
| 상태 표시줄 | YASB | `AmN.yasb` |
| 프롬프트 | Starship | `Starship.Starship` |
| 프롬프트/폰트 도구 | Oh My Posh | `JanDeDobbeleer.OhMyPosh` |
| CLI | lsd | `lsd-rs.lsd` |
| CLI | fzf | `junegunn.fzf` |
| CLI | zoxide | `ajeetdsouza.zoxide` |

PowerShell 모듈은 현재 사용자 범위에 설치합니다.

- `PSFzf` 2.7.10
- `CompletionPredictor`

터미널, YASB, VS Code에서 사용하는 Lilex와 JetBrainsMono Nerd Font도 Oh My Posh를 통해 설치합니다. Windows에 등록되는 실제 글꼴 이름인 `Lilex Nerd Font`, `JetBrainsMono NFM`을 설정에 사용합니다. VS Code 설정의 Sarasa Fixed K와 Interop은 fallback 글꼴이며 자동 설치 대상에는 포함하지 않습니다.

VS Code Settings Sync에서 가져온 사용자 설정, 키 바인딩, Python snippet과 확장 목록도 재현합니다. 설정 파일은 `%APPDATA%\Code\User`에 링크하고 `vscode.extensions.txt`의 확장을 VS Code CLI로 설치합니다.

Helium은 Chromium 프로필 전체를 복사하지 않습니다. `Helium\preferences.portable.json`의 UI·탭·언어·맞춤법 설정만 기존 Preferences에 병합하며, 로그인·쿠키·암호화 키·기기 식별 정보는 저장소에서 제외합니다.

## 설치 스크립트 옵션

`setup.windows.cmd` 뒤나 `setup.windows.ps1` 뒤에 다음 옵션을 붙일 수 있습니다.

| 옵션 | 설명 |
| --- | --- |
| `-Upgrade` | 이미 설치된 winget 패키지도 가능한 최신 버전으로 업그레이드 |
| `-SkipPackages` | winget 패키지 설치 생략 |
| `-SkipModules` | PowerShell 모듈 설치 생략 |
| `-SkipFonts` | Nerd Font 설치 생략 |
| `-SkipVscodeExtensions` | VS Code 확장 설치 생략 |
| `-SkipHelium` | Helium 이식 가능 설정 병합 생략 |
| `-SkipLinks` | 설정 파일 링크 적용 생략 |
| `-NoBackup` | 기존 대상 설정의 백업 생략 |

예를 들어 프로그램은 건드리지 않고 설정 링크만 다시 적용하려면 다음과 같이 실행합니다.

```powershell
.\setup.windows.cmd -SkipPackages -SkipModules -SkipFonts -SkipVscodeExtensions -SkipHelium
```

## 설정 파일 적용 방식

`install.windows.ps1`은 아래 경로를 파일 단위 심볼릭 링크로 연결합니다. 실행 중인 앱이 잡고 있는 `.log` 파일과 저장소의 `.git` 디렉터리는 제외합니다.

| 저장소 경로 | 대상 경로 |
| --- | --- |
| `.config\*` | `%USERPROFILE%\.config\*` |
| `.glzr\*` | `%USERPROFILE%\.glzr\*` |
| `komorebi*.json`, `applications.json` | `%USERPROFILE%\...` |
| `AppData\...` | `%USERPROFILE%\AppData\...` |
| `PowerShell\Microsoft.PowerShell_profile.ps1` | 문서 폴더의 `PowerShell\Microsoft.PowerShell_profile.ps1` |

대상 파일이 이미 있고 저장소를 가리키는 링크가 아니면 먼저 `%USERPROFILE%\.dot-file-backups\yyyyMMdd-HHmmss` 아래에 복사한 뒤 교체합니다. 이미 올바르게 연결된 파일은 건너뛰므로 반복 실행해도 안전합니다.

Helium 설정을 적용할 때는 Helium을 먼저 완전히 종료해야 합니다. 실행 중이면 해당 단계만 건너뛰고 경고를 표시합니다.

설정 파일 링크만 적용하려면 PowerShell 7에서 실행합니다.

```powershell
.\install.windows.ps1
```

실제 변경 없이 대상만 확인하려면 다음을 사용합니다.

```powershell
.\install.windows.ps1 -WhatIf
```

## 사용 시 주의사항

GlazeWM, komorebi, LeopardWM은 서로 대체 관계인 창 관리자입니다. 모두 설치되지만 동시에 자동 실행되지는 않으며, 사용할 프로그램 하나만 시작하는 것을 권장합니다.

- komorebi: `komorebic start --whkd`
- LeopardWM 설정 다시 읽기: `lwm reload`
- GlazeWM: 시작 메뉴에서 실행하거나 원하는 시작 프로그램 방식으로 등록

YASB 설정은 komorebi 연동을 기본으로 사용합니다. 창 관리자를 바꾸면 `.config\yasb\config.yaml`의 workspace widget과 시작/종료 명령도 함께 조정하세요.
