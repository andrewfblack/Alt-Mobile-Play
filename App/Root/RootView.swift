import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @State private var showVolume = false

    var body: some View {
        GeometryReader { geo in
            let barWidth = max(80, geo.size.width * 0.10)
            ZStack(alignment: .leading) {
                CarTheme.background
                    .ignoresSafeArea()

                Group {
                    switch router.current {
                    case .home:        HomeScreenView()
                    case .apps:        AppDrawerView()
                    case .navigation:  NavigationView(barWidth: barWidth)
                    case .music:       MusicView()
                    case .phone:       ContactsView()
                    case .messages:    QuickMessagesView()
                    case .podcasts:    PodcastsView()
                    case .settings:    SettingsView()
                    }
                }
                .id(router.current)
                .transition(.opacity)
                .padding(.leading, router.current == .navigation ? 0 : barWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                LeftControlBar(
                    width: barWidth,
                    onHome: {
                        if router.current == .home {
                            router.navigate(to: .apps)
                        } else {
                            router.navigate(to: .home)
                        }
                    },
                    onVolume: { showVolume = true }
                )
                .ignoresSafeArea()

                if showVolume {
                    VolumePopup(isPresented: $showVolume, barWidth: barWidth)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: router.current)
            .preferredColorScheme(ThemeManager.shared.scheme)
            .statusBarHidden(true)
            .persistentSystemOverlays(.hidden)
        }
    }
}