import SwiftUI
import Foundation

// MARK: - Layout Algorithm Types

enum LayoutAlgorithm: String, CaseIterable, Codable {
    case greedySpiral = "Greedy Spiral"
    case vertical = "Vertical"

    var description: String {
        switch self {
        case .greedySpiral:
            return "Classic word-cloud style with organic spiral placement"
        case .vertical:
            return "Clean vertical layout with highest priority timers at top"
        }
    }
}

// MARK: - Timer Layout Information

struct TimerLayout {
    let timer: CountdownTimer
    let position: CGPoint
    let fontSize: CGFloat
    let boundingBox: CGRect
}

// MARK: - Layout Engine

class LayoutEngine: ObservableObject {
    @Published var currentAlgorithm: LayoutAlgorithm = .greedySpiral {
        didSet {
            // Ensure the change is published
            objectWillChange.send()
        }
    }

    // Font size constraints
    private let minFontSize: CGFloat = 16
    private let maxFontSize: CGFloat = 118

    // Screen buffer/margin
    private let screenBuffer: CGFloat = 40

    // MARK: - Public Interface

    func calculateLayout(for timers: [CountdownTimer], in screenSize: CGSize) -> [TimerLayout] {
        guard !timers.isEmpty else { return [] }

        switch currentAlgorithm {
        case .greedySpiral:
            return calculateGreedySpiralLayout(for: timers, in: screenSize)
        case .vertical:
            return calculateVerticalLayout(for: timers, in: screenSize)
        }
    }

        // MARK: - Font Size Calculation (Logarithmic Scaling)

    private func calculateFontSize(for timer: CountdownTimer, among timers: [CountdownTimer], maxAllowedSize: CGFloat? = nil) -> CGFloat {
        guard !timers.isEmpty else { return minFontSize }

        let priorities = timers.map { $0.priority }
        let minPriority = priorities.min() ?? 1
        let maxPriority = priorities.max() ?? 1

        // Use dynamic max size if provided, otherwise use default
        let effectiveMaxSize = maxAllowedSize ?? maxFontSize

        // Avoid division by zero for single priority value
        if minPriority == maxPriority {
            return (minFontSize + effectiveMaxSize) / 2
        }

        // Normalize priority to 0.0-1.0 range
        let normalizedPriority = Double(timer.priority - minPriority) / Double(maxPriority - minPriority)

        let scale: Double

        // Use linear scaling for fewer than 4 timers, logarithmic for 4 or more
        if timers.count < 4 {
            // Linear scaling for small numbers of timers
            scale = normalizedPriority
        } else {
            // Apply logarithmic scaling: log(1 + x) where x is normalized priority
            // This creates a more gradual scaling compared to linear
            scale = log(1 + normalizedPriority * (M_E - 1)) / log(M_E)
        }

        // Map to font size range
        let fontSize = minFontSize + CGFloat(scale) * (effectiveMaxSize - minFontSize)

        return max(minFontSize, min(effectiveMaxSize, fontSize))
    }

    private func calculateDynamicMaxFontSize(for timers: [CountdownTimer], in screenSize: CGSize) -> CGFloat {
        guard !timers.isEmpty else { return maxFontSize }

        // Calculate available width (screen width minus buffers)
        let availableWidth = screenSize.width - (screenBuffer * 2)

        // Find the longest timer text
        let longestText = timers.map { $0.displayText }.max(by: { $0.count < $1.count }) ?? ""

        // Estimate character width at max font size
        let characterWidth = maxFontSize * 0.6 // Monospace character width approximation
        let estimatedWidth = CGFloat(longestText.count) * characterWidth + 32 // Include padding

        // If the longest text would exceed available width, scale down the max font size
        if estimatedWidth > availableWidth {
            let scaleFactor = availableWidth / estimatedWidth
            return max(minFontSize, maxFontSize * scaleFactor)
        }

        return maxFontSize
    }

        private func calculateBoundingBox(for timer: CountdownTimer, fontSize: CGFloat) -> CGSize {
        // Estimate text size (this is an approximation)
        let text = timer.displayText
        let characterWidth = fontSize * 0.6 // Approximate monospace character width
        let lineHeight = fontSize * 1.2 // Standard line height

        let estimatedWidth = CGFloat(text.count) * characterWidth + 32 // Add padding
        let estimatedHeight = lineHeight + 16 // Single line + padding

        return CGSize(width: estimatedWidth, height: estimatedHeight)
    }

        private func constrainToScreen(_ position: CGPoint, size: CGSize, screenSize: CGSize) -> CGPoint {
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2

        let constrainedX = max(screenBuffer + halfWidth, min(screenSize.width - screenBuffer - halfWidth, position.x))
        let constrainedY = max(screenBuffer + halfHeight, min(screenSize.height - screenBuffer - halfHeight, position.y))

        return CGPoint(x: constrainedX, y: constrainedY)
    }

    // MARK: - Greedy Spiral Algorithm

        private func calculateGreedySpiralLayout(for timers: [CountdownTimer], in screenSize: CGSize) -> [TimerLayout] {
        let center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        let sortedTimers = timers.sorted { $0.priority > $1.priority }

        // Calculate dynamic max font size to respect screen bounds
        let dynamicMaxSize = calculateDynamicMaxFontSize(for: timers, in: screenSize)

        var layouts: [TimerLayout] = []
        var placedRects: [CGRect] = []

        for timer in sortedTimers {
            let fontSize = calculateFontSize(for: timer, among: timers, maxAllowedSize: dynamicMaxSize)
            let boundingSize = calculateBoundingBox(for: timer, fontSize: fontSize)

            let position: CGPoint
            if layouts.isEmpty {
                // Place first timer at center
                position = center
            } else {
                // Find position using spiral search
                position = findSpiralPosition(
                    from: center,
                    size: boundingSize,
                    avoiding: placedRects,
                    screenSize: screenSize
                )
            }

                        // Constrain position to screen bounds
            let constrainedPosition = constrainToScreen(position, size: boundingSize, screenSize: screenSize)

            let boundingBox = CGRect(
                x: constrainedPosition.x - boundingSize.width / 2,
                y: constrainedPosition.y - boundingSize.height / 2,
                width: boundingSize.width,
                height: boundingSize.height
            )

            layouts.append(TimerLayout(
                timer: timer,
                position: constrainedPosition,
                fontSize: fontSize,
                boundingBox: boundingBox
            ))

            placedRects.append(boundingBox)
        }

        return layouts
    }

    private func findSpiralPosition(from center: CGPoint, size: CGSize, avoiding placedRects: [CGRect], screenSize: CGSize) -> CGPoint {
        let spiralStep: CGFloat = 5.0
        let maxRadius = max(screenSize.width, screenSize.height)
        var angle: CGFloat = 0
        var radius: CGFloat = 0

        while radius < maxRadius {
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)

            let testRect = CGRect(
                x: x - size.width / 2,
                y: y - size.height / 2,
                width: size.width,
                height: size.height
            )

            // Check if position is within screen bounds (including buffer)
            if testRect.minX >= screenBuffer && testRect.maxX <= screenSize.width - screenBuffer &&
               testRect.minY >= screenBuffer && testRect.maxY <= screenSize.height - screenBuffer {

                // Check for collisions with placed rectangles
                let hasCollision = placedRects.contains { rect in
                    testRect.intersects(rect)
                }

                if !hasCollision {
                    return CGPoint(x: x, y: y)
                }
            }

            // Update spiral parameters
            angle += 0.1
            radius += spiralStep * angle / (2 * .pi)
        }

        // Fallback to center if no position found
        return center
    }



    // MARK: - Vertical Layout Algorithm

    private func calculateVerticalLayout(for timers: [CountdownTimer], in screenSize: CGSize) -> [TimerLayout] {
        guard !timers.isEmpty else { return [] }

        // Sort timers by priority (highest first)
        let sortedTimers = timers.sorted { $0.priority > $1.priority }

        // Calculate dynamic max font size to respect screen bounds
        let dynamicMaxSize = calculateDynamicMaxFontSize(for: timers, in: screenSize)

        var layouts: [TimerLayout] = []

        // Calculate total height needed for all timers
        var totalHeight: CGFloat = 0
        var timerData: [(timer: CountdownTimer, fontSize: CGFloat, size: CGSize)] = []

        for timer in sortedTimers {
            let fontSize = calculateFontSize(for: timer, among: timers, maxAllowedSize: dynamicMaxSize)
            let size = calculateBoundingBox(for: timer, fontSize: fontSize)
            timerData.append((timer: timer, fontSize: fontSize, size: size))
            totalHeight += size.height
        }

        // Add spacing between timers (10pt between each timer)
        let spacing: CGFloat = 10
        if sortedTimers.count > 1 {
            totalHeight += CGFloat(sortedTimers.count - 1) * spacing
        }

        // Calculate available height (screen height minus buffers)
        let availableHeight = screenSize.height - (screenBuffer * 2)

        // Start positioning from top, centered horizontally
        let centerX = screenSize.width / 2
        var currentY = screenBuffer

        // If total height exceeds available height, distribute evenly
        if totalHeight > availableHeight {
            let adjustedSpacing = max(0, (availableHeight - timerData.reduce(0) { $0 + $1.size.height }) / max(1, CGFloat(sortedTimers.count - 1)))

            for (_, data) in timerData.enumerated() {
                let position = CGPoint(
                    x: centerX,
                    y: currentY + data.size.height / 2
                )

                let boundingBox = CGRect(
                    x: position.x - data.size.width / 2,
                    y: position.y - data.size.height / 2,
                    width: data.size.width,
                    height: data.size.height
                )

                layouts.append(TimerLayout(
                    timer: data.timer,
                    position: position,
                    fontSize: data.fontSize,
                    boundingBox: boundingBox
                ))

                currentY += data.size.height + adjustedSpacing
            }
        } else {
            // Center the entire block vertically
            let startY = screenBuffer + (availableHeight - totalHeight) / 2
            currentY = startY

            for data in timerData {
                let position = CGPoint(
                    x: centerX,
                    y: currentY + data.size.height / 2
                )

                let boundingBox = CGRect(
                    x: position.x - data.size.width / 2,
                    y: position.y - data.size.height / 2,
                    width: data.size.width,
                    height: data.size.height
                )

                layouts.append(TimerLayout(
                    timer: data.timer,
                    position: position,
                    fontSize: data.fontSize,
                    boundingBox: boundingBox
                ))

                currentY += data.size.height + spacing
            }
        }

        return layouts
    }
}
