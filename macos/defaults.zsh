#!/usr/bin/env zsh

configure_macos_defaults() {
	echo "${BGREEN}Configuring macOS settings...${NC}"

	# --- Keyboard ---
	# Disable Caps Lock (No Action) for all keyboards
	# 0x700000039 = HID Caps Lock key; -1 = No Action
	local caps_lock=30064771129
	defaults write -g "com.apple.keyboard.modifiermapping.0-0-0" \
		-array "<dict><key>HIDKeyboardModifierMappingSrc</key><integer>${caps_lock}</integer><key>HIDKeyboardModifierMappingDst</key><integer>-1</integer></dict>"

	# --- Trackpad ---
	# Tap to click
	defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

	# Three-finger drag (also requires Accessibility + currentHost write)
	defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
	defaults -currentHost write NSGlobalDomain com.apple.trackpad.threeFingerDragGesture -bool true

	# Disable three-finger swipe gestures (freed up for drag)
	defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 0
	defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 0
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture -int 0

	# Two-finger right-click
	defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true

	# Pointer / scroll scaling
	defaults write -g com.apple.trackpad.scaling -float 1
	defaults write -g com.apple.mouse.scaling -float 1.5
	defaults write -g com.apple.scrollwheel.scaling -float 0.5

	# --- Dock ---
	defaults write com.apple.dock autohide -bool true
	defaults write com.apple.dock show-recents -bool false
	defaults write com.apple.dock tilesize -int 49

	# Bottom-left hot corner: Lock Screen (13), triggered with ⌘ held
	defaults write com.apple.dock wvous-bl-corner -int 13
	defaults write com.apple.dock wvous-bl-modifier -int 1048576

	dockutil --remove all --no-restart
	dockutil --add "/Applications/Spark Desktop.app"          --no-restart
	dockutil --add "/Applications/WhatsApp.app"               --no-restart
	dockutil --add "/Applications/Slack.app"                  --no-restart
	dockutil --add "/Applications/Google Chrome.app"          --no-restart
	dockutil --add "/Applications/Zen.app"                    --no-restart
	dockutil --add "/Applications/Firefox.app"                --no-restart
	dockutil --add "/Applications/Safari.app"                 --no-restart
	dockutil --add "/Applications/Obsidian.app"               --no-restart
	dockutil --add "/Applications/Notion.app"                 --no-restart
	dockutil --add "/Applications/Visual Studio Code.app"     --no-restart
	dockutil --add "/Applications/Antigravity.app"            --no-restart
	dockutil --add "/Applications/GitHub Desktop.app"         --no-restart
	dockutil --add "/Applications/Ghostty.app"                --no-restart
	dockutil --add "/Applications/Spotify.app"                --no-restart
	dockutil --add "/System/Applications/System Settings.app" --no-restart
	dockutil --add "$HOME/Downloads" --view list --display folder
	killall Dock

	# --- Apps ---
	# Stats - menu bar system monitor
	defaults import eu.exelban.Stats "$(pwd)/stats-menu/Stats.plist"

	# Enable press and hold for special characters
	defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
	defaults write com.google.antigravity ApplePressAndHoldEnabled -bool false

	# --- Accessibility ---
	# Reduce motion when switching desktops
	sudo defaults write com.apple.universalaccess reduceMotion -bool true

	echo "${GREEN}macOS settings configured${NC}"
}
