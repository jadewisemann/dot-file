
# ============================================================

# macOS Personal Tweaks

# ============================================================

# ─────────────────────────────────────────────

# Dock

# ─────────────────────────────────────────────

defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.7
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock static-only -bool true

# ─────────────────────────────────────────────

# Keyboard

# ─────────────────────────────────────────────

defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 10
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# ─────────────────────────────────────────────

# Finder

# ─────────────────────────────────────────────

defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# ─────────────────────────────────────────────

# External / Network drives

# ─────────────────────────────────────────────

defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# ─────────────────────────────────────────────

# Library

# ─────────────────────────────────────────────

chflags nohidden ~/Library

# ─────────────────────────────────────────────

# Reload UI

# ─────────────────────────────────────────────

killall Dock
killall Finder
