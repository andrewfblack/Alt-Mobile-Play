import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        applySettings()
        return true
    }

    func applySettings() {
        let keepAwake = UserDefaults.standard.object(forKey: "keepAwake") as? Bool ?? true
        UIApplication.shared.isIdleTimerDisabled = keepAwake
    }
}
