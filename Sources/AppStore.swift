import SwiftUI
import Combine

// MARK: - Theme

enum Theme {
    static let bg = Color(red: 0.05, green: 0.06, blue: 0.09)
    static let card = Color(red: 0.11, green: 0.12, blue: 0.16)
    static let cardAlt = Color(red: 0.15, green: 0.16, blue: 0.21)
    static let accent = Color(red: 0.42, green: 0.62, blue: 1.0)
    static let accent2 = Color(red: 0.55, green: 0.95, blue: 0.78)
    static let warn = Color(red: 1.0, green: 0.72, blue: 0.30)
    static let danger = Color(red: 1.0, green: 0.42, blue: 0.42)
    static let text = Color.white
    static let textDim = Color.white.opacity(0.55)
}

// MARK: - Models

struct Note: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var createdAt: Date = Date()
    var pinned: Bool = false
}

enum TimerPhase: String {
    case idle, focus, shortBreak, longBreak

    var label: String {
        switch self {
        case .idle: return "Ready"
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var color: Color {
        switch self {
        case .idle: return Theme.textDim
        case .focus: return Theme.accent
        case .shortBreak: return Theme.accent2
        case .longBreak: return Theme.warn
        }
    }
}

// MARK: - Store

final class AppStore: ObservableObject {

    // Notes
    @Published var notes: [Note] = []
    @Published var searchText: String = ""

    // Pomodoro
    @Published var phase: TimerPhase = .idle
    @Published var remaining: Int = 25 * 60
    @Published var isRunning: Bool = false
    @Published var completedSessions: Int = 0
    @Published var focusMinutes: Int = 25
    @Published var breakMinutes: Int = 5

    private var timer: Timer?
    private let notesKey = "minis.pulse.notes.v1"
    private let statsKey = "minis.pulse.stats.v1"

    init() {
        loadNotes()
        loadStats()
    }

    // MARK: Notes

    var filteredNotes: [Note] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = q.isEmpty ? notes : notes.filter {
            $0.title.localizedCaseInsensitiveContains(q) ||
            $0.body.localizedCaseInsensitiveContains(q)
        }
        return base.sorted {
            if $0.pinned != $1.pinned { return $0.pinned }
            return $0.createdAt > $1.createdAt
        }
    }

    func addNote(title: String, body: String) {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty || !b.isEmpty else { return }
        notes.insert(Note(title: t.isEmpty ? "Untitled" : t, body: b), at: 0)
        saveNotes()
    }

    func updateNote(_ note: Note) {
        guard let i = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[i] = note
        saveNotes()
    }

    func togglePin(_ note: Note) {
        guard let i = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[i].pinned.toggle()
        saveNotes()
    }

    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }

    func deleteNotes(at offsets: IndexSet, in list: [Note]) {
        let ids = offsets.map { list[$0].id }
        notes.removeAll { ids.contains($0.id) }
        saveNotes()
    }

    private func saveNotes() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: notesKey)
        }
    }

    private func loadNotes() {
        guard let data = UserDefaults.standard.data(forKey: notesKey),
              let decoded = try? JSONDecoder().decode([Note].self, from: data) else { return }
        notes = decoded
    }

    // MARK: Pomodoro

    var progress: Double {
        let total = Double(phase == .focus ? focusMinutes * 60 : breakMinutes * 60)
        guard total > 0 else { return 0 }
        return 1.0 - (Double(remaining) / total)
    }

    var timeString: String {
        String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }

    func start() {
        if phase == .idle {
            phase = .focus
            remaining = focusMinutes * 60
        }
        guard !isRunning else { return }
        isRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        phase = .idle
        remaining = focusMinutes * 60
    }

    func skip() {
        advancePhase()
    }

    private func tick() {
        guard isRunning else { return }
        if remaining > 0 {
            remaining -= 1
        } else {
            advancePhase()
        }
    }

    private func advancePhase() {
        pause()
        switch phase {
        case .idle, .focus:
            completedSessions += 1
            saveStats()
            let isLong = completedSessions % 4 == 0
            phase = isLong ? .longBreak : .shortBreak
            remaining = (isLong ? breakMinutes * 3 : breakMinutes) * 60
        case .shortBreak, .longBreak:
            phase = .focus
            remaining = focusMinutes * 60
        }
        Haptics.success()
    }

    private func saveStats() {
        UserDefaults.standard.set(completedSessions, forKey: statsKey)
    }

    private func loadStats() {
        completedSessions = UserDefaults.standard.integer(forKey: statsKey)
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
