import SwiftUI

private struct ThemeDraft {
    var name: String
    var background: Color
    var widget: Color
    var tile: Color
    var tilePressed: Color
    var field: Color
    var accent: Color
    var green: Color
    var orange: Color
    var red: Color
    var purple: Color
    var primaryText: Color
    var secondaryText: Color
    var tertiaryText: Color

    init(_ theme: Theme) {
        name = theme.name
        background = theme.background.color
        widget = theme.widget.color
        tile = theme.tile.color
        tilePressed = theme.tilePressed.color
        field = theme.field.color
        accent = theme.accent.color
        green = theme.green.color
        orange = theme.orange.color
        red = theme.red.color
        purple = theme.purple.color
        primaryText = theme.primaryText.color
        secondaryText = theme.secondaryText.color
        tertiaryText = theme.tertiaryText.color
    }

    func makeTheme(id: String, name: String) -> Theme {
        Theme(
            id: id,
            name: name,
            background: RGBColor(background),
            widget: RGBColor(widget),
            tile: RGBColor(tile),
            tilePressed: RGBColor(tilePressed),
            field: RGBColor(field),
            accent: RGBColor(accent),
            green: RGBColor(green),
            orange: RGBColor(orange),
            red: RGBColor(red),
            purple: RGBColor(purple),
            primaryText: RGBColor(primaryText),
            secondaryText: RGBColor(secondaryText),
            tertiaryText: RGBColor(tertiaryText)
        )
    }
}

struct ThemeEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let initial: Theme?
    var onSave: (Theme) -> Void = { _ in }
    var onDelete: (() -> Void)?

    @State private var draft: ThemeDraft
    @State private var name = ""

    init(initial: Theme?, onSave: @escaping (Theme) -> Void, onDelete: (() -> Void)? = nil) {
        self.initial = initial
        self.onSave = onSave
        self.onDelete = onDelete
        let base = initial ?? ThemeManager.shared.current
        _draft = State(initialValue: ThemeDraft(base))
        _name = State(initialValue: base.name)
    }

    private var isNew: Bool { initial == nil }
    private var themeID: String { initial?.id ?? "custom-\(UUID().uuidString)" }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 12) {
                    nameField
                    preview
                    colorSection
                    buttons
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Theme Editor")
                .font(CarTheme.rounded(24, .bold))
                .foregroundStyle(CarTheme.primaryText)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(CarTheme.primaryText)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(CarTheme.field))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var nameField: some View {
        HStack(spacing: 12) {
            Text("Name")
                .font(CarTheme.rounded(17, .medium))
                .foregroundStyle(CarTheme.primaryText)
            Spacer()
            TextField("Theme name", text: $name)
                .font(CarTheme.rounded(18, .medium))
                .foregroundStyle(CarTheme.primaryText)
                .multilineTextAlignment(.trailing)
                .autocorrectionDisabled()
        }
        .padding(14)
        .background(CarTheme.field)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name.isEmpty ? "My Theme" : name)
                .font(CarTheme.rounded(22, .semibold))
                .foregroundStyle(draft.primaryText)
            HStack(spacing: 8) {
                Circle()
                    .fill(draft.accent)
                    .frame(width: 12, height: 12)
                Text("Accent text")
                    .font(CarTheme.rounded(16, .medium))
                    .foregroundStyle(draft.primaryText)
                Spacer()
                Text("Secondary")
                    .font(CarTheme.rounded(15))
                    .foregroundStyle(draft.secondaryText)
            }
            HStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(draft.tile)
                    .frame(height: 56)
                    .overlay {
                        HStack(spacing: 10) {
                            Image(systemName: "music.note")
                                .foregroundStyle(draft.accent)
                            Text("Tile")
                                .font(CarTheme.rounded(17, .semibold))
                                .foregroundStyle(draft.primaryText)
                        }
                    }
                Circle()
                    .fill(draft.green)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(.white)
                    }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(draft.background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(draft.primaryText.opacity(0.15), lineWidth: 1)
        )
    }

    private var colorSection: some View {
        VStack(spacing: 0) {
            colorRow("Background", $draft.background)
            colorRow("Widget", $draft.widget)
            colorRow("Tile", $draft.tile)
            colorRow("Tile Pressed", $draft.tilePressed)
            colorRow("Field", $draft.field)
            colorRow("Accent", $draft.accent)
            colorRow("Green", $draft.green)
            colorRow("Orange", $draft.orange)
            colorRow("Red", $draft.red)
            colorRow("Purple", $draft.purple)
            colorRow("Primary Text", $draft.primaryText)
            colorRow("Secondary Text", $draft.secondaryText)
            colorRow("Tertiary Text", $draft.tertiaryText)
        }
        .background(CarTheme.field)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func colorRow(_ label: String, _ color: Binding<Color>) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(CarTheme.rounded(17, .medium))
                .foregroundStyle(CarTheme.primaryText)
            Spacer()
            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()
        }
        .padding(12)
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            Button {
                let trimmed = name.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                onSave(draft.makeTheme(id: themeID, name: trimmed))
                dismiss()
            } label: {
                Text(isNew ? "Create Theme" : "Save Changes")
                    .font(CarTheme.rounded(18, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? CarTheme.tertiaryText : CarTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

            if let onDelete {
                Button {
                    onDelete()
                    dismiss()
                } label: {
                    Text("Delete Theme")
                        .font(CarTheme.rounded(18, .semibold))
                        .foregroundStyle(CarTheme.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(CarTheme.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 6)
    }
}