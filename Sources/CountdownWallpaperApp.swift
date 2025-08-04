import SwiftUI
import AppKit

@main
struct CountdownWallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var countdownStore = CountdownStore()

    var body: some Scene {
        // Pass the countdown store to the app delegate
        let _ = appDelegate.setCountdownStore(countdownStore)

        // Main settings window (shows by default)
        WindowGroup("Countdown Wallpaper", id: "settings") {
            SettingsView()
                .environmentObject(countdownStore)
                .onAppear {
                    // Ensure window appears on top when opened
                    DispatchQueue.main.async {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }
                }
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1000, height: 700)

        // Menu bar extra for convenient access
        MenuBarExtra("Countdown Wallpaper", systemImage: "timer") {
            MenuBarContent()
                .environmentObject(countdownStore)
        }
    }
}

struct MenuBarContent: View {
    @EnvironmentObject var countdownStore: CountdownStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Settings") {
            openWindow(id: "settings")
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindow: NSWindow?
    var countdownStore: CountdownStore?

    func setCountdownStore(_ store: CountdownStore) {
        self.countdownStore = store
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Delay setup to ensure countdown store is set
        DispatchQueue.main.async {
            self.setupOverlayWindow()
        }

        // Make the app appear in the dock like a normal app
        NSApp.setActivationPolicy(.regular)
    }

    private func setupOverlayWindow() {
        guard let screen = NSScreen.main,
              let store = countdownStore else {
            print("Error: Screen or CountdownStore not available")
            return
        }

        // Create a borderless, transparent window that covers the entire screen
        overlayWindow = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        guard let window = overlayWindow else { return }

        // Configure window to act as desktop overlay
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // Set up the SwiftUI content view with the shared store
        let contentView = OverlayView()
            .environmentObject(store)

        window.contentView = NSHostingView(rootView: contentView)
        window.orderFront(nil)

        // Ensure window stays in position
        window.setFrame(screen.frame, display: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when settings window is closed - app should continue running in background
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When user clicks on the app icon, show settings if no windows are visible
        if !flag {
            if let window = NSApp.windows.first(where: { $0.title == "Countdown Settings" }) {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }
}
