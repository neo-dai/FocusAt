import Foundation
import UserNotifications
import Observation

@Observable
final class PomodoroViewModel {
    enum Mode: String, Codable {
        case focus = "Focus"
        case `break` = "Break"
    }

    enum State: String {
        case idle = "Idle"
        case running = "Running"
        case paused = "Paused"
    }

    enum SessionStatus: String, Codable {
        case completed
        case abandoned
    }

    struct Session: Identifiable, Codable {
        let id: UUID
        let title: String
        let mode: Mode
        let startAt: Date
        let endAt: Date
        let durationSeconds: TimeInterval
        let status: SessionStatus
    }

    private let focusDuration: TimeInterval = 25 * 60
    private let breakDuration: TimeInterval = 5 * 60
    private let notificationIdentifier = "pomodoro.timer.complete"

    var mode: Mode = .focus
    var state: State = .idle
    var displayRemaining: TimeInterval = 25 * 60
    var focusTitle: String = ""
    var sessions: [Session] = []

    private var endAt: Date?
    private var remainingWhenPaused: TimeInterval?
    private var currentSessionStartAt: Date?

    // 版本计划:
    // [V0] MVP: Focus 25/Break 5, EndAt 逻辑, 本地通知, 仅窗口模式.

    init() {
        loadSessions()
    }

    func requestNotificationAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            // Silence errors; app remains usable without notifications.
        }
    }

    func start() {
        guard state == .idle else { return }
        if mode == .focus, focusTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }
        let duration = initialDuration(for: mode)
        if currentSessionStartAt == nil {
            currentSessionStartAt = Date()
        }
        endAt = Date().addingTimeInterval(duration)
        state = .running
        updateDisplay()
        scheduleNotification(at: endAt)
    }

    func pause() {
        guard state == .running else { return }
        remainingWhenPaused = remainingTime()
        endAt = nil
        state = .paused
        updateDisplay()
        cancelNotifications()
    }

    func resume() {
        guard state == .paused else { return }
        let remaining = remainingWhenPaused ?? initialDuration(for: mode)
        endAt = Date().addingTimeInterval(remaining)
        remainingWhenPaused = nil
        state = .running
        updateDisplay()
        scheduleNotification(at: endAt)
    }

    func reset() {
        if state == .running || state == .paused {
            recordAbandonedSession()
        }
        endAt = nil
        remainingWhenPaused = nil
        state = .idle
        displayRemaining = initialDuration(for: mode)
        cancelNotifications()
    }

    func switchMode() {
        mode = (mode == .focus) ? .break : .focus
        reset()
    }

    func tick() {
        updateDisplay()
        if state == .running, remainingTime() <= 0 {
            recordCompletedSession()
            endAt = nil
            remainingWhenPaused = nil
            state = .idle
            displayRemaining = 0
            cancelNotifications()
        }
    }

    func formattedTime() -> String {
        let totalSeconds = Int(displayRemaining.rounded(.down))
        let minutes = max(0, totalSeconds) / 60
        let seconds = max(0, totalSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func initialDuration(for mode: Mode) -> TimeInterval {
        switch mode {
        case .focus: return focusDuration
        case .break: return breakDuration
        }
    }

    private func remainingTime() -> TimeInterval {
        if state == .running, let endAt {
            return max(0, endAt.timeIntervalSinceNow)
        }
        if state == .paused, let remainingWhenPaused {
            return max(0, remainingWhenPaused)
        }
        return initialDuration(for: mode)
    }

    private func updateDisplay() {
        displayRemaining = remainingTime()
    }

    private func recordCompletedSession() {
        guard let actualEndAt = endAt else { return }
        let startAt = currentSessionStartAt ?? actualEndAt.addingTimeInterval(-initialDuration(for: mode))
        let duration = max(0, actualEndAt.timeIntervalSince(startAt))
        addSession(
            title: mode == .focus ? focusTitle.trimmingCharacters(in: .whitespacesAndNewlines) : "",
            mode: mode,
            startAt: startAt,
            endAt: actualEndAt,
            durationSeconds: duration,
            status: .completed
        )
        currentSessionStartAt = nil
    }

    private func recordAbandonedSession() {
        let now = Date()
        let total = initialDuration(for: mode)
        let remaining = remainingTime()
        let elapsed = max(0, total - remaining)
        guard elapsed > 1 else { return }
        let startAt = now.addingTimeInterval(-elapsed)
        addSession(
            title: mode == .focus ? focusTitle.trimmingCharacters(in: .whitespacesAndNewlines) : "",
            mode: mode,
            startAt: currentSessionStartAt ?? startAt,
            endAt: now,
            durationSeconds: elapsed,
            status: .abandoned
        )
        currentSessionStartAt = nil
    }

    private func sessionsFileURL() -> URL? {
        let fileManager = FileManager.default
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = base.appendingPathComponent("FocusAt", isDirectory: true)
        return folder.appendingPathComponent("sessions.json")
    }

    private func loadSessions() {
        guard let fileURL = sessionsFileURL() else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            sessions = try decoder.decode([Session].self, from: data)
        } catch {
            sessions = []
        }
    }

    private func saveSessions() {
        guard let fileURL = sessionsFileURL() else { return }
        do {
            let folder = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(sessions)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Ignore persistence errors for V1.
        }
    }

    private func addSession(
        title: String,
        mode: Mode,
        startAt: Date,
        endAt: Date,
        durationSeconds: TimeInterval,
        status: SessionStatus
    ) {
        let session = Session(
            id: UUID(),
            title: title,
            mode: mode,
            startAt: startAt,
            endAt: endAt,
            durationSeconds: durationSeconds,
            status: status
        )
        sessions.insert(session, at: 0)
        saveSessions()
    }

    private func scheduleNotification(at date: Date?) {
        guard let date, date.timeIntervalSinceNow > 0 else { return }
        cancelNotifications()

        let content = UNMutableNotificationContent()
        content.title = "Pomodoro"
        content.body = mode == .focus ? "Focus session complete." : "Break time is over."
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
