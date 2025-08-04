# Countdown Wallpaper & Screensaver

A beautiful macOS application that displays countdown timers both as desktop wallpaper overlays and as screensavers. Built with SwiftUI and featuring sophisticated layout algorithms for optimal timer positioning.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

- **Desktop Wallpaper Integration**: Overlay countdown timers directly on your desktop
- **Screensaver Support**: Use your timers as a beautiful screensaver
- **Multiple Layout Algorithms**: Choose between Spiral and Vertical layouts
- **Real-time Synchronization**: Screensaver automatically syncs with wallpaper settings
- **Template System**: Pre-designed timer styles (Anticipation, Deadline, Memento Mori, Legacy)
- **Flexible Timer Types**: Support for both countdown and count-up timers
- **Menu Bar Integration**: Quick access via menu bar icon
- **Multi-screen Support**: Works across multiple displays

## 🏗️ Project Structure

```
countdown-wallpaper/
├── Sources/                     # Main application source code
│   ├── CountdownWallpaperApp.swift    # App entry point & delegate
│   ├── CountdownTimer.swift            # Data models & persistence
│   ├── LayoutEngine.swift              # Layout algorithms & positioning
│   ├── OverlayView.swift               # Desktop overlay rendering
│   └── SettingsView.swift              # Settings interface
├── Screensaver/                 # Screensaver implementation
│   ├── Sources/                        # Active screensaver code
│   │   ├── CountdownScreensaverView_SwiftUI.swift
│   │   └── SharedModelsComplete.swift
│   ├── Legacy/                         # Previous implementation attempts
│   ├── Scripts/                        # Build scripts & utilities
│   ├── Documentation/                  # Screensaver-specific docs
│   └── Build/                          # Compiled screensaver bundle
├── Resources/                   # Assets & resources
│   ├── AppIcon.icns
│   └── timer.png
├── Documentation/               # Project documentation
├── Scripts/                     # Build & utility scripts
├── CountdownWallpaper.app      # Compiled application bundle
└── Package.swift               # Swift Package Manager configuration
```

## 🚀 Quick Start

### Building the Application

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd countdown-wallpaper
   ```

2. **Build the main application**:
   ```bash
   swift build
   ```

3. **Update the app bundle** (optional):
   ```bash
   cp .build/debug/CountdownWallpaper "CountdownWallpaper.app/Contents/MacOS/CountdownWallpaper"
   ```

### Building the Screensaver

1. **Navigate to screensaver directory**:
   ```bash
   cd Screensaver/Scripts
   ```

2. **Build and install**:
   ```bash
   make swiftui         # Build SwiftUI version (recommended)
   make install         # Install to ~/Library/Screen Savers
   ```

3. **Force reload** (if needed):
   ```bash
   make force-reload-swiftui
   ```

## 🎯 Usage

### Setting Up Timers

1. Launch the **Countdown Wallpaper** app
2. Use the settings interface to:
   - Add new countdown/count-up timers
   - Choose timer templates and styles
   - Select layout algorithm (Spiral or Vertical)
   - Arrange timer priorities via drag & drop

### Enabling Screensaver

1. Open **System Settings** → **Screen Saver**
2. Select **"Countdown Screensaver"** from the list
3. Click **"Options..."** for configuration instructions
4. The screensaver automatically syncs with your wallpaper settings

### Layout Algorithms

- **Spiral Layout**: Organic, word-cloud style positioning with collision detection
- **Vertical Layout**: Clean, organized vertical stack with priority-based ordering

## 🔧 Technical Details

### Data Synchronization

The application uses a sophisticated synchronization system:

- **Primary Storage**: `~/Library/Application Support/CountdownWallpaper/timers.json`
- **Screensaver Access**: `/tmp/CountdownWallpaper/timers.json` (auto-updated)
- **Format**: JSON containing timers + layout algorithm choice
- **Update Frequency**: Real-time for wallpaper, 5-second polling for screensaver

### Layout Engine

The positioning system features:
- **Logarithmic Font Scaling**: Priority-based sizing with smooth gradients
- **Collision Detection**: Sophisticated overlap prevention
- **Screen Constraints**: Automatic boundary respect with buffer zones
- **Multi-screen Support**: Independent layout calculation per display

## 📚 Documentation

- **[Project Documentation](Documentation/)**: Comprehensive guides and notes
- **[Screensaver Documentation](Screensaver/Documentation/)**: Screensaver-specific information
- **[Implementation Notes](Documentation/SCREENSAVER_IMPLEMENTATION.md)**: Technical implementation details
- **[Troubleshooting Guide](Screensaver/Documentation/TROUBLESHOOTING.md)**: Common issues and solutions

## 🛠️ Development

### Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Architecture

- **SwiftUI**: Modern UI framework for settings and overlay
- **AppKit**: Low-level window management and screensaver integration
- **Combine**: Reactive programming for real-time updates
- **Swift Package Manager**: Dependency management and building

### Building Different Versions

The screensaver supports multiple implementation approaches:

```bash
make swiftui           # SwiftUI version (recommended)
make appkit-beautiful  # Beautiful AppKit version
make appkit-simple     # Simple AppKit version
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit your changes: `git commit -am 'Add feature'`
4. Push to the branch: `git push origin feature-name`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by desktop customization tools and productivity apps
- Built with modern macOS development best practices
- Special thanks to the Swift and macOS development community

---

**Made with ❤️ for macOS productivity enthusiasts**