import SwiftUI
import Foundation
import Combine

// MARK: - Timer Template System

enum TimerTemplate: String, CaseIterable, Codable {
    case anticipation = "The Anticipation"
    case deadline = "The Deadline"
    case mementoMori = "Memento Mori"
    case legacy = "The Legacy"

    var color: Color {
        switch self {
        case .anticipation:
            return Color(hex: "#FF6B6B") // Energetic Coral
        case .deadline:
            return Color(hex: "#FF3B30") // Action Red
        case .mementoMori:
            return Color(hex: "##06D6A0") // Vibrant Teal
        case .legacy:
            return Color(hex: "#118AB2") // Clarity Blue
        }
    }

    var fontName: String {
        switch self {
        case .anticipation:
            return "Quicksand"
        case .deadline:
            return "Montserrat"
        case .mementoMori:
            return "EB Garamond"
        case .legacy:
            return "Lora"
        }
    }

    var fontWeight: Font.Weight {
        switch self {
        case .deadline:
            return .bold
        default:
            return .medium
        }
    }

    var description: String {
        switch self {
        case .anticipation:
            return "Positive excitement, joy, and looking forward to fun events."
        case .deadline:
            return "Urgency, focus, and the need for action. Commands attention."
        case .mementoMori:
            return "Reflection, mortality, and introspection. Somber and profound."
        case .legacy:
            return "Long-term journey with stability, pride, and history."
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Countdown Timer Data Model

struct CountdownTimer: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    var label: String
    var targetDate: Date
    var position: CGPoint
    var priority: Int // Higher number = higher priority (more prominent)
    var fontSize: CGFloat
    var template: TimerTemplate // Template defining color and font
    var isCountUp: Bool // false for countdown, true for count-up (like age)

    // Legacy properties for backward compatibility
    var textColor: Color?
    var fontDesign: Font.Design?
    var customFontName: String?

    init(
        label: String,
        targetDate: Date,
        position: CGPoint = CGPoint(x: 400, y: 300),
        priority: Int = 1,
        fontSize: CGFloat = 24,
        template: TimerTemplate = .anticipation,
        isCountUp: Bool = false
    ) {
        self.id = UUID()
        self.label = label
        self.targetDate = targetDate
        self.position = position
        self.priority = priority
        self.fontSize = fontSize
        self.template = template
        self.isCountUp = isCountUp

        // Legacy properties set to nil for new timers
        self.textColor = nil
        self.fontDesign = nil
        self.customFontName = nil
    }

    // Computed properties that use template or fall back to legacy
    var displayColor: Color {
        return textColor ?? template.color
    }

    var displayFontName: String {
        return customFontName ?? template.fontName
    }

    // Computed property to get the formatted time display
    var displayText: String {
        let now = Date()
        let timeInterval: TimeInterval

        if isCountUp {
            timeInterval = now.timeIntervalSince(targetDate)
        } else {
            timeInterval = targetDate.timeIntervalSince(now)
        }

        return formatTimeInterval(timeInterval)
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let absInterval = abs(interval)

        let years = Int(absInterval) / 31536000 // 365 days * 24 hours * 60 minutes * 60 seconds
        let days = Int(absInterval) % 31536000 / 86400
        let hours = Int(absInterval) % 86400 / 3600
        let minutes = Int(absInterval) % 3600 / 60
        let seconds = Int(absInterval) % 60

        var components: [String] = []

        if years > 0 {
            components.append("\(years)y")
        }
        if days > 0 || years > 0 {
            components.append("\(days)d")
        }
        if hours > 0 || days > 0 || years > 0 {
            components.append("\(hours)h")
        }
        if minutes > 0 || hours > 0 || days > 0 || years > 0 {
            components.append("\(minutes)m")
        }

        // Always show seconds
        components.append("\(seconds)s")

        let timeString = components.joined(separator: " ")

        // Add prefix for count-up vs countdown
        if isCountUp {
            return "\(label): +\(timeString)"
        } else {
            if interval < 0 {
                return "\(label): Completed!"
            } else {
                return "\(label): \(timeString)"
            }
        }
    }
}

// MARK: - Font.Design Codable Extension

extension Font.Design: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "default":
            self = .default
        case "serif":
            self = .serif
        case "rounded":
            self = .rounded
        case "monospaced":
            self = .monospaced
        default:
            self = .default
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .default:
            try container.encode("default")
        case .serif:
            try container.encode("serif")
        case .rounded:
            try container.encode("rounded")
        case .monospaced:
            try container.encode("monospaced")
        @unknown default:
            try container.encode("default")
        }
    }
}

// MARK: - Color Codable Extension

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decode(Double.self, forKey: .alpha)

        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let uiColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        // Convert to RGB colorspace if needed to handle system/dynamic colors
        let rgbColor = uiColor.usingColorSpace(.deviceRGB) ?? uiColor
        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        try container.encode(Double(red), forKey: .red)
        try container.encode(Double(green), forKey: .green)
        try container.encode(Double(blue), forKey: .blue)
        try container.encode(Double(alpha), forKey: .alpha)
    }
}

// MARK: - Shared Data Structure for Screensaver

struct ScreensaverData: Codable {
    let timers: [CountdownTimer]
    let layoutAlgorithm: LayoutAlgorithm
    let version: Int = 1 // For future compatibility

    init(timers: [CountdownTimer], layoutAlgorithm: LayoutAlgorithm) {
        self.timers = timers
        self.layoutAlgorithm = layoutAlgorithm
    }
}

// MARK: - Data Store

class CountdownStore: ObservableObject {
    @Published var timers: [CountdownTimer] = []
    @Published var lastUpdate: Date = Date() // Force UI updates
    @Published var timerLayouts: [TimerLayout] = [] // Calculated layouts
    private var layoutEngine = LayoutEngine()
    private var updateTimer: Timer?
    private var screenSize: CGSize = CGSize(width: 1920, height: 1080) // Default screen size

    init() {
        loadTimers()
        startUpdateTimer()

        // Add some default timers for testing
        if timers.isEmpty {
            addDefaultTimers()
        }

        // Calculate initial layouts
        updateLayouts()

        // IMPORTANT: Create /tmp file on startup for screensaver access
        saveTimers()

        // Listen for layout algorithm changes
        layoutEngine.$currentAlgorithm.sink { [weak self] (_: LayoutAlgorithm) in
            DispatchQueue.main.async {
                self?.updateLayouts()
            }
        }.store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    deinit {
        updateTimer?.invalidate()
    }

    private func startUpdateTimer() {
        // Invalidate any existing timer
        updateTimer?.invalidate()

        // Update every second for good performance and battery life
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.triggerUpdate()
            }
        }

        // Ensure timer runs on main run loop with common mode to keep running during UI interactions
        if let timer = updateTimer {
            RunLoop.main.add(timer, forMode: .common)
        }

        print("Timer started successfully") // Debug
    }

    private func triggerUpdate() {
        // Force SwiftUI to update by updating the lastUpdate published property
        lastUpdate = Date()
        print("Timer triggered update at: \(lastUpdate)") // Debug
    }

    func addTimer(_ timer: CountdownTimer) {
        NSLog("➕ CountdownApp: addTimer() called - adding '\(timer.label)' (total will be \(timers.count + 1))")
        timers.append(timer)
        updatePriorities() // Update priorities based on new order
        saveTimers()
        updateLayouts()
    }

    func removeTimer(_ timer: CountdownTimer) {
        timers.removeAll { $0.id == timer.id }
        updatePriorities() // Update priorities after removal
        saveTimers()
        updateLayouts()
    }



    func moveTimer(from source: IndexSet, to destination: Int) {
        timers.move(fromOffsets: source, toOffset: destination)
        updatePriorities() // Update priorities based on new order
        saveTimers()
        updateLayouts()
    }

    func moveTimerUp(timer: CountdownTimer) {
        guard let currentIndex = timers.firstIndex(where: { $0.id == timer.id }),
              currentIndex > 0 else { return }

        // Swap with the item above
        timers.swapAt(currentIndex, currentIndex - 1)
        updatePriorities()
        saveTimers()
        updateLayouts()
    }

    func moveTimerDown(timer: CountdownTimer) {
        guard let currentIndex = timers.firstIndex(where: { $0.id == timer.id }),
              currentIndex < timers.count - 1 else { return }

        // Swap with the item below
        timers.swapAt(currentIndex, currentIndex + 1)
        updatePriorities()
        saveTimers()
        updateLayouts()
    }

    func updateTimer(_ timer: CountdownTimer) {
        if let index = timers.firstIndex(where: { $0.id == timer.id }) {
            timers[index] = timer
            saveTimers()
            updateLayouts()
        }
    }

    private func updatePriorities() {
        // Update priorities based on position in array (first = highest priority)
        for (index, timer) in timers.enumerated() {
            var updatedTimer = timer
            updatedTimer.priority = timers.count - index // Reverse order: first item gets highest number
            timers[index] = updatedTimer
        }
    }

    func setScreenSize(_ size: CGSize) {
        screenSize = size
        updateLayouts()
    }

    var currentLayoutAlgorithm: LayoutAlgorithm {
        get { layoutEngine.currentAlgorithm }
        set {
            layoutEngine.currentAlgorithm = newValue
            // Save the layout choice and force layout update
            saveTimers()
            updateLayouts()
        }
    }

    private func updateLayouts() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timerLayouts = self.layoutEngine.calculateLayout(for: self.timers, in: self.screenSize)
        }
    }

    private func addDefaultTimers() {
        let newYear = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1)) ?? Date()
        let birthday = Calendar.current.date(from: DateComponents(year: 1990, month: 6, day: 15)) ?? Date()

        let defaultTimers = [
            CountdownTimer(
                label: "New Year 2025",
                targetDate: newYear,
                position: CGPoint(x: 400, y: 200),
                priority: 3,
                fontSize: 32,
                template: .anticipation,
                isCountUp: false
            ),
            CountdownTimer(
                label: "Age",
                targetDate: birthday,
                position: CGPoint(x: 400, y: 150),
                priority: 2,
                fontSize: 24,
                template: .mementoMori,
                isCountUp: true
            )
        ]

        timers = defaultTimers
        saveTimers()
    }

    // MARK: - Persistence

    // Shared UserDefaults suite for sharing data with screensaver
    private let sharedDefaults = UserDefaults(suiteName: "com.countdownwallpaper.app")

    private func saveTimers() {
        NSLog("💾 CountdownApp: saveTimers() called with \(timers.count) timers, layout: \(layoutEngine.currentAlgorithm.rawValue)")
        do {
            // Save timers only (for backward compatibility)
            let timerData = try JSONEncoder().encode(timers)
            sharedDefaults?.set(timerData, forKey: "SavedTimers")
            UserDefaults.standard.set(timerData, forKey: "SavedTimers")

            // Save combined data for screensaver
            let screensaverData = ScreensaverData(timers: timers, layoutAlgorithm: layoutEngine.currentAlgorithm)
            let combinedData = try JSONEncoder().encode(screensaverData)
            saveTimersToFile(data: combinedData)
            NSLog("✅ CountdownApp: Successfully saved \(timers.count) timers with \(layoutEngine.currentAlgorithm.rawValue) layout")
        } catch {
            NSLog("❌ CountdownApp: Failed to save timers: \(error)")
        }
    }

        private func saveTimersToFile(data: Data) {
        let fileManager = FileManager.default
        NSLog("📁 CountdownApp: saveTimersToFile() called with \(data.count) bytes")

        // Save to Application Support (original location)
        do {
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let appDirectory = appSupportURL.appendingPathComponent("CountdownWallpaper")

            try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)

            let timerFileURL = appDirectory.appendingPathComponent("timers.json")
            try data.write(to: timerFileURL)

            NSLog("✅ CountdownApp: Saved timers to Application Support: \(timerFileURL.path)")
        } catch {
            NSLog("❌ CountdownApp: Failed to save timers to Application Support: \(error)")
        }

        // ALSO save to /tmp (for screensaver access)
        do {
            let tmpURL = URL(fileURLWithPath: "/tmp/CountdownWallpaper")

            try fileManager.createDirectory(at: tmpURL, withIntermediateDirectories: true, attributes: nil)

            let tmpTimerFileURL = tmpURL.appendingPathComponent("timers.json")
            try data.write(to: tmpTimerFileURL)

            NSLog("✅ CountdownApp: Saved timers to /tmp: \(tmpTimerFileURL.path)")
        } catch {
            NSLog("❌ CountdownApp: Failed to save timers to /tmp: \(error)")
        }
    }

    private func loadTimers() {
        // Try shared suite first
        if let data = sharedDefaults?.data(forKey: "SavedTimers") {
            do {
                timers = try JSONDecoder().decode([CountdownTimer].self, from: data)
                return
            } catch {
                print("Failed to load timers from shared suite: \(error)")
            }
        }

        // Fallback to standard defaults
        guard let data = UserDefaults.standard.data(forKey: "SavedTimers") else { return }

        do {
            timers = try JSONDecoder().decode([CountdownTimer].self, from: data)
        } catch {
            print("Failed to load timers: \(error)")
        }
    }
}
