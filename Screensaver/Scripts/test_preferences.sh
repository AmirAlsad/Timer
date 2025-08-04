#!/bin/bash

echo "Checking Countdown Wallpaper preferences..."
echo

PLIST_PATH="$HOME/Library/Preferences/com.countdownwallpaper.app.plist"

if [ -f "$PLIST_PATH" ]; then
    echo "✓ Preferences file exists at: $PLIST_PATH"
    echo

    # Check if SavedTimers key exists
    if defaults read com.countdownwallpaper.app SavedTimers &>/dev/null; then
        echo "✓ SavedTimers data found in preferences"
        echo

        # Get the size of the data
        DATA_SIZE=$(defaults read com.countdownwallpaper.app SavedTimers | wc -c)
        echo "  Data size: $DATA_SIZE bytes"

        # Try to extract some readable info
        echo
        echo "Attempting to decode timer data..."
        # This will show raw data, but we can at least see if it contains timer labels
        defaults read com.countdownwallpaper.app SavedTimers | strings | grep -E "(label|targetDate|New Year|Age)" | head -10
    else
        echo "✗ No SavedTimers data found in preferences"
        echo
        echo "Please make sure to:"
        echo "1. Open the Countdown Wallpaper app"
        echo "2. Create at least one timer"
        echo "3. Quit the app (this saves preferences)"
    fi
else
    echo "✗ Preferences file not found"
    echo
    echo "The Countdown Wallpaper app needs to be run at least once to create preferences."
fi

echo
echo "To manually inspect all preferences:"
echo "  defaults read com.countdownwallpaper.app"
