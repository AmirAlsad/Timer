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
    private var countdownStore: SharedCountdownStore?

    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.animationTimeInterval = 1.0 // Update every second
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
        // Create the shared countdown store
        countdownStore = SharedCountdownStore()

        // Create SwiftUI view
        let contentView = ScreensaverContentView()
            .environmentObject(countdownStore!)
            .background(Color.black) // Solid black background

        // Create hosting view
        let hosting = NSHostingView(rootView: contentView)
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = self.bounds

        self.addSubview(hosting)
        self.hostingView = hosting

        // Start timer for updates
        startUpdateTimer()
    }

    private func startUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.countdownStore?.triggerUpdate()
        }
    }

    public override func startAnimation() {
        super.startAnimation()
        startUpdateTimer()
    }

    public override func stopAnimation() {
        super.stopAnimation()
        updateTimer?.invalidate()
    }

    public override var hasConfigureSheet: Bool {
        return true
    }

            public override var configureSheet: NSWindow? {
        let appBundleIdentifier = "com.countdownwallpaper.app"
        let appPath = "/Applications/Countdown Wallpaper.app"

        // Check if the app is already running
        let runningApps = NSWorkspace.shared.runningApplications
        let isAppRunning = runningApps.contains { app in
            app.bundleIdentifier == appBundleIdentifier
        }

        if isAppRunning {
            // App is running - open settings via menu bar extra
            let script = """
                tell application "System Events"
                    -- Look for the Countdown Wallpaper menu bar extra
                    tell process "Countdown Wallpaper"
                        try
                            -- Click on the menu bar extra (timer icon)
                            click menu bar item 1 of menu bar 1

                            -- Wait for menu to appear
                            delay 0.3

                            -- Click on Settings in the dropdown menu
                            click menu item "Settings" of menu 1 of menu bar item 1 of menu bar 1

                        on error theError
                            -- Fallback: try to activate app and use keyboard shortcut
                            tell application "Countdown Wallpaper" to activate
                            delay 0.5
                            -- Use Cmd+, which is common for opening preferences
                            key code 43 using command down
                        end try
                    end tell
                end tell
            """

            if let appleScript = NSAppleScript(source: script) {
                var errorDict: NSDictionary?
                appleScript.executeAndReturnError(&errorDict)
                if let error = errorDict {
                    print("AppleScript error: \(error)")
                }
            }
        } else {
            // App is not running - launch it
            let appURL = URL(fileURLWithPath: appPath)
            NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration()) { (app, error) in
                if let error = error {
                    print("Failed to open app: \(error)")
                }
            }
        }

        // Return nil since we're opening the main app instead of showing a sheet
        return nil
    }
}

// SwiftUI View for the screensaver content
struct ScreensaverContentView: View {
    @EnvironmentObject var countdownStore: SharedCountdownStore

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Solid black background
                Color.black
                    .ignoresSafeArea(.all)

                // Debug overlay to show we're rendering
                if countdownStore.timerLayouts.isEmpty {
                    VStack {
                        Text("Countdown Screensaver")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text("Loading timers...")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Found \(countdownStore.timers.count) timers")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                } else {
                    // Display all timers using calculated layouts
                    ForEach(countdownStore.timerLayouts, id: \.timer.id) { layout in
                        TimerDisplayView(
                            timer: layout.timer,
                            fontSize: layout.fontSize,
                            lastUpdate: countdownStore.lastUpdate
                        )
                        .position(layout.position)
                        .zIndex(Double(layout.timer.priority))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                print("ScreensaverContentView appeared with geometry: \(geometry.size)")
                countdownStore.setScreenSize(geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                print("ScreensaverContentView geometry changed to: \(newSize)")
                countdownStore.setScreenSize(newSize)
            }
        }
    }
}

// Duplicate of TimerDisplayView for the screensaver
struct TimerDisplayView: View {
    let timer: CountdownTimer
    let fontSize: CGFloat
    let lastUpdate: Date

    var body: some View {
        Text(timer.displayText)
            .font(.custom(timer.displayFontName, size: fontSize).weight(timer.template.fontWeight))
            .foregroundColor(timer.displayColor)
            .shadow(color: .black.opacity(0.7), radius: 2, x: 1, y: 1)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.3))
                    .blur(radius: 1)
            )
    }
}

// Shared countdown store that reads from the main app's UserDefaults
class SharedCountdownStore: ObservableObject {
    @Published var timers: [CountdownTimer] = []
    @Published var lastUpdate: Date = Date()
    @Published var timerLayouts: [TimerLayout] = []

    private var layoutEngine = LayoutEngine()
    private var screenSize: CGSize = CGSize(width: 1920, height: 1080)

    // UserDefaults suite shared with the main app
    private let sharedDefaults = UserDefaults(suiteName: "com.countdownwallpaper.app")

    private var reloadTimer: Timer?

    init() {
        loadTimers()
        updateLayouts()

        // Reload timers periodically in case they're updated
        reloadTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.loadTimers()
            self?.updateLayouts()
        }
    }

    deinit {
        reloadTimer?.invalidate()
    }

    func triggerUpdate() {
        lastUpdate = Date()
    }

    func setScreenSize(_ size: CGSize) {
        screenSize = size
        updateLayouts()
    }

    private func updateLayouts() {
        timerLayouts = layoutEngine.calculateLayout(for: timers, in: screenSize)
    }

        private func loadTimers() {
        print("🔍 Loading timers...")

        // Try multiple approaches to load timer data
        let appBundleIdentifier = "com.countdownwallpaper.app"

        // Method 1: Try reading directly from app's UserDefaults domain
        if let appDefaults = UserDefaults(suiteName: appBundleIdentifier),
           let data = appDefaults.data(forKey: "SavedTimers") {
            print("📱 Found timer data in app suite defaults (\(data.count) bytes)")
            do {
                timers = try JSONDecoder().decode([CountdownTimer].self, from: data)
                print("✅ Successfully loaded \(timers.count) timers from app suite")
                return
            } catch {
                print("❌ Failed to decode from app suite: \(error)")
            }
        }

        // Method 2: Read the app's specific defaults domain
        let appUserDefaults = UserDefaults()
        appUserDefaults.addSuite(named: appBundleIdentifier)
        if let data = appUserDefaults.data(forKey: "SavedTimers") {
            print("📱 Found timer data in named suite (\(data.count) bytes)")
            do {
                timers = try JSONDecoder().decode([CountdownTimer].self, from: data)
                print("✅ Successfully loaded \(timers.count) timers from named suite")
                return
            } catch {
                print("❌ Failed to decode from named suite: \(error)")
            }
        }

        // Method 3: Use defaults command to read the data
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", appBundleIdentifier, "SavedTimers"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            print("📱 Defaults command output length: \(output.count)")

            // Parse the hex data from defaults output
            if let hexData = extractHexDataFromDefaultsOutput(output) {
                print("📱 Extracted hex data (\(hexData.count) bytes)")
                do {
                    timers = try JSONDecoder().decode([CountdownTimer].self, from: hexData)
                    print("✅ Successfully loaded \(timers.count) timers from defaults command")
                    return
                } catch {
                    print("❌ Failed to decode from defaults command: \(error)")
                }
            }
        } catch {
            print("❌ Failed to run defaults command: \(error)")
        }

        // Method 4: Try standard UserDefaults as final fallback
        if let data = UserDefaults.standard.data(forKey: "SavedTimers") {
            print("📱 Found timer data in standard defaults (\(data.count) bytes)")
            do {
                timers = try JSONDecoder().decode([CountdownTimer].self, from: data)
                print("✅ Successfully loaded \(timers.count) timers from standard defaults")
                return
            } catch {
                print("❌ Failed to decode from standard defaults: \(error)")
            }
        }

        print("❌ No timer data found in any location")
    }

    private func extractHexDataFromDefaultsOutput(_ output: String) -> Data? {
        // Parse the defaults output format: {length = 2084, bytes = 0x5b7b2269...}
        let lines = output.components(separatedBy: .newlines)
        var hexString = ""

        for line in lines {
            if line.contains("0x") {
                // Extract hex part after 0x
                let parts = line.components(separatedBy: "0x")
                for i in 1..<parts.count {
                    let hexPart = parts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    // Remove any trailing characters that aren't hex
                    let cleanHex = hexPart.components(separatedBy: CharacterSet(charactersIn: "0123456789abcdefABCDEF").inverted)[0]
                    hexString += cleanHex
                }
            }
        }

        // Convert hex string to Data
        if !hexString.isEmpty {
            return Data(hexString: hexString)
        }

        return nil
    }
}
