import ScreenSaver
import Cocoa
import Foundation

// NSPrincipalClass export - this class name must match Info.plist
@objc(CountdownScreensaverView)
public class CountdownScreensaverView: ScreenSaverView {

    // MARK: - Properties
    private var timers: [SimpleTimer] = []
    private var updateTimer: Timer?
    private var lastUpdateTime: Date = Date()

    // Drawing properties
    private let backgroundColor = NSColor.black
    private let titleColor = NSColor.white
    private let timerLabelColor = NSColor.cyan
    private let timerValueColor = NSColor.white
    private let statusColor = NSColor.green
    private let errorColor = NSColor.red

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
        updateTimer?.invalidate()
    }

    // MARK: - Setup

    private func setupScreensaver() {
        NSLog("🔧 CountdownScreensaver: Setting up AppKit-based screensaver...")
        loadTimers()
        NSLog("✅ CountdownScreensaver: Setup complete with \(timers.count) timers")
    }

    // MARK: - ScreenSaver Lifecycle

    public override func draw(_ rect: NSRect) {
        super.draw(rect)
        NSLog("🎨 CountdownScreensaver: Initial draw called - frame: \(bounds)")
        drawContent()
    }

    public override func animateOneFrame() {
        // Only reload timers every 5 seconds to avoid excessive file I/O
        let now = Date()
        if now.timeIntervalSince(lastUpdateTime) >= 5.0 {
            loadTimers()
            lastUpdateTime = now
        }

        // Always redraw to update countdown values
        setNeedsDisplay(bounds)
    }

    public override func startAnimation() {
        super.startAnimation()
        NSLog("▶️ CountdownScreensaver: Starting animation")
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

    // MARK: - Drawing

    private func drawContent() {
        let bounds = self.bounds

        // Fill background
        backgroundColor.setFill()
        bounds.fill()

        // Calculate layout
        let centerX = bounds.midX
        var currentY = bounds.height * 0.8

        // Draw title
        drawText(
            "Countdown Screensaver",
            at: NSPoint(x: centerX, y: currentY),
            font: NSFont.boldSystemFont(ofSize: 48),
            color: titleColor,
            centered: true
        )
        currentY -= 80

        // Draw status
        let statusText = "Found \(timers.count) timers"
        drawText(
            statusText,
            at: NSPoint(x: centerX, y: currentY),
            font: NSFont.systemFont(ofSize: 32),
            color: statusColor,
            centered: true
        )
        currentY -= 60

        if timers.isEmpty {
            drawText(
                "No timers loaded",
                at: NSPoint(x: centerX, y: currentY),
                font: NSFont.systemFont(ofSize: 24),
                color: errorColor,
                centered: true
            )
        } else {
            // Draw first 3 timers (to avoid clipping)
            let timersToShow = Array(timers.prefix(3))

            for (index, timer) in timersToShow.enumerated() {
                // Timer label
                drawText(
                    "Timer \(index + 1): \(timer.label)",
                    at: NSPoint(x: centerX, y: currentY),
                    font: NSFont.boldSystemFont(ofSize: 28),
                    color: timerLabelColor,
                    centered: true
                )
                currentY -= 40

                // Timer value with background
                let timerRect = NSRect(
                    x: centerX - 200,
                    y: currentY - 35,
                    width: 400,
                    height: 50
                )

                // Draw background for timer value
                NSColor.blue.withAlphaComponent(0.3).setFill()
                timerRect.fill()

                drawText(
                    timer.displayText,
                    at: NSPoint(x: centerX, y: currentY - 20),
                    font: NSFont.monospacedSystemFont(ofSize: 24, weight: .regular),
                    color: timerValueColor,
                    centered: true
                )
                currentY -= 80
            }

            // Show additional timers count if needed
            if timers.count > 3 {
                drawText(
                    "... and \(timers.count - 3) more timers",
                    at: NSPoint(x: centerX, y: currentY),
                    font: NSFont.systemFont(ofSize: 20),
                    color: NSColor.gray,
                    centered: true
                )
            }
        }
    }

    private func drawText(_ text: String, at point: NSPoint, font: NSFont, color: NSColor, centered: Bool = false) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let size = attributedString.size()

        var drawPoint = point
        if centered {
            drawPoint.x -= size.width / 2
        }

        attributedString.draw(at: drawPoint)
    }

    // MARK: - Timer Data Loading

    private func loadTimers() {
        NSLog("🔍 CountdownScreensaver: Loading timers...")

        // Method 1: Try reading from /tmp (shared location)
        do {
            let timerFileURL = URL(fileURLWithPath: "/tmp/CountdownWallpaper/timers.json")

            NSLog("📂 CountdownScreensaver: Looking for timers at: \(timerFileURL.path)")

            if FileManager.default.fileExists(atPath: timerFileURL.path) {
                let data = try Data(contentsOf: timerFileURL)
                NSLog("📱 CountdownScreensaver: Found timer file (\(data.count) bytes)")

                let decoder = JSONDecoder()
                let fullTimers = try decoder.decode([SimpleTimer].self, from: data)
                self.timers = fullTimers
                NSLog("✅ CountdownScreensaver: Successfully decoded \(fullTimers.count) timers from /tmp")

                // Log first timer for debugging
                if let firstTimer = fullTimers.first {
                    NSLog("🔍 CountdownScreensaver: First timer: \(firstTimer.label)")
                }
                return
            } else {
                NSLog("📂 CountdownScreensaver: Timer file does not exist at: \(timerFileURL.path)")
            }
        } catch {
            NSLog("❌ CountdownScreensaver: File read error: \(error)")
        }

        // Method 2: Fallback to Application Support (original location)
        do {
            let fileManager = FileManager.default
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDirectory = appSupportURL.appendingPathComponent("CountdownWallpaper")
            let timerFileURL = appDirectory.appendingPathComponent("timers.json")

            NSLog("📂 CountdownScreensaver: Fallback - Looking for timers at: \(timerFileURL.path)")

            if fileManager.fileExists(atPath: timerFileURL.path) {
                let data = try Data(contentsOf: timerFileURL)
                NSLog("📱 CountdownScreensaver: Found fallback timer file (\(data.count) bytes)")

                let decoder = JSONDecoder()
                let fullTimers = try decoder.decode([SimpleTimer].self, from: data)
                self.timers = fullTimers
                NSLog("✅ CountdownScreensaver: Successfully decoded \(fullTimers.count) timers from fallback")
                return
            } else {
                NSLog("📂 CountdownScreensaver: Fallback timer file does not exist")
            }
        } catch {
            NSLog("❌ CountdownScreensaver: Fallback file read error: \(error)")
        }

        // Method 3: Final fallback to UserDefaults (unlikely to work in sandbox)
        let appBundleIdentifier = "com.countdownwallpaper.app"

        if let appDefaults = UserDefaults(suiteName: appBundleIdentifier),
           let data = appDefaults.data(forKey: "SavedTimers") {
            NSLog("📱 CountdownScreensaver: Found timer data in UserDefaults (\(data.count) bytes)")

            do {
                let decoder = JSONDecoder()
                let fullTimers = try decoder.decode([SimpleTimer].self, from: data)
                self.timers = fullTimers
                NSLog("✅ CountdownScreensaver: Successfully decoded \(fullTimers.count) timers from UserDefaults")
                return
            } catch {
                NSLog("❌ CountdownScreensaver: JSON decode error: \(error)")
            }
        }

        NSLog("❌ CountdownScreensaver: No timer data found in any location")
    }
}

// MARK: - Timer Data Models

struct SimpleTimer: Codable, Identifiable {
    let id: UUID
    let label: String
    let targetDate: Date
    let isCountUp: Bool

    // Optional field for backward compatibility
    let isCompleted: Bool?

    // Computed property for compatibility
    var isTimerCompleted: Bool {
        return isCompleted ?? false
    }

    var displayText: String {
        let now = Date()
        let interval = isCountUp ? now.timeIntervalSince(targetDate) : targetDate.timeIntervalSince(now)

        if interval < 0 && !isCountUp {
            return "Time's up!"
        }

        let absInterval = abs(interval)
        let days = Int(absInterval) / 86400
        let hours = Int(absInterval) % 86400 / 3600
        let minutes = Int(absInterval) % 3600 / 60
        let seconds = Int(absInterval) % 60

        if days > 0 {
            return String(format: "%dd %02dh %02dm %02ds", days, hours, minutes, seconds)
        } else if hours > 0 {
            return String(format: "%02dh %02dm %02ds", hours, minutes, seconds)
        } else {
            return String(format: "%02dm %02ds", minutes, seconds)
        }
    }
}
