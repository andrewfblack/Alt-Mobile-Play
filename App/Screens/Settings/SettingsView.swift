import SwiftUI

struct SettingsView: View {
    @Environment(AppRouter.self) private var router
    @Bindable private var settings = AppSettings.shared
    @State private var showAppManager = false
    @State private var themeManager = ThemeManager.shared
    @State private var showThemeEditor = false
    @State private var editingTheme: Theme?

    var body: some View {
        VStack(spacing: 0) {
            topTitle("Settings")
                .padding(.horizontal, 24)
                .padding(.top, 16)

            ScrollView {
                VStack(spacing: 12) {
                    section("Home Screen") {
                        Button {
                            showAppManager = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "square.grid.2x2.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(CarTheme.accent)
                                    .frame(width: 40, height: 40)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Home Apps")
                                        .font(CarTheme.rounded(18, .semibold))
                                        .foregroundStyle(CarTheme.primaryText)
                                    Text("Add, hide, or remove apps on the home screen")
                                        .font(CarTheme.rounded(14))
                                        .foregroundStyle(CarTheme.secondaryText)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(CarTheme.tertiaryText)
                            }
                            .padding(14)
                        }
                        .buttonStyle(.plain)
                    }

                    section("Appearance") {
                        ForEach(themeManager.allThemes) { theme in
                            themeRow(theme)
                        }
                        Button {
                            editingTheme = nil
                            showThemeEditor = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(CarTheme.green)
                                    .frame(width: 40, height: 40)
                                Text("Create Custom Theme")
                                    .font(CarTheme.rounded(18, .semibold))
                                    .foregroundStyle(CarTheme.primaryText)
                                Spacer()
                            }
                            .padding(14)
                        }
                        .buttonStyle(.plain)
                    }

                    section("Custom Theme File") {
                        SettingRow(
                            icon: "doc.text.fill",
                            title: "customThemes.json",
                            subtitle: "Files › On My iPhone › AltPlay"
                        )
                        Button {
                            themeManager.reloadFromFile()
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 20))
                                    .foregroundStyle(CarTheme.accent)
                                    .frame(width: 40, height: 40)
                                Text("Reload from Files")
                                    .font(CarTheme.rounded(18, .semibold))
                                    .foregroundStyle(CarTheme.primaryText)
                                Spacer()
                            }
                            .padding(14)
                        }
                        .buttonStyle(.plain)
                        Text(sampleJSON)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(CarTheme.tertiaryText)
                            .lineLimit(6)
                            .padding(14)
                    }

                    section("Display") {
                        SettingToggle(
                            icon: "sun.max.fill",
                            title: "Keep Screen Awake",
                            subtitle: "Prevent the screen from locking while driving",
                            isOn: Binding(
                                get: { settings.keepAwake },
                                set: { settings.keepAwake = $0 }
                            )
                        )
                    }

                    section("Navigation") {
                        SettingToggle(
                            icon: "speaker.wave.3.fill",
                            title: "Voice Guidance",
                            subtitle: "Speak turn-by-turn directions aloud",
                            isOn: Binding(
                                get: { settings.voiceGuidance },
                                set: { newValue in
                                    settings.voiceGuidance = newValue
                                    NavigationState.shared.setVoice(newValue)
                                }
                            )
                        )
                    }

                    section("About") {
                        SettingRow(
                            icon: "info.circle",
                            title: "AltPlay",
                            subtitle: "CarPlay for your iPhone"
                        )
                        SettingRow(
                            icon: "chevron.left.forwardslash.chevron.right",
                            title: "Version",
                            subtitle: "0.2.0 (1)"
                        )
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(CarTheme.accent)
                                    .frame(width: 40, height: 40)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Open System Settings")
                                        .font(CarTheme.rounded(18, .semibold))
                                        .foregroundStyle(CarTheme.primaryText)
                                    Text("Manage permissions and notifications")
                                        .font(CarTheme.rounded(14))
                                        .foregroundStyle(CarTheme.secondaryText)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(CarTheme.tertiaryText)
                            }
                            .padding(14)
                            .background(CarTheme.field)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .onAppear {
                settings.voiceGuidance = NavigationState.shared.voiceEnabled
            }
        }
        .sheet(isPresented: $showAppManager) {
            HomeAppsManagerView()
        }
        .sheet(isPresented: $showThemeEditor) {
            ThemeEditorView(
                initial: editingTheme,
                onSave: { themeManager.upsert($0) },
                onDelete: editingTheme.map { t in { themeManager.delete(t) } }
            )
        }
    }

    private func themeRow(_ theme: Theme) -> some View {
        let isCustom = themeManager.customThemes.contains { $0.id == theme.id }
        return HStack(spacing: 0) {
            Button {
                themeManager.current = theme
            } label: {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(theme.name)
                            .font(CarTheme.rounded(18, .semibold))
                            .foregroundStyle(CarTheme.primaryText)
                        if isCustom {
                            Text("Custom")
                                .font(CarTheme.rounded(13))
                                .foregroundStyle(CarTheme.secondaryText)
                        }
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        swatch(theme.background)
                        swatch(theme.accent)
                        swatch(theme.tile)
                        swatch(theme.primaryText)
                    }
                    if themeManager.current.id == theme.id {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(CarTheme.accent)
                    }
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isCustom {
                Button {
                    editingTheme = theme
                    showThemeEditor = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(CarTheme.secondaryText)
                        .padding(.horizontal, 14)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func swatch(_ c: RGBColor) -> some View {
        Circle()
            .fill(c.color)
            .frame(width: 14, height: 14)
            .overlay(Circle().strokeBorder(CarTheme.primaryText.opacity(0.3), lineWidth: 1))
    }

    private let sampleJSON = """
    [
      {"id": "sunrise", "name": "Sunrise",
       "background": [0.18, 0.12, 0.16],
       "tile": [0.25, 0.17, 0.22],
       "accent": "#FF8C40",
       "primaryText": [1, 0.96, 0.9]}
    ]
    """

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(CarTheme.rounded(12, .semibold))
                .foregroundStyle(CarTheme.secondaryText)
                .tracking(0.8)
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            content()
                .background(CarTheme.field)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.bottom, 12)
    }
}

private struct SettingToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(CarTheme.accent)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(CarTheme.rounded(18, .semibold))
                        .foregroundStyle(CarTheme.primaryText)
                    Text(subtitle)
                        .font(CarTheme.rounded(14))
                        .foregroundStyle(CarTheme.secondaryText)
                }
                Spacer()
                Circle()
                    .fill(isOn ? CarTheme.accent : CarTheme.tertiaryText)
                    .frame(width: 48, height: 28)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 22, height: 22)
                            .offset(x: isOn ? 11 : -11)
                            .animation(.spring(duration: 0.2), value: isOn)
                    )
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(CarTheme.accent)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(CarTheme.rounded(18, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
                Text(subtitle)
                    .font(CarTheme.rounded(14))
                    .foregroundStyle(CarTheme.secondaryText)
            }
            Spacer()
        }
        .padding(14)
    }
}
