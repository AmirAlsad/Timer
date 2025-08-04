#!/bin/bash

echo "🔍 Monitoring CountdownScreensaver logs in real-time..."
echo "Open System Settings → Screen Saver and select 'Countdown Screensaver'"
echo "Press Ctrl+C to stop monitoring"
echo
echo "=== LIVE LOGS ==="

# Monitor logs in real-time for CountdownScreensaver
log stream --predicate 'process CONTAINS "CountdownScreensaver" OR process CONTAINS "ScreenSaver" OR process CONTAINS "legacyScreenSaver"' --info --debug
