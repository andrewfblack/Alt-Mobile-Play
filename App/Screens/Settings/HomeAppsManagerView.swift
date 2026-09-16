import SwiftUI

struct HomeAppsManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = AppSettings.shared
    @State private var customName = ""
    @State private var customScheme = ""
    @State private var customIcon = HomeAppCatalog.customIcons.first ?? "app.badge.fill"

    private var trimmedScheme: String {
        customScheme.trimmingCharacters(in: .whitespaces).lowercased()
            .replacingOccurrences(of: "://", with: "")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Home Apps")
                    .font(CarTheme.rounded(30, .bold))
                    .foregroundStyle(CarTheme.primaryText)
                Spacer()
                Button { dismiss() } label: {
                    Text("Done")
                        .font(CarTheme.rounded(18, .semibold))
                        .foregroundStyle(CarTheme.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 16) {
                    section("On Home Screen") {
                        if settings.homeApps.isEmpty {
                            emptyRow("No apps on the home screen")
                        } else {
                            rows(settings.homeApps) { app in
                                actionButton(icon: "minus.circle.fill", tint: CarTheme.red) {
                                    settings.removeFromHome(app)
                                }
                            }
                        }
                    }

                    section("Add Suggested Apps") {
                        let available = HomeAppCatalog.installedSuggestions.filter { !settings.isOnHome($0) }
                        if available.isEmpty {
                            emptyRow("No other installed apps detected")
                        } else {
                            rows(available) { app in
                                actionButton(icon: "plus.circle.fill", tint: CarTheme.green) {
                                    settings.addToHome(app)
                                }
                            }
                        }
                    }

                    section("Hidden Built-in Apps") {
                        let hidden = HomeAppCatalog.builtins.filter { !settings.isOnHome($0) }
                        if hidden.isEmpty {
                            emptyRow("All built-in apps are shown")
                        } else {
                            rows(hidden) { app in
                                actionButton(icon: "plus.circle.fill", tint: CarTheme.green) {
                                    settings.addToHome(app)
                                }
                            }
                        }
                    }

                    section("Add Custom App") {
                        customForm
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(CarTheme.background.ignoresSafeArea())
    }

    // MARK: - Pieces

    private func rows<Content: View>(_ apps: [HomeApp], @ViewBuilder trailing: @escaping (HomeApp) -> Content) -> some View {
        VStack(spacing: 0) {
            ForEach(apps) { app in
                HStack(spacing: 14) {
                    Image(systemName: app.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(app.color)
                        .frame(width: 40, height: 40)
                        .background(app.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Text(app.title)
                        .font(CarTheme.rounded(18, .semibold))
                        .foregroundStyle(CarTheme.primaryText)
                    Spacer()
                    trailing(app)
                }
                .padding(14)

                if app.id != apps.last?.id {
                    Divider().background(CarTheme.tertiaryText.opacity(0.3)).padding(.leading, 68)
                }
            }
        }
    }

    private func actionButton(icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(CarTheme.rounded(15))
            .foregroundStyle(CarTheme.tertiaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
    }

    private var customForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("App name", text: $customName)
                .font(CarTheme.rounded(17))
                .foregroundStyle(CarTheme.primaryText)
                .autocorrectionDisabled()

            TextField("URL scheme (e.g. myapp)", text: $customScheme)
                .font(CarTheme.rounded(17))
                .foregroundStyle(CarTheme.primaryText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            HStack(spacing: 10) {
                ForEach(HomeAppCatalog.customIcons, id: \.self) { icon in
                    Button { customIcon = icon } label: {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundStyle(customIcon == icon ? .white : CarTheme.secondaryText)
                            .frame(width: 40, height: 40)
                            .background(customIcon == icon ? CarTheme.accent : CarTheme.field)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                let app = HomeApp(
                    id: "custom-\(trimmedScheme)",
                    title: customName.trimmingCharacters(in: .whitespaces),
                    icon: customIcon,
                    colorIndex: HomeAppCatalog.customIcons.firstIndex(of: customIcon) ?? 0,
                    scheme: trimmedScheme
                )
                settings.addToHome(app)
                customName = ""
                customScheme = ""
            } label: {
                Text("Add to Home Screen")
                    .font(CarTheme.rounded(17, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(canAddCustom ? CarTheme.accent : CarTheme.field)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canAddCustom)
        }
        .padding(14)
    }

    private var canAddCustom: Bool {
        !customName.trimmingCharacters(in: .whitespaces).isEmpty && !trimmedScheme.isEmpty
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
    }
}