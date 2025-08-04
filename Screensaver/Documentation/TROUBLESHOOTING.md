# Countdown Screensaver Troubleshooting

## Fixes Applied

### 1. Black Screen Without Timers
**Problem**: Screensavers run in a sandboxed environment and cannot access shared UserDefaults suites.

**Solution**: Modified the screensaver to read directly from the app's preferences plist file at:
`~/Library/Preferences/com.countdownwallpaper.app.plist`

The screensaver now:
- Reads timer data directly from the preferences file
- Reloads timers every 10 seconds to catch updates
- Prints debug information about loaded timers

### 2. "make test" Command
**Problem**: The bundle identifier for System Preferences changed in recent macOS versions.

**Solution**: Updated to use the new System Settings URL:
`x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension`

### 3. Configure Button
**Problem**: URL schemes don't work reliably from screensavers.

**Solution**: The configure button now opens the app directly from:
`/Applications/Countdown Wallpaper.app`

## Debugging Steps

If timers still don't appear:

1. **Check Console.app for messages**:
   - Open Console.app
   - Filter by "CountdownScreensaver"
   - Look for messages about timer loading

2. **Verify timer data exists**:
   ```bash
   # Check if preferences file exists
   ls -la ~/Library/Preferences/com.countdownwallpaper.app.plist

   # View the preferences (will show binary data)
   defaults read com.countdownwallpaper.app
   ```

3. **Test timer loading**:
   - Make sure the Countdown Wallpaper app has been run at least once
   - Create some timers in the app
   - Quit and restart the app to ensure preferences are saved
   - Then test the screensaver

4. **Force reload**:
   ```bash
   # Reinstall the screensaver
   cd Screensaver
   make clean
   make install
   ```

## Technical Details

The screensaver loads timers by:
1. Reading `~/Library/Preferences/com.countdownwallpaper.app.plist`
2. Extracting the "SavedTimers" data
3. Decoding the JSON timer array
4. Using the same layout engine as the wallpaper

Timer data is reloaded every 10 seconds to catch any updates made in the main app.
