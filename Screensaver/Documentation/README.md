# Countdown Screensaver

This is the screensaver companion for the Countdown Wallpaper app. It displays the same countdown timers as your wallpaper but as a macOS screensaver.

## Features

- Displays all timers from the Countdown Wallpaper app
- Solid black background for better visibility
- Updates every second
- Supports multiple screens
- Configure button opens the main app settings

## Building

### Requirements

- macOS 14.0 or later
- Xcode Command Line Tools
- The main Countdown Wallpaper app should be installed

### Build Instructions

1. Navigate to the Screensaver directory:
   ```bash
   cd Screensaver
   ```

2. Build the screensaver:
   ```bash
   ./build.sh
   ```

   Or using make directly:
   ```bash
   make all
   ```

## Installation

### User Installation (Recommended)

Install the screensaver for the current user:
```bash
make install
```

This installs the screensaver to `~/Library/Screen Savers/`

### System Installation

Install the screensaver for all users (requires admin password):
```bash
make install-system
```

This installs the screensaver to `/Library/Screen Savers/`

## Testing

After installation, you can test the screensaver:
```bash
make test
```

This will open System Preferences to the Screen Saver pane.

## Uninstallation

To remove the screensaver:
```bash
make uninstall
```

## Configuration

The screensaver reads timer data from the main Countdown Wallpaper app. To configure timers:

1. Click the "Screen Saver Options..." button in System Preferences
2. This will open the main Countdown Wallpaper app
3. Configure your timers in the app
4. Changes will be reflected in the screensaver

## Troubleshooting

### Screensaver doesn't show timers
- Make sure the main Countdown Wallpaper app has been run at least once
- Check that you have created some timers in the app

### Configure button doesn't work
- Ensure the main Countdown Wallpaper app is installed
- The app should be in your Applications folder

### Build fails
- Make sure you have Xcode Command Line Tools installed:
  ```bash
  xcode-select --install
  ```

## Technical Details

The screensaver shares timer data with the main app through a shared UserDefaults suite (`com.countdownwallpaper.app`). It reads the same timer configuration and displays it with identical styling but on a solid black background suitable for screensavers.
