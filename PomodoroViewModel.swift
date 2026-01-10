import Foundation
import UserNotifications
import Observation

@Observable
final class PomodoroViewModel {
    enum Mode: String {
        case focus = "Focus"
        case `break` = "Break"
    }

    enum State: String {
        case idle = "Idle"
        case running = "Running"
        case paused = "Paused"
    }

    private let focusDuration: TimeInterval = 25 * 60
    private let breakDuration: TimeInterval = 5 * 60
    private let notificationIdentifier = "pomodoro.timer.complete"

    var mode: Mode = .focus
    var state: State = .idle
    var displayRemaining: TimeInterval = 25 * 60

    private var endAt: Date?
    private var remainingWhenPaused: TimeInterval?

    // 版本计划:
    // [V0] MVP: Focus 25/Break 5, EndAt 逻辑, 本地通知, 仅窗口模式.

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
        let duration = initialDuration(for: mode)
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
