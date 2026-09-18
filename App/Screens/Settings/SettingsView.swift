import SwiftUI
import UIKit

struct SettingsView: View {
    @Bindable private var settings = AppSettings.shared
    @State private var page: SettingsPage = .main
    @State private var showAppManager = false
    @State private var themeManager = ThemeManager.shared
    @State private var showThemeEditor = false
    @State private var editingTheme: Theme?
    @State private var absPassword = ""
    @State private var absConnecting = false
    @State private var absError: String?
    @State private var absService = AudiobookshelfService.shared

    var body: some View {
        VStack(spacing: 0) {
            header

            Group {
                switch page {
                case .main:
                    mainSettings
                case .appearance:
                    appearanceSettings
                case .audiobookshelf:
                    audiobookshelfSettings
                }
            }
            .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.18), value: page)
        .onAppear {
            settings.voiceGuidance = NavigationState.shared.voiceEnabled
        }
        .sheet(isPresented: $showAppManager) {
            HomeAppsManagerView()
        }
        .sheet(isPresented: $showThemeEditor) {
            ThemeEditorView(
                initial: editingTheme,
                onSave: { themeManager.upsert($0) },
                onDelete: editingTheme.map { theme in { themeManager.delete(theme) } }
            )
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            if page != .main {
                Button { page = .main } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(CarTheme.primaryText)
                        .frame(width: 40, height: 40)
                        .background(CarTheme.field)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to Settings")
            }

            Text(page.title)
                .font(CarTheme.rounded(30, .bold))
                .foregroundStyle(CarTheme.primaryText)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    private var mainSettings: some View {
        settingsScroll {
            section("Home Screen") {
                navigationRow(
                    icon: "square.grid.2x2.fill",
                    title: "Home Apps",
                    subtitle: "Choose and arrange apps on the home screen"
                ) {
                    showAppManager = true
                }
            }

            section("Personalization") {
                navigationRow(
                    icon: "paintpalette.fill",
                    title: "Appearance",
                    subtitle: "Theme: \(themeManager.current.name)"
                ) {
                    page = .appearance
                }
            }

            section("Driving") {
                SettingToggle(
                    icon: "sun.max.fill",
                    title: "Keep Screen Awake",
                    subtitle: "Prevent the screen from locking while driving",
                    isOn: $settings.keepAwake
                )
                settingDivider
                SettingToggle(
                    icon: "speaker.wave.3.fill",
                    title: "Voice Guidance",
                    subtitle: "Speak turn-by-turn directions aloud",
                    isOn: Binding(
                        get: { settings.voiceGuidance },
                        set: { enabled in
                            settings.voiceGuidance = enabled
                            NavigationState.shared.setVoice(enabled)
                        }
                    )
                )
            }

            section("Services") {
                navigationRow(
                    icon: "books.vertical.fill",
                    title: "Audiobookshelf",
                    subtitle: audiobookshelfSummary
                ) {
                    page = .audiobookshelf
                }
            }

            section("About") {
                SettingRow(
                    icon: "info.circle",
                    title: "AltPlay",
                    subtitle: "CarPlay for your iPhone"
                )
                settingDivider
                SettingRow(
                    icon: "chevron.left.forwardslash.chevron.right",
                    title: "Version",
                    subtitle: versionText
                )
                settingDivider
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    rowLabel(
                        icon: "gearshape.fill",
                        title: "Open System Settings",
                        subtitle: "Manage permissions and notifications",
                        trailingIcon: "arrow.up.right"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var appearanceSettings: some View {
        settingsScroll {
            section("Themes") {
                ForEach(themeManager.allThemes) { theme in
                    themeRow(theme)
                    settingDivider
                }

                Button {
                    editingTheme = nil
                    showThemeEditor = true
                } label: {
                    rowLabel(
                        icon: "plus.circle.fill",
                        iconColor: CarTheme.green,
                        title: "Create Custom Theme"
                    )
                }
                .buttonStyle(.plain)
            }

            section("Custom Theme File") {
                SettingRow(
                    icon: "doc.text.fill",
                    title: "customThemes.json",
                    subtitle: "Files > On My iPhone > AltPlay"
                )
                settingDivider
                Button {
                    themeManager.reloadFromFile()
                } label: {
                    rowLabel(icon: "arrow.clockwise", title: "Reload from Files")
                }
                .buttonStyle(.plain)
            }

            section("File Format") {
                Text(sampleJSON)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(CarTheme.secondaryText)
                    .lineLimit(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
        }
    }

    private var audiobookshelfSettings: some View {
        settingsScroll {
            section("Server") {
                settingTextField(
                    icon: "server.rack",
                    title: "Server URL",
                    placeholder: "http://192.168.1.100:3333",
                    text: $settings.absServerURL,
                    keyboard: .URL
                )
                settingDivider
                settingTextField(
                    icon: "person.fill",
                    title: "Username",
                    placeholder: "username",
                    text: $settings.absUsername,
                    keyboard: .default
                )
                settingDivider
                settingSecureField(icon: "lock.fill", title: "Password")
            }

            section("Connection") {
                if absService.isConnected {
                    SettingRow(
                        icon: "checkmark.circle.fill",
                        iconColor: CarTheme.green,
                        title: "Connected",
                        subtitle: absServerVersionText
                    )
                    settingDivider
                    Button {
                        absService.clear()
                        absPassword = ""
                        absError = nil
                    } label: {
                        rowLabel(
                            icon: "xmark.circle.fill",
                            iconColor: CarTheme.orange,
                            title: "Disconnect"
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    if let absError {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(CarTheme.orange)
                                .frame(width: 40, height: 40)
                            Text(absError)
                                .font(CarTheme.rounded(14, .medium))
                                .foregroundStyle(CarTheme.orange)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(14)
                        settingDivider
                    }

                    Button { connectToABS() } label: {
                        HStack(spacing: 10) {
                            if absConnecting {
                                ProgressView().tint(.white)
                            }
                            Text(absConnecting ? "Connecting..." : "Connect")
                                .font(CarTheme.rounded(18, .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(CarTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(absConnecting)
                    .opacity(absConnecting ? 0.7 : 1)
                }
            }
        }
    }

    private func settingsScroll<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                content()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(CarTheme.rounded(12, .semibold))
                .foregroundStyle(CarTheme.secondaryText)
                .tracking(0.8)
                .padding(.horizontal, 14)

            VStack(spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CarTheme.field)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func navigationRow(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            rowLabel(
                icon: icon,
                title: title,
                subtitle: subtitle,
                trailingIcon: "chevron.right"
            )
        }
        .buttonStyle(.plain)
    }

    private func rowLabel(
        icon: String,
        iconColor: Color = CarTheme.accent,
        title: String,
        subtitle: String? = nil,
        trailingIcon: String? = nil
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(CarTheme.rounded(18, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
                if let subtitle {
                    Text(subtitle)
                        .font(CarTheme.rounded(14))
                        .foregroundStyle(CarTheme.secondaryText)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 12)

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CarTheme.tertiaryText)
            }
        }
        .padding(14)
        .contentShape(Rectangle())
    }

    private var settingDivider: some View {
        Divider()
            .overlay(CarTheme.tertiaryText.opacity(0.25))
            .padding(.leading, 68)
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
                    HStack(spacing: 5) {
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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isCustom {
                Button {
                    editingTheme = theme
                    showThemeEditor = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(CarTheme.secondaryText)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(theme.name)")
            }
        }
        .frame(minHeight: 68)
    }

    private func swatch(_ color: RGBColor) -> some View {
        Circle()
            .fill(color.color)
            .frame(width: 14, height: 14)
            .overlay(Circle().strokeBorder(CarTheme.primaryText.opacity(0.3), lineWidth: 1))
    }

    private func settingTextField(
        icon: String,
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(CarTheme.accent)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(CarTheme.rounded(14, .medium))
                    .foregroundStyle(CarTheme.secondaryText)
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(keyboard)
                    .font(CarTheme.rounded(18, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
            }
        }
        .padding(14)
    }

    private func settingSecureField(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(CarTheme.accent)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(CarTheme.rounded(14, .medium))
                    .foregroundStyle(CarTheme.secondaryText)
                SecureField("password", text: $absPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(CarTheme.rounded(18, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
            }
        }
        .padding(14)
    }

    private var audiobookshelfSummary: String {
        absService.isConnected ? "Connected as \(settings.absUsername)" : "Configure server and sign in"
    }

    private var absServerVersionText: String {
        let version = settings.absServerVersion
        return version.isEmpty
            ? "Signed in as \(settings.absUsername)"
            : "Server v\(version) - \(settings.absUsername)"
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.2.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func connectToABS() {
        let url = settings.absServerURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else {
            absError = "Enter your server URL first."
            return
        }
        guard !absPassword.isEmpty else {
            absError = "Enter your password."
            return
        }
        absError = nil
        absConnecting = true
        Task {
            defer { absConnecting = false }
            do {
                try await absService.login(username: settings.absUsername, password: absPassword)
                absPassword = ""
            } catch {
                absError = (error as? ABSError)?.errorDescription ?? error.localizedDescription
            }
        }
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
}

private enum SettingsPage: Equatable {
    case main
    case appearance
    case audiobookshelf

    var title: String {
        switch self {
        case .main: "Settings"
        case .appearance: "Appearance"
        case .audiobookshelf: "Audiobookshelf"
        }
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
                        .lineLimit(2)
                }
                Spacer(minLength: 12)
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule()
                        .fill(isOn ? CarTheme.accent : CarTheme.tertiaryText)
                        .frame(width: 48, height: 28)
                    Circle()
                        .fill(.white)
                        .frame(width: 22, height: 22)
                        .padding(3)
                }
                .animation(.spring(duration: 0.2), value: isOn)
            }
            .padding(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

private struct SettingRow: View {
    let icon: String
    var iconColor: Color = CarTheme.accent
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(CarTheme.rounded(18, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
                Text(subtitle)
                    .font(CarTheme.rounded(14))
                    .foregroundStyle(CarTheme.secondaryText)
                    .lineLimit(2)
            }
            Spacer(minLength: 12)
        }
        .padding(14)
    }
}
