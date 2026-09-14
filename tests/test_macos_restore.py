"""Run with python3 tests/test_macos_restore.py; never changes the real home or Homebrew."""
import os
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    checkout = root / 'checkout'
    checkout.mkdir()
    for name in ('.config', 'fonts'):
        (checkout / name).symlink_to(repo / name, target_is_directory=True)
    # Redirect only the script's HOME references without changing the process HOME.
    script = checkout / 'setup.ghostty.sh'
    script.write_text((repo / script.name).read_text().replace('$HOME', '$restore_test_home'))
    test_home = root / 'home'
    test_home.mkdir()
    bin_dir = root / 'bin'
    bin_dir.mkdir()
    for name, body in {
        'uname': 'echo Darwin',
        'brew': 'if [ "$1" = list ]; then exit 1; fi\n[ "$1" = install ]',
    }.items():
        stub = bin_dir / name
        stub.write_text('#!/bin/sh\n' + body + '\n')
        stub.chmod(0o755)
    env = dict(os.environ, restore_test_home=str(test_home),
               PATH=str(bin_dir) + ':' + os.environ['PATH'])
    env.pop('XDG_CONFIG_HOME', None)
    env.pop('ZDOTDIR', None)
    config = test_home / '.config'
    target = config / 'ghostty/config'
    target.parent.mkdir(parents=True)
    target.write_text('old config\n')
    alternate = config / 'ghostty/config.ghostty'
    alternate.write_text('theme = old\n')
    original = root / 'original-zsh'
    original.write_text('old zsh\n')
    (test_home / '.zshrc').symlink_to(original)

    def run():
        subprocess.run(['bash', str(script)], env=env, check=True, capture_output=True)

    run()
    for relative in ['ghostty/config', 'ghostty/themes/TokyoNight Day',
                     'omniwm/settings.toml', 'starship.toml']:
        assert (config / relative).read_bytes() == (repo / '.config' / relative).read_bytes()
    assert (test_home / '.zshrc').read_bytes() == (repo / '.config/zsh/.zshrc').read_bytes()
    assert not (test_home / '.zshrc').is_symlink()
    assert original.read_text() == 'old zsh\n'
    assert not alternate.exists()
    for font in (repo / 'fonts/yeomil-mono').glob('*.ttf'):
        assert (test_home / 'Library/Fonts' / font.name).read_bytes() == font.read_bytes()
    backups = list(test_home.glob('.dot-file-backup.*'))
    assert len(backups) == 1
    assert 'old config\n' in [p.read_text() for p in backups[0].iterdir() if p.is_file()]
    run()
    assert list(test_home.glob('.dot-file-backup.*')) == backups

    env['XDG_CONFIG_HOME'] = str(test_home / 'custom-config')
    env['ZDOTDIR'] = str(test_home / 'custom-zsh')
    run()
    assert (Path(env['XDG_CONFIG_HOME']) / 'omniwm/settings.toml').exists()
    assert (Path(env['ZDOTDIR']) / '.zshrc').exists()
print('PASS: restore, backups, symlinks, repeated runs, XDG_CONFIG_HOME and ZDOTDIR')
