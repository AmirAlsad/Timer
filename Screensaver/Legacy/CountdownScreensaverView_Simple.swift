import ScreenSaver
import SwiftUI
import AppKit

// Export the principal class for the screensaver bundle
@_cdecl("CountdownScreensaverView")
public func CountdownScreensaverViewFactory() -> CountdownScreensaverView.Type {
    return CountdownScreensaverView.self
}

public class CountdownScreensaverView: ScreenSaverView {
    private var hostingView: NSView?
    private var updateTimer: Timer?
    private var timers: [SimpleTimer] = []

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.animationTimeInterval = 1.0
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.animationTimeInterval = 1.0
        setupView()
    }

    deinit {
        updateTimer?.invalidate()
    }

    private func setupView() {
        NSLog("🔧 CountdownScreensaver: Setting up view...")

        // Load timers immediately
        loadTimers()

        // Create SwiftUI view
        let contentView = SimpleScreensaverContentView(timers: timers)
            .background(Color.black)

                // Create hosting view with explicit frame management
        let hosting = NSHostingView(rootView: contentView)
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = self.bounds
        hosting.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(hosting)
        self.hostingView = hosting

        // Add constraints to ensure proper sizing
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: self.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        NSLog("🔧 CountdownScreensaver: Hosting view frame: \(hosting.frame)")
        NSLog("🔧 CountdownScreensaver: Self frame: \(self.bounds)")

        NSLog("✅ CountdownScreensaver: View setup complete with \(timers.count) timers")

        // Start timer for updates
        startUpdateTimer()
    }

    private func startUpdateTimer() {
        updateTimer?.invalidate()
        // Temporarily disable updates to debug the display issue
        // updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        //     self?.loadTimers() // Reload timers every second
        //     if let hostingView = self?.hostingView as? NSHostingView<SimpleScreensaverContentView> {
        //         hostingView.rootView = SimpleScreensaverContentView(timers: self?.timers ?? [])
        //     }
        // }
        NSLog("🔧 CountdownScreensaver: Update timer disabled for debugging")
    }

    public override func startAnimation() {
        super.startAnimation()
        NSLog("▶️ CountdownScreensaver: Starting animation")
        startUpdateTimer()
    }

    public override func stopAnimation() {
        super.stopAnimation()
        NSLog("⏹️ CountdownScreensaver: Stopping animation")
        updateTimer?.invalidate()
    }

    public override var hasConfigureSheet: Bool {
        return true
    }

    public override var configureSheet: NSWindow? {
        NSLog("⚙️ CountdownScreensaver: Configure button pressed")

        // Try to open the app
        let appPath = "/Applications/Countdown Wallpaper.app"
        let appURL = URL(fileURLWithPath: appPath)

        NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration()) { (app, error) in
            if let error = error {
                NSLog("❌ CountdownScreensaver: Failed to open app: \(error)")
            } else {
                NSLog("✅ CountdownScreensaver: App opened successfully")
            }
        }

        return nil
    }

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

// Simplified Timer struct for testing
struct SimpleTimer: Codable, Identifiable {
    let id: UUID
    let label: String
    let targetDate: Date
    let isCountUp: Bool
    let fontSize: CGFloat
    let template: String

    private enum CodingKeys: String, CodingKey {
        case id, label, targetDate, isCountUp, fontSize, template
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        label = try container.decode(String.self, forKey: .label)
        isCountUp = try container.decode(Bool.self, forKey: .isCountUp)
        fontSize = try container.decode(CGFloat.self, forKey: .fontSize)
        template = try container.decode(String.self, forKey: .template)

        // Handle the date format (appears to be TimeInterval since reference date)
        let timeInterval = try container.decode(Double.self, forKey: .targetDate)
        targetDate = Date(timeIntervalSinceReferenceDate: timeInterval)
    }

    var displayText: String {
        let now = Date()
        let timeInterval: TimeInterval

        if isCountUp {
            timeInterval = now.timeIntervalSince(targetDate)
        } else {
            timeInterval = targetDate.timeIntervalSince(now)
        }

        let absInterval = abs(timeInterval)
        let days = Int(absInterval) / 86400
        let hours = Int(absInterval) % 86400 / 3600
        let minutes = Int(absInterval) % 3600 / 60
        let seconds = Int(absInterval) % 60

        var components: [String] = []
        if days > 0 { components.append("\(days)d") }
        if hours > 0 || days > 0 { components.append("\(hours)h") }
        if minutes > 0 || hours > 0 || days > 0 { components.append("\(minutes)m") }
        components.append("\(seconds)s")

        let timeString = components.joined(separator: " ")

        if isCountUp {
            return "\(label): +\(timeString)"
        } else {
            if timeInterval < 0 {
                return "\(label): Completed!"
            } else {
                return "\(label): \(timeString)"
            }
        }
    }
}

// Simplified SwiftUI View
struct SimpleScreensaverContentView: View {
    let timers: [SimpleTimer]

    var body: some View {
        ZStack {
            // Solid black background
            Rectangle()
                .fill(Color.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)

            VStack(spacing: 30) {
                Text("Countdown Screensaver")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Found \(timers.count) timers")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)

                if timers.isEmpty {
                    Text("No timers loaded")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else {
                    // Show just the first 3 timers to avoid clipping
                    VStack(spacing: 20) {
                        ForEach(Array(timers.prefix(3).enumerated()), id: \.element.id) { index, timer in
                            VStack(spacing: 10) {
                                Text("Timer \(index + 1): \(timer.label)")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.cyan)
                                    .multilineTextAlignment(.center)

                                Text(timer.displayText)
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .padding(15)
                                    .background(Color.blue.opacity(0.4))
                                    .cornerRadius(12)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        if timers.count > 3 {
                            Text("... and \(timers.count - 3) more timers")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(40)
        }
    }
}
