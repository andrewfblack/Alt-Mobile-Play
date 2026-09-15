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

    private init() {
        keepAwake = UserDefaults.standard.object(forKey: "keepAwake") as? Bool ?? true
        voiceGuidance = UserDefaults.standard.object(forKey: "voiceGuidance") as? Bool ?? true
    }

    func apply() {
        UIApplication.shared.isIdleTimerDisabled = keepAwake
    }
}
