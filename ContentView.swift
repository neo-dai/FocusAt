import SwiftUI

struct ContentView: View {
    @State private var viewModel = PomodoroViewModel()
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var showHistory = false

    var body: some View {
        let isFocusTitleMissing = viewModel.mode == .focus
            && viewModel.state == .idle
            && viewModel.focusTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        VStack(spacing: 12) {
            if showHistory {
                historyView
            } else {
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

                HStack(spacing: 8) {
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

            Button(showHistory ? "返回计时器" : "查看历史") {
                showHistory.toggle()
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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

    private var historyView: some View {
        VStack(spacing: 6) {
            Text("历史记录")
                .font(.system(size: 14, weight: .semibold))

            if viewModel.sessions.isEmpty {
                Text("暂无记录")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.sessions) { session in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sessionTitle(session))
                                    .font(.system(size: 13, weight: .medium))
                                Text(sessionSubtitle(session))
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                }
                .frame(height: 140)
            }
        }
    }

    private func sessionTitle(_ session: PomodoroViewModel.Session) -> String {
        if session.mode == .focus {
            return session.title.isEmpty ? "未命名专注" : session.title
        }
        if session.mode == .longBreak {
            return "长休息"
        }
        return "短休息"
    }

    private func sessionSubtitle(_ session: PomodoroViewModel.Session) -> String {
        let minutes = Int(session.durationSeconds.rounded(.down)) / 60
        let status = session.status == .completed ? "完成" : "中断"
        return "\(session.mode.rawValue) · \(status) · \(minutes) 分钟 · \(Self.dateFormatter.string(from: session.startAt))"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter
    }()
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
