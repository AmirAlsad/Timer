import SwiftUI

struct OverlayView: View {
    @EnvironmentObject var countdownStore: CountdownStore

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clear background for wallpaper effect
                Color.clear
                    .ignoresSafeArea(.all)

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                // Update screen size when view appears
                countdownStore.setScreenSize(geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                // Update screen size when geometry changes
                countdownStore.setScreenSize(newSize)
            }
        }
        .ignoresSafeArea(.all)
    }
}

struct TimerDisplayView: View {
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
                // Semi-transparent background for readability
                RoundedRectangle(cornerRadius: 8)
                    .fill(.black.opacity(0.3))
                    .blur(radius: 1)
            )
    }
}

// Legacy initializer for compatibility
extension TimerDisplayView {
    init(timer: CountdownTimer, lastUpdate: Date) {
        self.timer = timer
        self.fontSize = timer.fontSize // Use manual font size as fallback
        self.lastUpdate = lastUpdate
    }
}

#Preview {
    OverlayView()
        .environmentObject(CountdownStore())
        .frame(width: 800, height: 600)
        .background(.blue.opacity(0.3)) // For preview purposes
}
