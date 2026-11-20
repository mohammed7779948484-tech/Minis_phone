import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var tab: Tab = .device

    enum Tab: String, CaseIterable {
        case device = "Device"
        case focus = "Focus"
        case notes = "Notes"

        var icon: String {
            switch self {
            case .device: return "cpu"
            case .focus: return "timer"
            case .notes: return "note.text"
            }
        }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                tabBar
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .device: DeviceView()
        case .focus:  FocusView()
        case .notes:  NotesView()
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { t in
                Button {
                    Haptics.tap()
                    withAnimation(.easeInOut(duration: 0.18)) { tab = t }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: t.icon)
                            .font(.system(size: 19, weight: .semibold))
                        Text(t.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(tab == t ? Theme.accent : Theme.textDim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 4)
        .background(
            Theme.card
                .overlay(Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
