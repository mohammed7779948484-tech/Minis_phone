import SwiftUI

struct NotesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showEditor = false
    @State private var editing: Note?

    var body: some View {
        VStack(spacing: 0) {
            header

            searchBar

            if store.filteredNotes.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .padding(.top, 20)
        .sheet(isPresented: $showEditor) {
            NoteEditor(note: nil) { title, body in
                store.addNote(title: title, body: body)
            }
        }
        .sheet(item: $editing) { note in
            NoteEditor(note: note) { title, body in
                var n = note
                n.title = title
                n.body = body
                store.updateNote(n)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Notes")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)
                Text("\(store.notes.count) saved")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textDim)
            }
            Spacer()
            Button {
                Haptics.tap()
                showEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.bg)
                    .frame(width: 42, height: 42)
                    .background(Theme.accent, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var searchBar: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textDim)
            TextField("Search notes", text: $store.searchText)
                .font(.system(size: 14))
                .foregroundStyle(Theme.text)
                .autocorrectionDisabled()
            if !store.searchText.isEmpty {
                Button {
                    store.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textDim)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(store.filteredNotes) { note in
                    NoteRow(note: note)
                        .onTapGesture { editing = note }
                        .contextMenu {
                            Button {
                                store.togglePin(note)
                            } label: {
                                Label(note.pinned ? "Unpin" : "Pin", systemImage: note.pinned ? "pin.slash" : "pin")
                            }
                            Button(role: .destructive) {
                                store.deleteNote(note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: store.searchText.isEmpty ? "note.text" : "magnifyingglass")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Theme.textDim.opacity(0.6))
            Text(store.searchText.isEmpty ? "No notes yet" : "No matches")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textDim)
            if store.searchText.isEmpty {
                Text("Tap + to write your first note")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textDim.opacity(0.7))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Row

struct NoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if note.pinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.warn)
                }
                Text(note.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Spacer()
            }

            if !note.body.isEmpty {
                Text(note.body)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textDim)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.textDim.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(note.pinned ? Theme.warn.opacity(0.35) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Editor

struct NoteEditor: View {
    let note: Note?
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var text: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                VStack(spacing: 14) {
                    TextField("Title", text: $title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.text)
                        .padding(14)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    TextEditor(text: $text)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.text)
                        .scrollContentBackground(.hidden)
                        .padding(10)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .frame(maxHeight: .infinity)

                    Spacer(minLength: 0)
                }
                .padding(20)
            }
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textDim)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, text)
                        Haptics.success()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.accent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty &&
                              text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            if let n = note {
                title = n.title
                text = n.body
            }
        }
    }
}
