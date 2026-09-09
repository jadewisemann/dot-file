#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_path="$repo_dir/.config/ghostty/config"
target_path="$HOME/.config/ghostty/config"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script supports macOS only." >&2
    exit 1
fi

if ! command -v brew >/dev/null; then
    echo "Homebrew가 필요합니다. README.ghostty.md를 참고해 먼저 설치하세요." >&2
    exit 1
fi

brew install --cask ghostty font-lilex

mkdir -p "$(dirname "$target_path")"

if [[ -e "$target_path" && ! -L "$target_path" ]]; then
    backup_path="$target_path.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$target_path" "$backup_path"
    echo "기존 설정 백업: $backup_path"
elif [[ -L "$target_path" ]]; then
    rm "$target_path"
fi

ln -s "$source_path" "$target_path"

echo "Ghostty 설정 적용 완료. Ghostty를 완전히 종료한 뒤 다시 실행하세요."
