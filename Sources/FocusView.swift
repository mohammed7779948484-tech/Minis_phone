import SwiftUI

struct FocusView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            header

            Spacer(minLength: 8)

            ring

            Spacer(minLength: 8)

            controls

            Spacer(minLength: 16)

            statsRow

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Focus")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.text)
            Text(store.phase.label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(2.2)
                .foregroundStyle(store.phase.color)
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Theme.cardAlt, lineWidth: 16)

            Circle()
                .trim(from: 0, to: max(0.001, store.progress))
                .stroke(
                    AngularGradient(
                        colors: [store.phase.color.opacity(0.55), store.phase.color],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: store.progress)

            VStack(spacing: 6) {
                Text(store.timeString)
                    .font(.system(size: 62, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.text)
                    .contentTransition(.numericText())

                Text(store.isRunning ? "Running" : "Paused")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textDim)
            }
        }
        .frame(width: 268, height: 268)
        .padding(.vertical, 8)
    }

    private var controls: some View {
        HStack(spacing: 14) {
            circleButton("arrow.counterclockwise", Theme.cardAlt, Theme.textDim) {
                store.reset()
            }

            Button {
                Haptics.tap()
                store.isRunning ? store.pause() : store.start()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: store.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 17, weight: .bold))
                    Text(store.isRunning ? "Pause" : "Start")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(Theme.bg)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(store.phase.color, in: Capsule())
            }
            .buttonStyle(.plain)

            circleButton("forward.end.fill", Theme.cardAlt, Theme.textDim) {
                store.skip()
            }
        }
    }

    private func circleButton(_ icon: String, _ bg: Color, _ fg: Color, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(fg)
                .frame(width: 58, height: 58)
                .background(bg, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statBox("Sessions", "\(store.completedSessions)", "checkmark.seal")
            statBox("Focus", "\(store.focusMinutes)m", "brain.head.profile")
            statBox("Break", "\(store.breakMinutes)m", "cup.and.saucer")
        }
    }

    private func statBox(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.text)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
