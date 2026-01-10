import SwiftUI

@main
struct PomodoroApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 300, height: 220)
        }
        .windowResizability(.contentSize)
    }
}
