#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script supports macOS only." >&2
    exit 1
fi

if ! command -v brew >/dev/null; then
    echo "Homebrew가 필요합니다. README.ghostty.md를 참고해 먼저 설치하세요." >&2
    exit 1
fi

for cask in ghostty omniwm font-lilex-nerd-font; do
    if brew list --cask "$cask" >/dev/null 2>&1; then
        echo "${cask}가 이미 설치되어 있어 건너뜁니다."
    else
        brew install --cask "$cask"
    fi
done

for formula in zoxide lsd zsh-autocomplete starship; do
    if brew list --formula "$formula" >/dev/null 2>&1; then
        echo "${formula}가 이미 설치되어 있어 건너뜁니다."
    else
        brew install "$formula"
    fi
done

backup_dir="$(mktemp -d "$HOME/.dot-file-backup.XXXXXX")"
backup_index=0
backup_file() {
    local target="$1"
    if [[ -e "$target" || -L "$target" ]]; then
        backup_index=$((backup_index + 1))
        mv "$target" "$backup_dir/$backup_index"
        printf '%s\t%s\n' "$backup_index" "$target" >> "$backup_dir/paths.tsv"
    fi
}

copy_file() {
    local source="$1" target="$2"
    if [[ ! -L "$target" ]] && cmp -s "$source" "$target"; then
        return
    fi
    mkdir -p "$(dirname "$target")"
    backup_file "$target"
    cp "$source" "$target"
}

# Ghostty의 다른 기본 설정 파일이 저장소 설정을 덮어쓰지 않도록 백업합니다.
backup_file "$config_dir/ghostty/config.ghostty"
backup_file "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
backup_file "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

for font in "$repo_dir"/fonts/yeomil-mono/*.ttf; do
    copy_file "$font" "$HOME/Library/Fonts/$(basename "$font")"
done
for theme in "$repo_dir"/.config/ghostty/themes/*; do
    copy_file "$theme" "$config_dir/ghostty/themes/$(basename "$theme")"
done
copy_file "$repo_dir/.config/ghostty/config" "$config_dir/ghostty/config"
copy_file "$repo_dir/.config/zsh/.zshrc" "${ZDOTDIR:-$HOME}/.zshrc"
copy_file "$repo_dir/.config/starship.toml" "$config_dir/starship.toml"
copy_file "$repo_dir/.config/omniwm/settings.toml" "$config_dir/omniwm/settings.toml"

if [[ -f "$backup_dir/paths.tsv" ]]; then
    echo "기존 파일 백업: $backup_dir (원래 위치: paths.tsv)"
else
    rmdir "$backup_dir"
fi
echo "macOS 설정 복원 완료. Ghostty와 Omni WM을 실행하세요."
echo "이미 실행 중인 터미널은 Cmd+Shift+,로 설정을 다시 읽고 새 셸을 여세요."
echo "새 Mac에서는 시스템 설정에서 Omni WM의 손쉬운 사용 권한을 허용해야 합니다."
