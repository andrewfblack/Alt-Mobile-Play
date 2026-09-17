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

        HomeApp(id: "applemaps", title: "Apple Maps", icon: "map.fill", colorIndex: 0, scheme: "maps"),
        HomeApp(id: "facetime", title: "FaceTime", icon: "video.fill", colorIndex: 2, scheme: "facetime"),
        HomeApp(id: "applebooks", title: "Apple Books", icon: "book.fill", colorIndex: 5, scheme: "com.apple.iBooks"),
        HomeApp(id: "telegram", title: "Telegram", icon: "paperplane.fill", colorIndex: 1, scheme: "tg"),
        HomeApp(id: "signal", title: "Signal", icon: "lock.fill", colorIndex: 1, scheme: "sgnl"),
        HomeApp(id: "slack", title: "Slack", icon: "number", colorIndex: 4, scheme: "slack"),
        HomeApp(id: "teams", title: "Teams", icon: "person.3.fill", colorIndex: 2, scheme: "msteams"),
        HomeApp(id: "zoom", title: "Zoom", icon: "video.badge.plus", colorIndex: 1, scheme: "zoommtg"),
        HomeApp(id: "discord", title: "Discord", icon: "gamecontroller.fill", colorIndex: 5, scheme: "discord"),
        HomeApp(id: "reddit", title: "Reddit", icon: "bubble.left.and.bubble.right.fill", colorIndex: 3, scheme: "reddit"),
        HomeApp(id: "linkedin", title: "LinkedIn", icon: "briefcase.fill", colorIndex: 1, scheme: "linkedin"),
        HomeApp(id: "pinterest", title: "Pinterest", icon: "pin.fill", colorIndex: 5, scheme: "pinterest"),
        HomeApp(id: "snapchat", title: "Snapchat", icon: "camera.aperture", colorIndex: 4, scheme: "snapchat"),
        HomeApp(id: "instagram", title: "Instagram", icon: "camera.fill", colorIndex: 4, scheme: "instagram"),
        HomeApp(id: "facebook", title: "Facebook", icon: "f.cursive.circle", colorIndex: 2, scheme: "fb"),
        HomeApp(id: "messenger", title: "Messenger", icon: "message.circle.fill", colorIndex: 1, scheme: "fb-messenger"),
        HomeApp(id: "x", title: "X", icon: "xmark", colorIndex: 2, scheme: "twitter"),
        HomeApp(id: "youtube", title: "YouTube", icon: "play.rectangle.fill", colorIndex: 5, scheme: "youtube"),
        HomeApp(id: "netflix", title: "Netflix", icon: "play.tv.fill", colorIndex: 5, scheme: "nflx"),
        HomeApp(id: "hbo", title: "HBO Max", icon: "tv.fill", colorIndex: 5, scheme: "hbomax"),
        HomeApp(id: "disneyplus", title: "Disney+", icon: "sparkles", colorIndex: 4, scheme: "disneyplus"),
        HomeApp(id: "paramount", title: "Paramount+", icon: "star.fill", colorIndex: 5, scheme: "paramount"),
        HomeApp(id: "hulu", title: "Hulu", icon: "tv.circle.fill", colorIndex: 3, scheme: "hulu"),
        HomeApp(id: "tubi", title: "Tubi", icon: "film.fill", colorIndex: 5, scheme: "tubi"),
        HomeApp(id: "peacock", title: "Peacock", icon: "feather", colorIndex: 1, scheme: "peacock"),
        HomeApp(id: "primevideo", title: "Prime Video", icon: "shippingbox.fill", colorIndex: 4, scheme: "amzn"),
        HomeApp(id: "pandora", title: "Pandora", icon: "radio.fill", colorIndex: 3, scheme: "pandora"),
        HomeApp(id: "tidal", title: "Tidal", icon: "drop.fill", colorIndex: 3, scheme: "tidal"),
        HomeApp(id: "deezer", title: "Deezer", icon: "waveform.path.ecg", colorIndex: 2, scheme: "deezer"),
        HomeApp(id: "soundcloud", title: "SoundCloud", icon: "cloud.fill", colorIndex: 1, scheme: "soundcloud"),
        HomeApp(id: "pocketcasts", title: "Pocket Casts", icon: "mic.circle.fill", colorIndex: 4, scheme: "pktc"),
        HomeApp(id: "plex", title: "Plex", icon: "play.fill", colorIndex: 4, scheme: "plex"),
        HomeApp(id: "homeassistant", title: "Home Assistant", icon: "house.fill", colorIndex: 1, scheme: "homeassistant"),
        HomeApp(id: "jellyfin", title: "Jellyfin", icon: "square.stack.3d.up.fill", colorIndex: 4, scheme: "jellyfin"),
        HomeApp(id: "vlc", title: "VLC", icon: "play.circle.fill", colorIndex: 5, scheme: "vlc"),
        HomeApp(id: "uber", title: "Uber", icon: "car.side.fill", colorIndex: 2, scheme: "uber"),
        HomeApp(id: "ubereats", title: "Uber Eats", icon: "takeoutbag.and.cup.and.straw.fill", colorIndex: 3, scheme: "ubereats"),
        HomeApp(id: "lyft", title: "Lyft", icon: "car.side", colorIndex: 3, scheme: "lyft"),
        HomeApp(id: "doordash", title: "DoorDash", icon: "fork.knife", colorIndex: 5, scheme: "doordash"),
        HomeApp(id: "grubhub", title: "Grubhub", icon: "cart.fill", colorIndex: 3, scheme: "grubhub"),
        HomeApp(id: "github", title: "GitHub", icon: "chevron.left.forwardslash.chevron.right", colorIndex: 2, scheme: "github"),
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
        "book.fill", "mic.fill", "phone.fill", "message.fill",
        "calendar", "camera.fill", "photo.fill", "tv.fill",
        "gamecontroller.fill", "fork.knife", "cart.fill", "creditcard.fill",
        "bed.double.fill", "pawprint.fill", "leaf.fill", "dumbbell.fill",
        "figure.run", "airplane", "tram.fill", "bolt.car.fill",
        "flame.fill", "drop.fill", "moon.fill", "sun.max.fill",
        "cloud.fill", "gift.fill", "graduationcap.fill", "briefcase.fill",
        "building.2.fill", "shield.fill", "heart.fill", "star.fill",
        "paintpalette.fill", "wrench.and.screwdriver.fill", "battery.100.fill", "wallet.pass.fill",
        "newspaper.fill", "books.vertical.fill", "radio.fill", "crown.fill",
    ]
}