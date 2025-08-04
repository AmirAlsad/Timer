import ScreenSaver
import Cocoa
import Foundation
import SwiftUI

// MARK: - Beautiful AppKit Screensaver (Matching Wallpaper Design)

@objc(CountdownScreensaverView)
public class CountdownScreensaverView: ScreenSaverView {

    // MARK: - Properties
    private var timers: [CountdownTimer] = []
    private var timerLayouts: [TimerLayout] = []
    private var layoutEngine = LayoutEngine()
    private var lastUpdateTime: Date = Date()

    // Drawing properties (matching wallpaper design)
    private let backgroundColor = NSColor.black

    // MARK: - Initialization

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.animationTimeInterval = 1.0
        setupScreensaver()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.animationTimeInterval = 1.0
        setupScreensaver()
    }

    deinit {
        // Clean up any timers if needed
    }

    // MARK: - Setup

    private func setupScreensaver() {
        NSLog("🔧 CountdownScreensaver: Setting up beautiful AppKit screensaver...")
        loadTimers()
        updateLayouts()
        NSLog("✅ CountdownScreensaver: Setup complete with \(timers.count) timers")
    }

    // MARK: - ScreenSaver Lifecycle

    public override func draw(_ rect: NSRect) {
        super.draw(rect)
        NSLog("🎨 CountdownScreensaver: Drawing beautiful design - frame: \(bounds)")
        drawContent()
    }

    public override func animateOneFrame() {
        // Reload timers every 5 seconds to avoid excessive file I/O
        let now = Date()
        if now.timeIntervalSince(lastUpdateTime) >= 5.0 {
            loadTimers()
            updateLayouts()
            lastUpdateTime = now
        }

        // Always redraw to update countdown values
        setNeedsDisplay(bounds)
    }

    public override func startAnimation() {
        super.startAnimation()
        NSLog("▶️ CountdownScreensaver: Starting beautiful animation")
    }

    public override func stopAnimation() {
        super.stopAnimation()
        NSLog("⏹️ CountdownScreensaver: Stopping animation")
    }

    // MARK: - Configuration

    public override var hasConfigureSheet: Bool {
        return true
    }

    public override var configureSheet: NSWindow? {
        NSLog("⚙️ CountdownScreensaver: Opening configuration...")

        // Use NSAppleScript to activate the main app and open settings
        let script = """
        tell application "System Events"
            set appRunning to (name of processes) contains "Countdown Wallpaper"
        end tell

        if appRunning then
            tell application "Countdown Wallpaper"
                activate
            end tell
            tell application "System Events"
                tell process "Countdown Wallpaper"
                    click menu bar item 1 of menu bar 2
                    delay 0.5
                    click menu item "Settings" of menu 1 of menu bar item 1 of menu bar 2
                end tell
            end tell
        else
            tell application "Countdown Wallpaper"
                activate
            end tell
        end if
        """

        let appleScript = NSAppleScript(source: script)
        var errorDict: NSDictionary?
        appleScript?.executeAndReturnError(&errorDict)

        if let error = errorDict {
            NSLog("❌ CountdownScreensaver: AppleScript error: \(error)")
        }

        return nil
    }

    // MARK: - Layout Updates

    private func updateLayouts() {
        guard !timers.isEmpty else {
            timerLayouts = []
            return
        }

        // Set screen size for layout engine
        layoutEngine.setScreenSize(bounds.size)

        // Calculate layouts for all timers
        timerLayouts = layoutEngine.calculateLayouts(for: timers, screenSize: bounds.size)

        NSLog("🎯 CountdownScreensaver: Updated layouts for \(timerLayouts.count) timers")
    }

    // MARK: - Beautiful Drawing (Matching Wallpaper)

    private func drawContent() {
        let bounds = self.bounds

        // Fill with solid black background
        backgroundColor.setFill()
        bounds.fill()

        // Draw each timer with beautiful styling
        for layout in timerLayouts {
            drawTimer(layout.timer, at: layout.position, fontSize: layout.fontSize)
        }
    }

    private func drawTimer(_ timer: CountdownTimer, at position: CGPoint, fontSize: CGFloat) {
        let displayText = timer.displayText

        // Get timer's display color (from template or custom)
        let timerColor = nsColorFromSwiftUIColor(timer.displayColor)

        // Get timer's font (from template or custom)
        let fontName = timer.displayFontName
        let fontWeight = nsWeightFromSwiftUIWeight(timer.template.fontWeight)

        // Create font
        let font: NSFont
        if let customFont = NSFont(name: fontName, size: fontSize) {
            font = customFont
        } else {
            // Fallback to system font with weight
            font = NSFont.systemFont(ofSize: fontSize, weight: fontWeight)
        }

        // Create attributed string with styling
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: timerColor,
            .shadow: createShadow()
        ]

        let attributedString = NSAttributedString(string: displayText, attributes: attributes)
        let textSize = attributedString.size()

        // Calculate position (center the text)
        let drawPoint = NSPoint(
            x: position.x - textSize.width / 2,
            y: position.y - textSize.height / 2
        )

        // Draw semi-transparent background (matching wallpaper)
        drawTextBackground(at: drawPoint, size: textSize)

        // Draw the text
        attributedString.draw(at: drawPoint)
    }

    private func drawTextBackground(at point: NSPoint, size: CGSize) {
        let padding: CGFloat = 8
        let cornerRadius: CGFloat = 8

        let backgroundRect = NSRect(
            x: point.x - padding,
            y: point.y - padding,
            width: size.width + (padding * 2),
            height: size.height + (padding * 2)
        )

        // Semi-transparent black background (matching wallpaper)
        NSColor.black.withAlphaComponent(0.3).setFill()

        let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: cornerRadius, yRadius: cornerRadius)
        backgroundPath.fill()
    }

    private func createShadow() -> NSShadow {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.7)
        shadow.shadowOffset = NSSize(width: 1, height: -1)
        shadow.shadowBlurRadius = 2
        return shadow
    }

    // MARK: - Color/Font Conversion Helpers

    private func nsColorFromSwiftUIColor(_ swiftUIColor: Color) -> NSColor {
        // Convert SwiftUI Color to NSColor
        // This is simplified - for full compatibility, you'd need to handle all color types

        // Extract color components if possible, otherwise use white as fallback
        if let cgColor = swiftUIColor.cgColor {
            return NSColor(cgColor: cgColor) ?? NSColor.white
        }

        // Fallback color mapping for common template colors
        // You could expand this to match your TimerTemplate colors exactly
        return NSColor.white
    }

    private func nsWeightFromSwiftUIWeight(_ swiftUIWeight: Font.Weight) -> NSFont.Weight {
        switch swiftUIWeight {
        case .black: return .black
        case .heavy: return .heavy
        case .bold: return .bold
        case .semibold: return .semibold
        case .medium: return .medium
        case .regular: return .regular
        case .light: return .light
        case .thin: return .thin
        case .ultraLight: return .ultraLight
        default: return .medium
        }
    }

    // MARK: - Timer Data Loading

    private func loadTimers() {
        NSLog("🔍 CountdownScreensaver: Loading timers...")

        // Method 1: Try reading from /tmp (shared location)
        do {
            let timerFileURL = URL(fileURLWithPath: "/tmp/CountdownWallpaper/timers.json")

            if FileManager.default.fileExists(atPath: timerFileURL.path) {
                let data = try Data(contentsOf: timerFileURL)
                NSLog("📱 CountdownScreensaver: Found timer file (\(data.count) bytes)")

                let decoder = JSONDecoder()
                let fullTimers = try decoder.decode([CountdownTimer].self, from: data)
                self.timers = fullTimers
                NSLog("✅ CountdownScreensaver: Successfully decoded \(fullTimers.count) timers from /tmp")
                return
            } else {
                NSLog("📂 CountdownScreensaver: Timer file does not exist at: \(timerFileURL.path)")
            }
        } catch {
            NSLog("❌ CountdownScreensaver: File read error: \(error)")
        }

        // Method 2: Fallback to Application Support
        do {
            let fileManager = FileManager.default
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDirectory = appSupportURL.appendingPathComponent("CountdownWallpaper")
            let timerFileURL = appDirectory.appendingPathComponent("timers.json")

            if fileManager.fileExists(atPath: timerFileURL.path) {
                let data = try Data(contentsOf: timerFileURL)
                let decoder = JSONDecoder()
                let fullTimers = try decoder.decode([CountdownTimer].self, from: data)
                self.timers = fullTimers
                NSLog("✅ CountdownScreensaver: Successfully decoded \(fullTimers.count) timers from fallback")
                return
            }
        } catch {
            NSLog("❌ CountdownScreensaver: Fallback file read error: \(error)")
        }

        NSLog("❌ CountdownScreensaver: No timer data found in any location")
    }
}

// MARK: - Shared Data Models (copy from main app for compatibility)

// Note: Shared models are included from SharedModelsComplete.swift

// Additional helper extension for AppKit compatibility
extension Color {
    var cgColor: CGColor? {
        // This is a simplified implementation
        // In a real app, you'd want more robust color conversion
        if self == Color.white { return CGColor.white }
        if self == Color.black { return CGColor.black }
        if self == Color.red { return CGColor(red: 1, green: 0, blue: 0, alpha: 1) }
        if self == Color.green { return CGColor(red: 0, green: 1, blue: 0, alpha: 1) }
        if self == Color.blue { return CGColor(red: 0, green: 0, blue: 1, alpha: 1) }
        // Fallback for template colors - approximate conversion
        return CGColor(red: 1, green: 1, blue: 1, alpha: 1) // White fallback
    }
}
