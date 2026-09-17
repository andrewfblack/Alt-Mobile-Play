import SwiftUI
import Observation

enum AppScreen: String, Hashable {
    case home
    case apps
    case navigation
    case music
    case phone
    case messages
    case podcasts
    case audiobooks
    case settings
}

@Observable
final class AppRouter {
    private(set) var stack: [AppScreen] = [.home]

    var current: AppScreen { stack.last ?? .home }

    func navigate(to screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.22)) {
            if screen == .home {
                stack = [.home]
            } else if stack.last != screen {
                if stack.count > 1 { stack.removeLast() }
                stack.append(screen)
            }
        }
    }
}
