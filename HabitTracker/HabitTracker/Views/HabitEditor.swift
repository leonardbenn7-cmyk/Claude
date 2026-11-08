import SwiftUI
import SwiftData

struct HabitEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var allHabits: [Habit]

    let habit: Habit?

    @State private var name = ""
    @State private var emoji = "✅"
    @State private var colorHex = Palette.colors[0]
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("z. B. 10 Minuten lesen", text: $name)
                }

                Section("Symbol") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                        ForEach(Palette.emojis, id: \.self) { item in
                            Text(item)
                                .font(.title2)
                                .frame(width: 38, height: 38)
                                .background(emoji == item ? Color(hex: colorHex).opacity(0.25) : .clear,
                                            in: RoundedRectangle(cornerRadius: 8))
                                .onTapGesture { emoji = item }
                        }
                    }
                    TextField("Eigenes Emoji", text: $emoji)
                        .onChange(of: emoji) { _, new in
                            if new.count > 1, let last = new.last { emoji = String(last) }
                        }
                }

                Section("Farbe") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(Palette.colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    if colorHex == hex {
                                        Image(systemName: "checkmark").font(.headline).foregroundStyle(.white)
                                    }
                                }
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                if habit != nil {
                    Section {
                        Button("Habit löschen", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(habit == nil ? "Neues Habit" : "Habit bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Habit wirklich löschen? Alle Häkchen gehen verloren.",
                                isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    if let habit { context.delete(habit) }
                    try? context.save()
                    dismiss()
                }
            }
            .onAppear {
                if let habit {
                    name = habit.name
                    emoji = habit.emoji
                    colorHex = habit.colorHex
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let symbol = emoji.isEmpty ? "✅" : emoji
        if let habit {
            habit.name = trimmed
            habit.emoji = symbol
            habit.colorHex = colorHex
        } else {
            let order = (allHabits.map(\.sortOrder).max() ?? -1) + 1
            context.insert(Habit(name: trimmed, emoji: symbol, colorHex: colorHex, sortOrder: order))
        }
        try? context.save()
        dismiss()
    }
}

struct HabitsListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Habit.sortOrder) private var habits: [Habit]
    @State private var editing: Habit?

    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
                    Button { editing = habit } label: {
                        HStack {
                            Circle().fill(Color(hex: habit.colorHex)).frame(width: 10, height: 10)
                            Text(habit.emoji)
                            Text(habit.name).foregroundStyle(.primary)
                        }
                    }
                }
                .onMove(perform: move)
                .onDelete(perform: delete)
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } }
            }
            .sheet(item: $editing) { habit in HabitEditor(habit: habit) }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ordered = habits
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, habit) in ordered.enumerated() { habit.sortOrder = index }
        try? context.save()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(habits[index]) }
        try? context.save()
    }
}
