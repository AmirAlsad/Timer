import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var countdownStore: CountdownStore
    @State private var selectedTimerID: UUID?
    @State private var isDeleteMode = false
    @State private var selectedTimersForDeletion: Set<UUID> = []

    var body: some View {
        NavigationSplitView {
            // Timer list sidebar
            VStack {
                // Layout Algorithm Selection with Icon Buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Layout Style")
                        .font(.headline)

                    HStack(spacing: 16) {
                        // Spiral Layout Button
                        Button(action: {
                            countdownStore.currentLayoutAlgorithm = .greedySpiral
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "hurricane")
                                    .font(.title2)
                                    .foregroundColor(countdownStore.currentLayoutAlgorithm == .greedySpiral ? .white : .secondary)
                                Text("Spiral")
                                    .font(.caption)
                                    .foregroundColor(countdownStore.currentLayoutAlgorithm == .greedySpiral ? .white : .secondary)
                            }
                            .frame(width: 80, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(countdownStore.currentLayoutAlgorithm == .greedySpiral ? Color.accentColor : Color.gray.opacity(0.2))
                            )
                        }
                        .buttonStyle(.plain)

                        // Vertical Layout Button
                        Button(action: {
                            countdownStore.currentLayoutAlgorithm = .vertical
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "list.bullet")
                                    .font(.title2)
                                    .foregroundColor(countdownStore.currentLayoutAlgorithm == .vertical ? .white : .secondary)
                                Text("Vertical")
                                    .font(.caption)
                                    .foregroundColor(countdownStore.currentLayoutAlgorithm == .vertical ? .white : .secondary)
                            }
                            .frame(width: 80, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(countdownStore.currentLayoutAlgorithm == .vertical ? Color.accentColor : Color.gray.opacity(0.2))
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }

                    Text(countdownStore.currentLayoutAlgorithm.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal)
                .padding(.top)

                Divider()

                                HStack {
                    Text("Countdown Timers")
                        .font(.headline)
                    Spacer()

                    if isDeleteMode {
                        // Delete mode buttons
                        Button("Cancel") {
                            isDeleteMode = false
                            selectedTimersForDeletion.removeAll()
                        }
                        .buttonStyle(.bordered)

                        Button("Delete Selected") {
                            deleteSelectedTimers()
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectedTimersForDeletion.isEmpty)
                        .foregroundColor(selectedTimersForDeletion.isEmpty ? .secondary : .white)
                        .background(selectedTimersForDeletion.isEmpty ? Color.gray.opacity(0.3) : Color.red)
                        .cornerRadius(6)
                    } else {
                        // Normal mode buttons
                        if !countdownStore.timers.isEmpty {
                            Button(action: {
                                isDeleteMode = true
                                selectedTimersForDeletion.removeAll()
                            }) {
                                Image(systemName: "trash")
                                    .font(.title2)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                            .help("Select timers to delete")
                        }

                        Button(action: {
                            createNewTimer()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .help("Add new timer")
                    }
                }
                .padding()

                                List(selection: $selectedTimerID) {
                    ForEach(countdownStore.timers, id: \.id) { timer in
                        HStack {
                            if isDeleteMode {
                                Button(action: {
                                    if selectedTimersForDeletion.contains(timer.id) {
                                        selectedTimersForDeletion.remove(timer.id)
                                    } else {
                                        selectedTimersForDeletion.insert(timer.id)
                                    }
                                }) {
                                    Image(systemName: selectedTimersForDeletion.contains(timer.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedTimersForDeletion.contains(timer.id) ? .blue : .secondary)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                            }

                                                        TimerRowView(
                                timer: timer,
                                isSelected: selectedTimerID == timer.id,
                                isDeleteMode: isDeleteMode,
                                onMoveUp: {
                                    moveTimerUp(timer: timer)
                                },
                                onMoveDown: {
                                    moveTimerDown(timer: timer)
                                },
                                canMoveUp: canMoveTimerUp(timer: timer),
                                canMoveDown: canMoveTimerDown(timer: timer)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !isDeleteMode {
                                    selectedTimerID = timer.id
                                }
                            }
                        }
                        .contextMenu {
                            if !isDeleteMode {
                                Button("Delete", role: .destructive) {
                                    countdownStore.removeTimer(timer)
                                    if selectedTimerID == timer.id {
                                        selectedTimerID = countdownStore.timers.first?.id
                                    }
                                }
                            }
                        }
                    }
                    .onMove(perform: isDeleteMode ? nil : moveTimers)
                }
                .listStyle(.sidebar)

                // Screensaver Controls Section
                VStack(alignment: .leading, spacing: 12) {
                    Divider()

                    Text("Screensaver")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    VStack(spacing: 8) {
                        Button(action: openScreensaverPreferences) {
                            HStack {
                                Image(systemName: "tv")
                                Text("Open Screensaver Preferences")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .padding(.horizontal)

                        if isScreensaverInstalled() {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Screensaver Installed")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Screensaver Not Installed")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Text("Run 'make install' in Screensaver folder")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 12)
                }
            }
        } detail: {
            // Timer detail/edit view
            if let selectedID = selectedTimerID,
               let timer = countdownStore.timers.first(where: { $0.id == selectedID }) {
                TimerEditView(timer: timer, selectedTimerID: $selectedTimerID)
                    .id(selectedID) // Force view refresh when selection changes
            } else {
                Text("Select a timer to edit")
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .onAppear {
            // Select first timer if none selected
            if selectedTimerID == nil && !countdownStore.timers.isEmpty {
                selectedTimerID = countdownStore.timers.first?.id
            }
        }
        .onChange(of: countdownStore.timers) { _, _ in
            // Refresh selection if current timer was deleted
            if let selectedID = selectedTimerID,
               !countdownStore.timers.contains(where: { $0.id == selectedID }) {
                selectedTimerID = countdownStore.timers.first?.id
            }
        }
    }

    private func createNewTimer() {
                                let newTimer = CountdownTimer(
                            label: "New Timer",
                            targetDate: Date().addingTimeInterval(3600), // 1 hour from now
                            position: CGPoint(x: 0, y: 0),
                            priority: 1,
                            fontSize: 24,
                            template: .anticipation,
                            isCountUp: false
                        )
        countdownStore.addTimer(newTimer)
        selectedTimerID = newTimer.id
    }

        private func deleteSelectedTimers() {
        for timerID in selectedTimersForDeletion {
            if let timer = countdownStore.timers.first(where: { $0.id == timerID }) {
                countdownStore.removeTimer(timer)
            }
        }

        // Clear selection and exit delete mode
        selectedTimersForDeletion.removeAll()
        isDeleteMode = false

        // Update selected timer if it was deleted
        if let selectedID = selectedTimerID,
           !countdownStore.timers.contains(where: { $0.id == selectedID }) {
            selectedTimerID = countdownStore.timers.first?.id
        }
    }

        private func moveTimers(from source: IndexSet, to destination: Int) {
        countdownStore.moveTimer(from: source, to: destination)

        // Update selection to moved item if it was selected
        if let selectedID = selectedTimerID,
           let sourceIndex = source.first,
           countdownStore.timers.indices.contains(sourceIndex),
           countdownStore.timers[sourceIndex].id == selectedID {
            let newIndex = destination > sourceIndex ? destination - 1 : destination
            if countdownStore.timers.indices.contains(newIndex) {
                selectedTimerID = countdownStore.timers[newIndex].id
            }
        }
    }

    private func moveTimerUp(timer: CountdownTimer) {
        countdownStore.moveTimerUp(timer: timer)
    }

    private func moveTimerDown(timer: CountdownTimer) {
        countdownStore.moveTimerDown(timer: timer)
    }

    private func canMoveTimerUp(timer: CountdownTimer) -> Bool {
        guard let index = countdownStore.timers.firstIndex(where: { $0.id == timer.id }) else {
            return false
        }
        return index > 0
    }

    private func canMoveTimerDown(timer: CountdownTimer) -> Bool {
        guard let index = countdownStore.timers.firstIndex(where: { $0.id == timer.id }) else {
            return false
        }
        return index < countdownStore.timers.count - 1
    }

    // MARK: - Screensaver Functions

    private func openScreensaverPreferences() {
        // Open System Preferences to the Screen Saver pane
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.desktopscreeneffect") {
            NSWorkspace.shared.open(url)
        }
    }

    private func isScreensaverInstalled() -> Bool {
        let userPath = NSString("~/Library/Screen Savers/CountdownScreensaver.saver").expandingTildeInPath
        let systemPath = "/Library/Screen Savers/CountdownScreensaver.saver"

        return FileManager.default.fileExists(atPath: userPath) ||
               FileManager.default.fileExists(atPath: systemPath)
    }
}

struct TimerRowView: View {
    let timer: CountdownTimer
    let isSelected: Bool
    let isDeleteMode: Bool
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    let canMoveUp: Bool
    let canMoveDown: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Drag handle (only show when not in delete mode and not selected)
                if !isDeleteMode && !isSelected {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }

                Text(timer.label)
                    .font(.headline)
                Spacer()

                                // Up/Down buttons (only show when selected and not in delete mode)
                if isSelected && !isDeleteMode {
                    HStack(spacing: 6) {
                        Button(action: {
                            onMoveUp?()
                        }) {
                            Image(systemName: "chevron.up")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(canMoveUp ? .blue : .gray)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canMoveUp)
                        .help("Move up in priority")

                        Button(action: {
                            onMoveDown?()
                        }) {
                            Image(systemName: "chevron.down")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(canMoveDown ? .blue : .gray)
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canMoveDown)
                        .help("Move down in priority")
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.controlBackgroundColor))
                            .strokeBorder(Color(.separatorColor), lineWidth: 0.5)
                    )
                }
            }

            Text(timer.isCountUp ? "Count Up" : "Countdown")
                .font(.caption)
                .foregroundColor(timer.isCountUp ? .green : .blue)

            Text("Target: \(timer.targetDate, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
    }
}

struct TimerEditView: View {
    @EnvironmentObject var countdownStore: CountdownStore
    @State private var editedTimer: CountdownTimer
    @Binding var selectedTimerID: UUID?

    init(timer: CountdownTimer, selectedTimerID: Binding<UUID?>) {
        _editedTimer = State(initialValue: timer)
        _selectedTimerID = selectedTimerID
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Information Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Information")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Timer Name")
                                .font(.headline)
                            TextField("Enter timer name", text: $editedTimer.label)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: editedTimer.label) { _, _ in
                                    saveChanges()
                                }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Target Date")
                                .font(.headline)
                            DatePicker("", selection: $editedTimer.targetDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .onChange(of: editedTimer.targetDate) { _, _ in
                                    saveChanges()
                                }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Timer Type")
                                .font(.headline)

                            Picker("Timer Type", selection: $editedTimer.isCountUp) {
                                Text("Countdown").tag(false)
                                Text("Count Up").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: editedTimer.isCountUp) { _, _ in
                                saveChanges()
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                }

                                // Template Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Style Template")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack(spacing: 12) {
                        ForEach(TimerTemplate.allCases, id: \.self) { template in
                            Button(action: {
                                editedTimer.template = template
                                saveChanges()
                            }) {
                                HStack(spacing: 12) {
                                    // Template preview
                                    VStack(spacing: 4) {
                                        Text("Aa")
                                            .font(.custom(template.fontName, size: 18).weight(template.fontWeight))
                                            .foregroundColor(template.color)

                                        Circle()
                                            .fill(template.color)
                                            .frame(width: 8, height: 8)
                                    }
                                    .frame(width: 40)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.rawValue)
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        Text(template.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()

                                    if editedTimer.template == template {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(editedTimer.template == template ? Color.blue.opacity(0.1) : Color(.controlBackgroundColor))
                                        .strokeBorder(editedTimer.template == template ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Font Size & Position")
                                .font(.headline)

                            HStack {
                                Text("Automatic")
                                    .foregroundColor(.secondary)

                                Spacer()

                                if let layout = countdownStore.timerLayouts.first(where: { $0.timer.id == editedTimer.id }) {
                                    Text("\(Int(layout.fontSize))pt")
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Based on position")
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text("Font size (10-100pt) and position are automatically calculated based on the timer's order in the list. Drag timers in the sidebar to reposition them.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(12)
                }

                // Preview Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preview")
                        .font(.title2)
                        .fontWeight(.semibold)

                    VStack {
                        if let layout = countdownStore.timerLayouts.first(where: { $0.timer.id == editedTimer.id }) {
                            TimerDisplayView(
                                timer: layout.timer,
                                fontSize: layout.fontSize,
                                lastUpdate: Date()
                            )
                            .scaleEffect(0.8) // Scale down for preview
                        } else {
                            TimerDisplayView(timer: editedTimer, lastUpdate: Date())
                                .scaleEffect(0.8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(12)
                }

                // Delete Button
                Button(action: {
                    countdownStore.removeTimer(editedTimer)
                    selectedTimerID = countdownStore.timers.first?.id
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Timer")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .navigationTitle("Edit Timer")
    }

        private func saveChanges() {
        countdownStore.updateTimer(editedTimer)
    }
}



#Preview {
    SettingsView()
        .environmentObject(CountdownStore())
}
