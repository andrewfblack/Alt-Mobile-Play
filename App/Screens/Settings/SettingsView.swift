import SwiftUI

struct SettingsView: View {
    @Environment(AppRouter.self) private var router
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            topTitle("Settings")
                .padding(.horizontal, 24)
                .padding(.top, 16)

            ScrollView {
                VStack(spacing: 12) {
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
    }

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
