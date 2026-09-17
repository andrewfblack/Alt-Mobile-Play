import SwiftUI
import UIKit

struct HomeApp: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let icon: String
    let colorIndex: Int
    let screen: String?
    let scheme: String?

    var isBuiltIn: Bool { screen != nil }
    var color: Color { CarTheme.palette[abs(colorIndex) % CarTheme.palette.count] }

    init(builtIn screen: AppScreen, title: String, icon: String, colorIndex: Int) {
        self.id = screen.rawValue
        self.screen = screen.rawValue
        self.scheme = nil
        self.title = title
        self.icon = icon
        self.colorIndex = colorIndex
    }

    init(id: String, title: String, icon: String, colorIndex: Int, scheme: String) {
        self.id = id
        self.screen = nil
        self.scheme = scheme
        self.title = title
        self.icon = icon
        self.colorIndex = colorIndex
    }

    var url: URL? { scheme.map { URL(string: $0 + "://") } ?? nil }

    func open() {
        guard !isBuiltIn, let url else { return }
        UIApplication.shared.open(url)
    }
}

enum HomeAppCatalog {
    static let builtins: [HomeApp] = [
        HomeApp(builtIn: .navigation, title: "Navigation", icon: "map.fill", colorIndex: 0),
        HomeApp(builtIn: .music, title: "Music", icon: "music.note", colorIndex: 1),
        HomeApp(builtIn: .phone, title: "Phone", icon: "phone.fill", colorIndex: 2),
        HomeApp(builtIn: .messages, title: "Messages", icon: "message.fill", colorIndex: 2),
        HomeApp(builtIn: .podcasts, title: "Podcasts", icon: "mic.fill", colorIndex: 3),
        HomeApp(builtIn: .audiobooks, title: "Audiobooks", icon: "book.fill", colorIndex: 4),
        HomeApp(builtIn: .settings, title: "Settings", icon: "gearshape.fill", colorIndex: 5),
    ]

    static let externalSuggestions: [HomeApp] = [
        HomeApp(id: "audible", title: "Audible", icon: "headphones", colorIndex: 4, scheme: "audible"),
        HomeApp(id: "spotify", title: "Spotify", icon: "music.note", colorIndex: 2, scheme: "spotify"),
        HomeApp(id: "applemusic", title: "Apple Music", icon: "music.note.list", colorIndex: 1, scheme: "musics"),
        HomeApp(id: "applepodcasts", title: "Podcasts", icon: "mic.fill", colorIndex: 3, scheme: "podcasts"),
        HomeApp(id: "youtubemusic", title: "YouTube Music", icon: "play.square.stack", colorIndex: 1, scheme: "youtubemusic"),
        HomeApp(id: "overcast", title: "Overcast", icon: "waveform", colorIndex: 4, scheme: "overcast"),
        HomeApp(id: "waze", title: "Waze", icon: "car.fill", colorIndex: 0, scheme: "waze"),
        HomeApp(id: "googlemaps", title: "Google Maps", icon: "map", colorIndex: 2, scheme: "comgooglemaps"),
        HomeApp(id: "whatsapp", title: "WhatsApp", icon: "message.fill", colorIndex: 2, scheme: "whatsapp"),
    ]

    static var installedSuggestions: [HomeApp] {
        externalSuggestions.filter { app in
            guard let url = app.url else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }

    static let customIcons: [String] = [
        "app.badge.fill", "car.fill", "house.fill", "video.fill",
        "envelope.fill", "map.fill", "music.note", "headphones",
    ]
}