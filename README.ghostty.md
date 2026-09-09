# Ghostty 환경 복원

새로운 Apple Silicon Mac에서 현재 Ghostty 사용성을 복원하는 가이드입니다. 현재 확인된 구성은 다음과 같습니다.

- Ghostty 1.3.1
- Lilex 글꼴, 18pt
- `TokyoNight Day` 테마
- 전역 `Option+/` Quick Terminal
- 화면 중앙, 화면 크기의 66% × 66%
- Quick Terminal 애니메이션 없음
- 포커스를 잃어도 자동으로 숨기지 않음

버전은 현재 환경의 기록이며 복원할 때는 Homebrew가 제공하는 최신 호환 버전을 설치합니다.

## 자동 복원

Homebrew가 없다면 먼저 설치합니다.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

저장소를 받은 뒤 스크립트를 실행합니다.

```bash
git clone https://github.com/jadewisemann/dot-file.git ~/dot-file
cd ~/dot-file
chmod +x setup.ghostty.sh
./setup.ghostty.sh
```

스크립트가 설치하는 프로그램은 Ghostty와 Lilex 글꼴뿐입니다. 기존 `~/.config/ghostty/config`는 날짜가 붙은 파일로 백업하고 저장소의 설정 파일을 심볼릭 링크합니다.

## 수동 적용

```bash
brew install --cask ghostty font-lilex
mkdir -p ~/.config/ghostty
ln -s ~/dot-file/.config/ghostty/config ~/.config/ghostty/config
```

기존 설정 파일이 있으면 `ln` 명령 전에 다른 이름으로 백업해야 합니다.

설정 원본은 `.config/ghostty/config`, 실제 적용 위치는 `~/.config/ghostty/config`입니다.

## 전역 Quick Terminal 권한

`Option+/`가 동작하지 않으면 **시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용**에서 Ghostty를 허용한 뒤 Ghostty를 완전히 종료하고 다시 실행합니다.

다른 앱이 같은 전역 단축키를 사용하면 충돌할 수 있습니다. 이 환경에서는 OmniWM 단축키와 겹치지 않게 구성되어 있습니다.
