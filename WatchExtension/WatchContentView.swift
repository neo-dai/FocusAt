import SwiftUI

struct WatchContentView: View {
    @State private var viewModel = PomodoroViewModel()
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        let isFocusTitleMissing = viewModel.mode == .focus
            && viewModel.state == .idle
            && viewModel.focusTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        VStack(spacing: 8) {
            Text(viewModel.formattedTime())
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text("\(viewModel.mode.rawValue) · \(viewModel.state.rawValue)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            if viewModel.mode == .focus {
                TextField("专注内容", text: $viewModel.focusTitle)
                    .disabled(viewModel.state == .running)
            }

            if viewModel.state == .idle {
                Button("开始") {
                    viewModel.start()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isFocusTitleMissing)
            }

            if viewModel.state == .running {
                Button("暂停") {
                    viewModel.pause()
                }
                .buttonStyle(.bordered)
            }

            if viewModel.state == .paused {
                Button("继续") {
                    viewModel.resume()
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 8) {
                Button("重置") {
                    viewModel.reset()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.state == .idle)

                Button("模式") {
                    viewModel.switchMode()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 6)
        .onReceive(timer) { _ in
            viewModel.tick()
        }
        .task {
            await viewModel.requestNotificationAuthorization()
        }
    }
}
