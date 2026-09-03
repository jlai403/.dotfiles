#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Create new Zen Window
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ./zen.png 

# Documentation:
# @raycast.description Creates a new Zen window

tell application "Zen"
	activate
end tell
repeat while not application "Zen" is frontmost
	delay 0.1
end repeat
tell application "System Events"
	keystroke "n" using {command down}
	delay 0.1
end tell


