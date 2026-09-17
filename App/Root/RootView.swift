import SwiftUI

struct RootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
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

            if router.current != .home {
                HomeButton()
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: router.current)
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}

private struct HomeButton: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        Button { router.navigate(to: .home) } label: {
            Image(systemName: "house.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(CarTheme.primaryText)
                .frame(width: 56, height: 56)
                .background(Circle().fill(CarTheme.tile))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Home")
    }
}
