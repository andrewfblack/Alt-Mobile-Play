import UIKit

struct ExternalAudioApp: Identifiable {
    let scheme: String
    let name: String
    let icon: String

    var id: String { scheme }
    var url: URL? { URL(string: scheme + "://") }
}

enum ExternalAudioApps {
    static let all: [ExternalAudioApp] = [
        ExternalAudioApp(scheme: "audible", name: "Audible", icon: "headphones"),
        ExternalAudioApp(scheme: "spotify", name: "Spotify", icon: "music.note"),
        ExternalAudioApp(scheme: "podcasts", name: "Apple Podcasts", icon: "mic.fill"),
        ExternalAudioApp(scheme: "musics", name: "Apple Music", icon: "music.note.list"),
        ExternalAudioApp(scheme: "youtubemusic", name: "YouTube Music", icon: "play.square.stack"),
        ExternalAudioApp(scheme: "overcast", name: "Overcast", icon: "waveform"),
    ]

    static var installed: [ExternalAudioApp] {
        all.filter { $0.url.map { UIApplication.shared.canOpenURL($0) } == true }
    }

    static func open(_ app: ExternalAudioApp) {
        if let url = app.url { UIApplication.shared.open(url) }
    }
}