import SwiftUI
import Foundation

// MARK: - Data Extension for Hex Conversion

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
            let j = hexString.index(i, offsetBy: 2)
            let bytes = hexString[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}

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
            return Color(hex: "#06D6A0") // Vibrant Teal
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
    var priority: Int
    var fontSize: CGFloat
    var template: TimerTemplate
    var isCountUp: Bool

    // Legacy properties for backward compatibility
    var textColor: Color?
    var fontDesign: Font.Design?
    var customFontName: String?

    var displayColor: Color {
        return textColor ?? template.color
    }

    var displayFontName: String {
        return customFontName ?? template.fontName
    }

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

        let years = Int(absInterval) / 31536000
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

        components.append("\(seconds)s")

        let timeString = components.joined(separator: " ")

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

        let rgbColor = uiColor.usingColorSpace(.deviceRGB) ?? uiColor
        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        try container.encode(Double(red), forKey: .red)
        try container.encode(Double(green), forKey: .green)
        try container.encode(Double(blue), forKey: .blue)
        try container.encode(Double(alpha), forKey: .alpha)
    }
}

// MARK: - Layout Engine

struct TimerLayout {
    let timer: CountdownTimer
    let position: CGPoint
    let fontSize: CGFloat
}

enum LayoutAlgorithm: String, CaseIterable {
    case greedySpiral = "Greedy Spiral"
    case vertical = "Vertical Stack"
}

class LayoutEngine: ObservableObject {
    @Published var currentAlgorithm: LayoutAlgorithm = .greedySpiral

    func calculateLayout(for timers: [CountdownTimer], in screenSize: CGSize) -> [TimerLayout] {
        switch currentAlgorithm {
        case .greedySpiral:
            return greedySpiralLayout(timers: timers, screenSize: screenSize)
        case .vertical:
            return verticalLayout(timers: timers, screenSize: screenSize)
        }
    }

    private func greedySpiralLayout(timers: [CountdownTimer], screenSize: CGSize) -> [TimerLayout] {
        var layouts: [TimerLayout] = []
        let sortedTimers = timers.sorted { $0.priority > $1.priority }

        for (index, timer) in sortedTimers.enumerated() {
            let scaleFactor = 1.0 - (Double(index) * 0.15)
            let fontSize = max(timer.fontSize * scaleFactor, 16.0)

            let angle = Double(index) * 0.5
            let radius = 100.0 + Double(index) * 50.0

            let x = screenSize.width / 2 + radius * cos(angle)
            let y = screenSize.height / 2 + radius * sin(angle)

            let position = CGPoint(x: x, y: y)

            layouts.append(TimerLayout(
                timer: timer,
                position: position,
                fontSize: fontSize
            ))
        }

        return layouts
    }

    private func verticalLayout(timers: [CountdownTimer], screenSize: CGSize) -> [TimerLayout] {
        var layouts: [TimerLayout] = []
        let sortedTimers = timers.sorted { $0.priority > $1.priority }

        let totalHeight = CGFloat(sortedTimers.count) * 80.0
        let startY = (screenSize.height - totalHeight) / 2

        for (index, timer) in sortedTimers.enumerated() {
            let scaleFactor = 1.0 - (Double(index) * 0.1)
            let fontSize = max(timer.fontSize * scaleFactor, 16.0)

            let y = startY + CGFloat(index) * 80.0
            let position = CGPoint(x: screenSize.width / 2, y: y)

            layouts.append(TimerLayout(
                timer: timer,
                position: position,
                fontSize: fontSize
            ))
        }

        return layouts
    }
}
