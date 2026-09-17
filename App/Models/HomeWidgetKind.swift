import SwiftUI

enum HomeWidgetKind: String, CaseIterable, Identifiable, Codable {
    case nowPlaying
    case navigation
    case quickMessages

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nowPlaying: "Now Playing"
        case .navigation: "Navigation"
        case .quickMessages: "Messages"
        }
    }

    var icon: String {
        switch self {
        case .nowPlaying: "music.note"
        case .navigation: "car.fill"
        case .quickMessages: "message.fill"
        }
    }
}