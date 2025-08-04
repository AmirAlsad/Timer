import ScreenSaver
import SwiftUI
import Cocoa
import Foundation
import Combine

// MARK: - SwiftUI Screensaver (Using NSHostingController)

@objc(CountdownScreensaverViewSwiftUI)
public class CountdownScreensaverViewSwiftUI: ScreenSaverView {

    private var hostingController: NSHostingController<ScreensaverContentView>?

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setupSwiftUIView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSwiftUIView()
    }

    private func setupSwiftUIView() {
        NSLog("🔧 CountdownScreensaver: Setting up SwiftUI screensaver...")

        // Enable layer-backed view for better rendering compatibility with SwiftUI
        wantsLayer = true

        // Create SwiftUI content view
        let contentView = ScreensaverContentView()
        let hostingController = NSHostingController(rootView: contentView)

        // Set frame directly to bounds and enable autoresizing
        hostingController.view.frame = bounds
        hostingController.view.autoresizingMask = [.width, .height]
        addSubview(hostingController.view)

        self.hostingController = hostingController

        NSLog("✅ CountdownScreensaver: SwiftUI setup complete")
    }

    // MARK: - Configuration

    public override var hasConfigureSheet: Bool {
        return true
    }

                public override var configureSheet: NSWindow? {
        NSLog("⚙️ CountdownScreensaver: Showing configuration instructions...")

        // Create a simple alert with instructions
        let alert = NSAlert()
        alert.messageText = "Countdown Screensaver Settings"
        alert.informativeText = """
        To configure your countdown timers:

        1. Look for the timer icon (⏲) in your menu bar
        2. Click it and select "Settings"

        Or open the Countdown Wallpaper app directly from your Applications folder.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Open App")

        let response = alert.runModal()

        if response == .alertSecondButtonReturn {
            // User clicked "Open App" - try to launch it
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.countdownwallpaper.app") ??
                           NSWorkspace.shared.urlForApplication(toOpen: URL(fileURLWithPath: "/Applications/Countdown Wallpaper.app")) {

                let configuration = NSWorkspace.OpenConfiguration()
                configuration.activates = true

                NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { app, error in
                    if let error = error {
                        NSLog("❌ CountdownScreensaver: Failed to open app: \(error)")
                    } else {
                        NSLog("✅ CountdownScreensaver: App opened successfully")
                    }
                }
            }
        }

        return nil
    }
}

// MARK: - SwiftUI Content View (Replicating Wallpaper Design)

struct ScreensaverContentView: View {
    @StateObject private var countdownStore = ScreensaverCountdownStore()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Solid black background for screensaver
                Color.black
                    .ignoresSafeArea(.all)

                // Display all timers using calculated layouts (same as wallpaper)
                ForEach(countdownStore.timerLayouts, id: \.timer.id) { layout in
                    ScreensaverTimerDisplayView(
                        timer: layout.timer,
                        fontSize: layout.fontSize,
                        lastUpdate: countdownStore.lastUpdate
                    )
                    .position(layout.position)
                    .zIndex(Double(layout.timer.priority))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                // Update screen size when view appears
                countdownStore.setScreenSize(geometry.size)
                NSLog("👀 CountdownScreensaver SwiftUI: View appeared with size \(geometry.size)")

                // Force reload for preview mode
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    countdownStore.forceReload()
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                // Update screen size when geometry changes
                countdownStore.setScreenSize(newSize)
                NSLog("📐 CountdownScreensaver SwiftUI: Size changed to \(newSize)")
            }
        }
        .ignoresSafeArea(.all)
    }
}

// MARK: - Timer Display View (Matching Wallpaper Design)

struct ScreensaverTimerDisplayView: View {
    let timer: CountdownTimer
    let fontSize: CGFloat
    let lastUpdate: Date // Force updates when this changes

    var body: some View {
        Text(timer.displayText)
            .font(.custom(timer.displayFontName, size: fontSize).weight(timer.template.fontWeight))
            .foregroundColor(timer.displayColor)
            .shadow(color: .black.opacity(0.7), radius: 2, x: 1, y: 1)
            .padding(8)
            .background(
                // Semi-transparent background for readability (same as wallpaper)
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.3))
                    .blur(radius: 1)
            )
    }
}

// MARK: - Screensaver-Specific Store (ObservableObject)

class ScreensaverCountdownStore: ObservableObject {
    @Published var timers: [CountdownTimer] = []
    @Published var timerLayouts: [TimerLayout] = []
    @Published var lastUpdate: Date = Date()

    private var layoutEngine = LayoutEngine()
    private var updateTimer: Timer?
    private var reloadTimer: Timer?
    private var currentScreenSize: CGSize = CGSize(width: 1920, height: 1080) // Store actual screen size
    private var isPreviewMode: Bool = false

    init() {
        NSLog("🎬 CountdownScreensaver SwiftUI: Initializing store...")
        loadTimers()
        startUpdateTimer()
        startReloadTimer()
        updateLayouts() // Will use default screen size initially, updated when view appears
    }

    deinit {
        updateTimer?.invalidate()
        reloadTimer?.invalidate()
    }

    func setScreenSize(_ size: CGSize) {
        // Store the actual screen size
        currentScreenSize = size
        updateLayouts(for: size)
        NSLog("📏 CountdownScreensaver SwiftUI: Screen size set to \(size)")

        // Force reload timers when screen size changes (helps with preview)
        loadTimers()
    }

    func forceReload() {
        NSLog("🔄 CountdownScreensaver SwiftUI: Force reload requested")
        loadTimers()
    }

    private func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.lastUpdate = Date()
            }
        }
    }

    private func startReloadTimer() {
        reloadTimer?.invalidate()
        reloadTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            NSLog("⏰ CountdownScreensaver SwiftUI: Reload timer triggered")
            DispatchQueue.main.async {
                self?.loadTimers()
            }
        }

        // Ensure timer runs in all run loop modes (important for preview)
        if let timer = reloadTimer {
            RunLoop.main.add(timer, forMode: .common)
            NSLog("✅ CountdownScreensaver SwiftUI: Reload timer started (5s interval)")
        }
    }

    private func updateLayouts(for screenSize: CGSize? = nil) {
        // Use provided size or fall back to stored current screen size
        let effectiveScreenSize = screenSize ?? currentScreenSize

        guard !timers.isEmpty else {
            timerLayouts = []
            return
        }

        // Use the sophisticated layout engine (same as main wallpaper app)
        timerLayouts = layoutEngine.calculateLayout(for: timers, in: effectiveScreenSize)

        NSLog("🎯 CountdownScreensaver: Updated SwiftUI layouts for \(timerLayouts.count) timers at size \(effectiveScreenSize)")
    }

        private func loadTimers() {
        let loadStartTime = Date()
        NSLog("🔍 CountdownScreensaver SwiftUI: Loading timers... (Current count: \(timers.count))")

        // Method 1: Try reading from /tmp (shared location)
        let tmpPath = "/tmp/CountdownWallpaper/timers.json"
        do {
            let timerFileURL = URL(fileURLWithPath: tmpPath)

            // Check file existence and modification date
            let fileExists = FileManager.default.fileExists(atPath: timerFileURL.path)
            NSLog("📂 CountdownScreensaver SwiftUI: /tmp file exists: \(fileExists)")

            if fileExists {
                let attributes = try FileManager.default.attributesOfItem(atPath: timerFileURL.path)
                if let modDate = attributes[.modificationDate] as? Date {
                    NSLog("📅 CountdownScreensaver SwiftUI: /tmp file modified: \(modDate)")
                }

                let data = try Data(contentsOf: timerFileURL)
                NSLog("📱 CountdownScreensaver SwiftUI: Found timer file (\(data.count) bytes)")

                let decoder = JSONDecoder()

                // Try new format first (ScreensaverData with layout algorithm)
                if let screensaverData = try? decoder.decode(ScreensaverData.self, from: data) {
                    let newTimers = screensaverData.timers
                    let newLayout = screensaverData.layoutAlgorithm

                    // Check if anything changed
                    let timersChanged = newTimers.count != timers.count ||
                                      !zip(newTimers, timers).allSatisfy { $0.id == $1.id }
                    let layoutChanged = newLayout != layoutEngine.currentAlgorithm

                    DispatchQueue.main.async {
                        let oldCount = self.timers.count
                        let oldLayout = self.layoutEngine.currentAlgorithm

                        self.timers = newTimers
                        if layoutChanged {
                            NSLog("🔄 CountdownScreensaver SwiftUI: Layout changed from \(oldLayout.rawValue) to \(newLayout.rawValue)")
                            self.layoutEngine.currentAlgorithm = newLayout
                        }
                        self.updateLayouts() // Will use stored current screen size

                        let loadTime = Date().timeIntervalSince(loadStartTime) * 1000
                        NSLog("✅ CountdownScreensaver SwiftUI: Loaded \(newTimers.count) timers with \(newLayout.rawValue) layout (was \(oldCount), timers changed: \(timersChanged), layout changed: \(layoutChanged), took: \(Int(loadTime))ms)")

                        // Force UI update
                        self.objectWillChange.send()
                    }
                    return
                }

                // Fallback: Try old format (just timers array)
                else if let newTimers = try? decoder.decode([CountdownTimer].self, from: data) {
                    NSLog("⚠️ CountdownScreensaver SwiftUI: Using old format (timers only), defaulting to Spiral layout")

                    let timersChanged = newTimers.count != timers.count ||
                                      !zip(newTimers, timers).allSatisfy { $0.id == $1.id }

                    DispatchQueue.main.async {
                        let oldCount = self.timers.count
                        self.timers = newTimers
                        self.layoutEngine.currentAlgorithm = .greedySpiral // Default for old format
                        self.updateLayouts() // Will use stored current screen size

                        let loadTime = Date().timeIntervalSince(loadStartTime) * 1000
                        NSLog("✅ CountdownScreensaver SwiftUI: Loaded \(newTimers.count) timers (old format, was \(oldCount), changed: \(timersChanged), took: \(Int(loadTime))ms)")

                        // Force UI update
                        self.objectWillChange.send()
                    }
                    return
                } else {
                    NSLog("❌ CountdownScreensaver SwiftUI: Could not decode timer data in any format")
                }
            } else {
                NSLog("📂 CountdownScreensaver SwiftUI: Timer file does not exist at: \(tmpPath)")
            }
        } catch {
            NSLog("❌ CountdownScreensaver SwiftUI: /tmp file read error: \(error)")
        }

                // Method 2: Fallback to Application Support (backward compatibility - likely old format)
        do {
            let fileManager = FileManager.default
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDirectory = appSupportURL.appendingPathComponent("CountdownWallpaper")
            let timerFileURL = appDirectory.appendingPathComponent("timers.json")
            let fallbackPath = timerFileURL.path

            NSLog("📂 CountdownScreensaver SwiftUI: Checking fallback at: \(fallbackPath)")

            if fileManager.fileExists(atPath: fallbackPath) {
                let attributes = try fileManager.attributesOfItem(atPath: fallbackPath)
                if let modDate = attributes[.modificationDate] as? Date {
                    NSLog("📅 CountdownScreensaver SwiftUI: Fallback file modified: \(modDate)")
                }

                let data = try Data(contentsOf: timerFileURL)
                let decoder = JSONDecoder()

                // Fallback location is likely old format, but try new format first just in case
                if let screensaverData = try? decoder.decode(ScreensaverData.self, from: data) {
                    let newTimers = screensaverData.timers
                    let newLayout = screensaverData.layoutAlgorithm

                    DispatchQueue.main.async {
                        let oldCount = self.timers.count
                        self.timers = newTimers
                        self.layoutEngine.currentAlgorithm = newLayout
                        self.updateLayouts() // Will use stored current screen size

                        let loadTime = Date().timeIntervalSince(loadStartTime) * 1000
                        NSLog("✅ CountdownScreensaver SwiftUI: Loaded \(newTimers.count) timers with \(newLayout.rawValue) layout from fallback (was \(oldCount), took: \(Int(loadTime))ms)")

                        // Force UI update
                        self.objectWillChange.send()
                    }
                } else if let newTimers = try? decoder.decode([CountdownTimer].self, from: data) {
                    NSLog("⚠️ CountdownScreensaver SwiftUI: Fallback using old format (timers only)")

                    DispatchQueue.main.async {
                        let oldCount = self.timers.count
                        self.timers = newTimers
                        self.layoutEngine.currentAlgorithm = .greedySpiral // Default for old format
                        self.updateLayouts() // Will use stored current screen size

                        let loadTime = Date().timeIntervalSince(loadStartTime) * 1000
                        NSLog("✅ CountdownScreensaver SwiftUI: Loaded \(newTimers.count) timers from fallback (old format, was \(oldCount), took: \(Int(loadTime))ms)")

                        // Force UI update
                        self.objectWillChange.send()
                    }
                }
                return
            } else {
                NSLog("📂 CountdownScreensaver SwiftUI: Fallback file does not exist at: \(fallbackPath)")
            }
        } catch {
            NSLog("❌ CountdownScreensaver SwiftUI: Fallback file read error: \(error)")
        }

        NSLog("❌ CountdownScreensaver SwiftUI: No timer data found in any location (checked /tmp and ~/Library/Application Support)")
    }
}

// MARK: - Shared Models (Copy from main app for compatibility)

// Include necessary shared models here - these should match the main app exactly
// For now, using the existing shared models from SharedModels.swift

#Preview {
    ScreensaverContentView()
        .frame(width: 1920, height: 1080)
        .background(Color.black)
}
