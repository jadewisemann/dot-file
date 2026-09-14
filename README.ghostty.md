# macOS Ghostty · Omni WM 환경 복원

이 저장소의 `setup.ghostty.sh` 하나로 Ghostty, Omni WM, 공용 테마, 폰트와 터미널용 zsh 설정을 복원합니다. 스크립트 이름은 기존 사용법과의 호환성을 위해 유지합니다.

## 자동 복원

Apple Silicon Mac과 인터넷 연결이 필요합니다. Homebrew가 없다면 [공식 설치 안내](https://brew.sh/)에 따라 먼저 설치합니다.

```bash
git clone https://github.com/jadewisemann/dot-file.git ~/dot-file
cd ~/dot-file
bash setup.ghostty.sh
```

스크립트는 Homebrew로 Ghostty, Omni WM, Lilex Nerd Font와 `lsd`, `zoxide`, `zsh-autocomplete`, Starship을 설치합니다. 실제 터미널 폰트인 Yeomil Mono는 저장소에 포함된 TTF를 설치합니다. 기존 복원 스크립트에서 설치하던 Lilex Nerd Font도 유지합니다.

기존 파일은 `~/.dot-file-backup.XXXXXX/`에 이동하고 저장소의 파일을 복사합니다. 백업 디렉터리의 `paths.tsv`에 백업 번호와 원래 경로가 기록됩니다. 동일한 파일은 건너뜁니다. Ghostty의 다른 기본 설정 파일(`config.ghostty`, Application Support 아래 `config`와 `config.ghostty`)도 백업하여 테마나 폰트가 덮어써지는 것을 방지합니다.

복원 후 Ghostty와 Omni WM을 실행하고, 새 Mac에서는 시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 Omni WM을 허용하세요. macOS 권한은 저장소에서 자동 복원할 수 없습니다. 기존 앱이 실행 중이면 터미널에서 `Cmd+Shift+,`로 설정을 다시 읽고 새 셸을 여세요. Omni WM 자체의 TOML 설정은 저장 시 자동으로 다시 읽습니다.

## 보관되는 설정

| 저장소 | 적용 위치 | 내용 |
| --- | --- | --- |
| `.config/ghostty/config` | `~/.config/ghostty/config` | Yeomil Mono, 14pt, TokyoNight Day |
| `.config/ghostty/themes/TokyoNight Day` | `~/.config/ghostty/themes/TokyoNight Day` | 두 터미널이 함께 읽는 색상 팔레트 |
| `fonts/yeomil-mono/*.ttf` | `~/Library/Fonts/` | 현재 사용하는 Regular·Bold·Light 폰트 |
| `.config/omniwm/settings.toml` | `~/.config/omniwm/settings.toml` | 창 배치, workspace, Quake, 단축키 |
| `.config/zsh/.zshrc` | `~/.zshrc` | lsd alias, zoxide, 자동 완성, Starship 초기화 |
| `.config/starship.toml` | `~/.config/starship.toml` | 프롬프트 |

`XDG_CONFIG_HOME`을 지정했다면 `~/.config` 대신 해당 경로를 사용합니다. `ZDOTDIR`을 지정했다면 그곳에 `.zshrc`를 복원합니다. 복원은 복사 방식이므로 이후 앱에서 바꾼 설정은 저장소로 자동 동기화되지 않습니다.

## Quake 터미널

- `Alt(Option)+Y`: Quake 터미널 표시·숨기기
- `Alt+Shift+Y`: 할당 해제
- scratchpad 1의 표시·할당 단축키: 모두 해제
- 화면 중앙, 너비·높이 각 50%, 불투명도 100%, 자동 숨김 꺼짐

Quake는 libghostty 기반 Omni WM 내장 터미널입니다. Ghostty 설정을 읽지만 테마 이름만으로 Ghostty.app 내부의 테마 파일을 찾지 못할 수 있어, `TokyoNight Day` 팔레트를 공용 사용자 테마 디렉터리에 함께 복원합니다. Quake의 위치·크기·투명도·블러는 Omni WM 설정이 제어합니다.

## 기록 범위와 버전

2026-09-14 기준 Omni WM 0.6.9의 schemaVersion 3 설정과 현재 설치된 테마·폰트를 보관했습니다. 기존 Ghostty 기록 버전은 1.3.1이며, 앱과 CLI는 복원 시 Homebrew의 최신 호환 버전을 설치합니다. 바이너리 버전까지 고정한 오프라인 복원은 아닙니다. 모니터·앱 규칙은 새 Mac의 구성에 맞춰 조정할 수 있습니다.

현재 전역 Ghostty 설정의 `.font-size` 오타는 저장소에서 유효한 `font-size = 14`로 수정했습니다. zsh는 저장소에서 관리하던 터미널 구성을 복원하며, 별도 개발 도구인 Grok·NVM의 설치 및 전역 프로필 추가분은 포함하지 않습니다.

Yeomil Mono 원본: https://github.com/taevel02/yeomil-mono — 재배포 라이선스는 `fonts/yeomil-mono/LICENSE`에 포함했습니다. 테마는 설치된 Ghostty의 `TokyoNight Day` 팔레트 사본입니다.
