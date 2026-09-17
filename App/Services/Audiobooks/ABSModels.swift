import Foundation

struct ABSCredentials: Encodable {
    let username: String
    let password: String
}

struct ABSLoginResponse: Decodable {
    let user: ABSLoginUser
    let serverSettings: ABSServerSettings?
}

struct ABSLoginUser: Decodable {
    let token: String
    let username: String?
}

struct ABSServerSettings: Decodable {
    let version: String?
}

struct ABSLibrariesResponse: Decodable {
    let libraries: [ABSLibrary]
}

struct ABSLibrary: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let mediaType: String?
    let icon: String?
    let displayOrder: Int?
}

struct ABSLibraryItemsResponse: Decodable {
    let results: [ABSLibraryItem]
    let total: Int?
}

struct ABSItemsInProgressResponse: Decodable {
    let libraryItems: [ABSLibraryItem]
}

struct ABSLibraryItem: Decodable, Identifiable, Hashable {
    let id: String
    let libraryId: String?
    let mediaType: String?
    let media: ABSBook?
}

struct ABSBook: Decodable, Hashable {
    let metadata: ABSBookMetadata?
    let mediaProgress: ABSMediaProgress?
    let chapters: [ABSChapter]?
    let duration: Double?
    let numTracks: Int?

    var title: String { metadata?.title ?? "Untitled" }
    var authorName: String { metadata?.authorName ?? "" }
}

struct ABSBookMetadata: Decodable, Hashable {
    let title: String?
    let authorName: String?
    let narratorName: String?
    let seriesName: String?
    let publishedYear: String?
}

struct ABSChapter: Decodable, Hashable {
    let start: Double?
    let end: Double?
    let title: String?
    let index: Int?
}

struct ABSMediaProgress: Decodable, Hashable {
    let currentTime: Double?
    let duration: Double?
    let progress: Double?
    let isFinished: Bool?
    let lastUpdate: Double?

    var fraction: Double {
        guard let progress else {
            guard let currentTime, let duration, duration > 0 else { return 0 }
            return max(0, min(1, currentTime / duration))
        }
        return progress
    }
}

struct ABSPlayRequest: Encodable {
    let deviceInfo: ABSPlayDeviceInfo
    let supportedMimeTypes: [String]
}

struct ABSPlayDeviceInfo: Encodable {
    let clientVersion: String
    let mediaPlayer: String

    init(clientVersion: String = "0.2.0", mediaPlayer: String = "AVPlayer") {
        self.clientVersion = clientVersion
        self.mediaPlayer = mediaPlayer
    }
}

struct ABSPlaybackSession: Decodable {
    let id: String
    let libraryItemId: String?
    let episodeId: String?
    let mediaType: String?
    let displayTitle: String?
    let displayAuthor: String?
    let duration: Double?
    let chapters: [ABSChapter]?
    let audioTracks: [ABSAudioTrack]?
    let currentTime: Double?
    let startTime: Double?
    let mediaMetadata: ABSPlaybackMetadata?
}

struct ABSPlaybackMetadata: Decodable {
    let title: String?
    let author: String?
    let narratorName: String?
    let seriesName: String?
}

struct ABSAudioTrack: Decodable, Hashable {
    let index: Int?
    let startOffset: Double?
    let duration: Double?
    let title: String?
    let contentUrl: String?
    let mimeType: String?
}