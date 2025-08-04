#!/bin/bash

echo "🔍 Debugging Countdown Screensaver..."
echo

# Step 1: Check if timer data exists and what format it's in
echo "=== STEP 1: Timer Data Analysis ==="
echo

if defaults read com.countdownwallpaper.app SavedTimers &>/dev/null; then
    echo "✅ SavedTimers key exists in preferences"

    # Get the raw data
    echo "Raw data format:"
    defaults read com.countdownwallpaper.app SavedTimers
    echo

    # Try to export as base64 to see if we can decode it
    echo "Attempting to export timer data..."
    defaults export com.countdownwallpaper.app - | grep -A 50 SavedTimers | head -20

else
    echo "❌ No SavedTimers found in com.countdownwallpaper.app"
    echo "Available keys:"
    defaults read com.countdownwallpaper.app 2>/dev/null || echo "No preferences found"
fi

echo
echo "=== STEP 2: Console Logs ==="
echo "Opening Console.app filtered for screensaver logs..."
echo "Look for messages containing 'CountdownScreensaver' or 'Loading timers'"
echo

# Open Console.app with a filter (this will open in GUI)
open /Applications/Utilities/Console.app

# Also try to get recent screensaver logs from command line
echo "Recent screensaver-related logs:"
log show --last 1h --predicate 'process CONTAINS "ScreenSaver" OR process CONTAINS "CountdownScreensaver"' --info 2>/dev/null | tail -20

echo
echo "=== STEP 3: Manual Timer Loading Test ==="
echo

# Create a test Swift script to try loading timers
cat > /tmp/test_timer_loading.swift << 'EOF'
import Foundation

// Test timer loading like the screensaver does
let appBundleIdentifier = "com.countdownwallpaper.app"

print("🔍 Testing timer loading methods...")

// Method 1: UserDefaults suite
if let appDefaults = UserDefaults(suiteName: appBundleIdentifier),
   let data = appDefaults.data(forKey: "SavedTimers") {
    print("✅ Method 1: Found \(data.count) bytes in suite defaults")
} else {
    print("❌ Method 1: No data in suite defaults")
}

// Method 2: Standard UserDefaults
if let data = UserDefaults.standard.data(forKey: "SavedTimers") {
    print("✅ Method 2: Found \(data.count) bytes in standard defaults")
} else {
    print("❌ Method 2: No data in standard defaults")
}

// Method 3: Direct domain access
let domainDefaults = UserDefaults()
domainDefaults.addSuite(named: appBundleIdentifier)
if let data = domainDefaults.data(forKey: "SavedTimers") {
    print("✅ Method 3: Found \(data.count) bytes in domain defaults")
} else {
    print("❌ Method 3: No data in domain defaults")
}

print("Test complete.")
EOF

echo "Running Swift test..."
swift /tmp/test_timer_loading.swift

echo
echo "=== NEXT STEPS ==="
echo "1. Check Console.app for detailed screensaver logs"
echo "2. Run 'make test' to open screensaver preferences"
echo "3. Select the screensaver and watch Console.app for messages"
echo "4. Report back what you see in the logs!"
