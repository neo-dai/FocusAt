import SwiftUI

struct ContentView: View {
    @State private var viewModel = PomodoroViewModel()
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        let isFocusTitleMissing = viewModel.mode == .focus
            && viewModel.state == .idle
            && viewModel.focusTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text(viewModel.formattedTime())
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("\(viewModel.mode.rawValue) · \(viewModel.state.rawValue)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                if viewModel.mode == .focus, !viewModel.focusTitle.isEmpty {
                    Text(viewModel.focusTitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if viewModel.mode == .focus {
                TextField("输入当前专注内容", text: $viewModel.focusTitle)
                    .textFieldStyle(.roundedBorder)
                    .disabled(viewModel.state == .running)
                    .frame(maxWidth: 240)
            }

            HStack(spacing: 10) {
                if viewModel.state == .idle {
                    Button("Start") {
                        viewModel.start()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isFocusTitleMissing)
                }

                if viewModel.state == .running {
                    Button("Pause") {
                        viewModel.pause()
                    }
                    .buttonStyle(.bordered)
                }

                if viewModel.state == .paused {
                    Button("Resume") {
                        viewModel.resume()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("Reset") {
                    viewModel.reset()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.state == .idle)
            }

            Button("Switch Mode") {
                viewModel.switchMode()
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .onReceive(timer) { _ in
            viewModel.tick()
        }
        .task {
            await viewModel.requestNotificationAuthorization()
        }
        .background(WindowAccessor { window in
            window.standardWindowButton(.zoomButton)?.isEnabled = false
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.collectionBehavior.remove(.fullScreenPrimary)
            window.collectionBehavior.remove(.fullScreenAuxiliary)
        })
    }
}

private struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                callback(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            callback(window)
        }
    }
}
