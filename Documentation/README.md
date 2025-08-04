# Countdown Wallpaper for macOS

A custom macOS application that displays multiple countdown timers and count-up timers directly on your desktop wallpaper with millisecond precision. Perfect for tracking important deadlines, personal milestones, age counters, and any time-sensitive events.

## ✨ Features

- **Multiple Timers**: Display as many countdown/count-up timers as you need
- **Precise Positioning**: Place timers anywhere on your screen with pixel-perfect control
- **Priority System**: Assign priority levels to control which timers appear more prominently
- **Second Precision**: Accurate time display with optimal performance
- **Count Up & Countdown**: Support for both countdown timers and count-up timers (like age counters)
- **Customizable Appearance**: Adjust font size, color, and positioning for each timer
- **Live Desktop Overlay**: Timers appear directly on your desktop background without interfering with normal use
- **Persistent Settings**: Your timer configurations are automatically saved and restored
- **Menu Bar Access**: Easy access to settings through the menu bar

## 🚀 Quick Start

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode Command Line Tools

If you don't have Xcode Command Line Tools installed:
```bash
xcode-select --install
```

### Build and Run

1. **Clone or download this project**
2. **Build the application:**
   ```bash
   ./build.sh
   ```
3. **Run the application:**
   ```bash
   ./build/CountdownWallpaper
   ```

   Or build and run in one step:
   ```bash
   ./build.sh --run
   ```

## 📖 How to Use

### First Launch

When you first launch the app:
1. The app will appear in your menu bar with a timer icon ⏲️
2. Two default timers will be created for demonstration
3. The timers will immediately appear on your desktop

### Managing Timers

1. **Access Settings**: Click the timer icon in your menu bar and select "Settings"
2. **Add New Timer**: Click the "+" button in the settings window
3. **Edit Timer**: Select a timer from the list to edit its properties
4. **Delete Timer**: Select a timer and click the "Delete" button

### Timer Configuration

For each timer, you can configure:

- **Label**: A descriptive name for your timer
- **Target Date**: The date/time you're counting to or from
- **Type**: Choose between countdown (to future date) or count-up (from past date)
- **Position**: X and Y coordinates for precise placement on screen
- **Priority**: Higher numbers appear on top (1-10 scale)
- **Font Size**: Text size (12-72 points)
- **Text Color**: Any color you prefer
- **Show Milliseconds**: Toggle milliseconds in display (currently optimized for seconds)

### Position Guidelines

Screen coordinates start from the top-left corner:
- X: 0 (left edge) to screen width (right edge)
- Y: 0 (top edge) to screen height (bottom edge)

For a 1920x1080 screen:
- Center: X=960, Y=540
- Top-left: X=100, Y=100
- Bottom-right: X=1820, Y=980

## 🔧 Technical Details

This application implements the "live overlay" approach recommended in the technical research document. Key technical features:

- **Transparent Overlay Window**: Creates a borderless, transparent window that sits between your desktop background and desktop icons
- **Optimized Updates**: Uses 1-second intervals for optimal performance and battery life
- **SwiftUI Interface**: Modern declarative UI with real-time previews
- **AppKit Integration**: Custom window management for proper desktop integration
- **Automatic Persistence**: Settings saved to UserDefaults with JSON encoding

### Performance

- **CPU Usage**: Minimal impact due to efficient GPU-accelerated rendering
- **Memory Usage**: Lightweight with automatic memory management
- **Battery Impact**: Optimized update cycles for energy efficiency

## 🎯 Use Cases

- **Project Deadlines**: Track work project milestones and deadlines
- **Personal Goals**: Count down to vacations, events, birthdays
- **Age Tracking**: Display your exact age with precision
- **Habit Tracking**: Count days since starting a new habit
- **Anniversary Counters**: Track relationship milestones
- **Event Planning**: Coordinate multiple event deadlines

## 🛠️ Development

### Project Structure

```
countdown-background/
├── CountdownWallpaperApp.swift    # Main app and window management
├── CountdownTimer.swift           # Data model and timer logic
├── OverlayView.swift             # Desktop overlay rendering
├── SettingsView.swift            # User interface for configuration
├── Package.swift                 # Swift Package Manager config
├── build.sh                      # Build script
└── README.md                     # This file
```

### Building from Source

The project uses Swift Package Manager for build configuration:

```bash
# Debug build
swift build

# Release build
swift build --configuration release

# Run directly
swift run
```

### Extending the Application

The codebase is designed for easy extension. Some ideas:

- **Visual Effects**: Add animations, gradients, or special effects
- **Notification System**: Alert when timers reach zero
- **Themes**: Pre-defined color schemes and layouts
- **Export/Import**: Share timer configurations
- **Multiple Monitors**: Support for multi-monitor setups

## ⚠️ Important Notes

- **System Permissions**: The app may request accessibility permissions on first launch
- **Menu Bar Only**: The app doesn't appear in the Dock - access via menu bar
- **Background Operation**: The app continues running even when settings window is closed
- **Resource Usage**: Designed to be lightweight but uses continuous updates for precision

## 📄 License

This project is provided as-is for educational and personal use. Feel free to modify and extend for your own needs.

## 🐛 Troubleshooting

**App doesn't start:**
- Ensure macOS 14+ and Xcode Command Line Tools are installed
- Try rebuilding: `swift clean && ./build.sh`

**Timers not visible:**
- Check if timers are positioned within screen bounds
- Verify the app is running (look for menu bar icon)
- Try different text colors if using light wallpapers

**Settings window won't open:**
- Click the menu bar icon and select "Settings"
- If stuck, quit and restart the application

**Performance issues:**
- Reduce number of active timers
- Disable milliseconds for less critical timers
- Check for other resource-intensive applications

---

*Built following the technical guidance from the comprehensive macOS wallpaper research document.*
