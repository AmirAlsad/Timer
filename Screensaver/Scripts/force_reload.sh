#!/bin/bash

echo "🔄 Force reloading Countdown Screensaver..."
echo

# Kill any existing screensaver processes
echo "1. Killing existing screensaver processes..."
sudo pkill -f "CountdownScreensaver"
sudo pkill -f "ScreenSaverEngine"
killall -KILL ScreenSaverEngine 2>/dev/null || true

# Remove from cache directories
echo "2. Clearing screensaver caches..."
rm -rf ~/Library/Caches/com.apple.ScreenSaver.Engine.legacyScreenSaver
rm -rf /tmp/com.apple.ScreenSaver*
sudo rm -rf /var/folders/*/T/com.apple.ScreenSaver* 2>/dev/null || true

# Force quit System Preferences/Settings if running
echo "3. Restarting System Settings..."
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true
killall "System Preferences" 2>/dev/null || true
killall "System Settings" 2>/dev/null || true

# Reinstall the screensaver
echo "4. Reinstalling screensaver..."
make clean
make install

# Clear more caches
echo "5. Clearing additional caches..."
sudo rm -rf /Library/Caches/com.apple.ScreenSaver*
sudo rm -rf /System/Library/Caches/com.apple.ScreenSaver* 2>/dev/null || true

# Reset screensaver preferences
echo "6. Resetting screensaver preferences..."
defaults delete com.apple.screensaver 2>/dev/null || true

echo
echo "✅ Cache clearing complete!"
echo
echo "Now try these steps:"
echo "1. Open System Settings → Screen Saver"
echo "2. Select a different screensaver first"
echo "3. Then select 'Countdown Screensaver'"
echo "4. The preview should now show your timers"
echo

# Optionally open System Settings
read -p "Open System Settings now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension"
fi
