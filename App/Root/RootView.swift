import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router
    @State private var showDrawer = false
    @State private var showVolume = false

    var body: some View {
        ZStack(alignment: .leading) {
            CarTheme.background
                .ignoresSafeArea()

            Group {
                switch router.current {
                case .home:      HomeScreenView()
                case .navigation: NavigationView()
                case .music:     MusicView()
                case .phone:     ContactsView()
                case .messages:  QuickMessagesView()
                case .podcasts:  PodcastsView()
                case .settings:  SettingsView()
                }
            }
            .id(router.current)
            .transition(.opacity)
            .padding(.leading, LeftControlBar.width)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            LeftControlBar(
                onHome: {
                    if router.current == .home {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { showDrawer = true }
                    } else {
                        router.navigate(to: .home)
                    }
                },
                onVolume: { showVolume = true }
            )
            .ignoresSafeArea()

            if showDrawer {
                AppDrawer(isPresented: $showDrawer)
                    .transition(.opacity)
            }

            if showVolume {
                VolumePopup(isPresented: $showVolume)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: router.current)
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}
