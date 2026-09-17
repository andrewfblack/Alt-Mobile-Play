import SwiftUI

@main
struct AltPlayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var router = AppRouter()
    @State private var settings = AppSettings.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(settings)
                .onAppear { settings.apply() }
                .onOpenURL { _ in router.navigate(to: .home) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                ReturnActivityManager.shared.start()
            }
        }
    }
}
