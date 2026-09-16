import SwiftUI
import Observation

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var keepAwake: Bool {
        didSet { UserDefaults.standard.set(keepAwake, forKey: "keepAwake"); apply() }
    }
    var voiceGuidance: Bool {
        didSet { UserDefaults.standard.set(voiceGuidance, forKey: "voiceGuidance") }
    }

    var homeApps: [HomeApp] {
        didSet { saveHomeApps() }
    }

    private static let homeAppsKey = "homeApps"

    private init() {
        keepAwake = UserDefaults.standard.object(forKey: "keepAwake") as? Bool ?? true
        voiceGuidance = UserDefaults.standard.object(forKey: "voiceGuidance") as? Bool ?? true
        if let data = UserDefaults.standard.data(forKey: Self.homeAppsKey),
           let decoded = try? JSONDecoder().decode([HomeApp].self, from: data) {
            homeApps = decoded
        } else {
            homeApps = HomeAppCatalog.builtins
        }
    }

    private func saveHomeApps() {
        if let data = try? JSONEncoder().encode(homeApps) {
            UserDefaults.standard.set(data, forKey: Self.homeAppsKey)
        }
    }

    func isOnHome(_ app: HomeApp) -> Bool { homeApps.contains { $0.id == app.id } }

    func addToHome(_ app: HomeApp) {
        guard !isOnHome(app) else { return }
        homeApps.append(app)
    }

    func removeFromHome(_ app: HomeApp) {
        homeApps.removeAll { $0.id == app.id }
    }

    func toggleHome(_ app: HomeApp) {
        if isOnHome(app) {
            removeFromHome(app)
        } else {
            addToHome(app)
        }
    }

    func apply() {
        UIApplication.shared.isIdleTimerDisabled = keepAwake
    }
}
