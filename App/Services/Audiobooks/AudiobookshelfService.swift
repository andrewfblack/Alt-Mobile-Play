import Foundation
import Observation
import UIKit

enum ABSError: LocalizedError {
    case notConfigured
    case badStatus(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured: "No Audiobookshelf server configured"
        case .badStatus(let code): "Server returned status \(code)"
        case .invalidResponse: "Unexpected server response"
        }
    }
}

@Observable
final class AudiobookshelfService {
    static let shared = AudiobookshelfService()

    private let settings = AppSettings.shared
    private let session: URLSession
    private let coverCache = NSCache<NSString, UIImage>()

    private(set) var libraries: [ABSLibrary] = []
    private(set) var itemsByLibrary: [String: [ABSLibraryItem]] = [:]
    private(set) var inProgress: [ABSLibraryItem] = []

    var lastError: String?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.waitsForConnectivity = false
        session = URLSession(configuration: config)
    }

    var serverURL: String? { settings.absServerURL }
    var username: String? { settings.absUsername }
    var isConfigured: Bool {
        guard let serverURL else { return false }
        return !serverURL.isEmpty
    }
    var isConnected: Bool { isConfigured && !settings.absToken.isEmpty }

    var baseURL: URL? {
        guard let raw = serverURL, !raw.isEmpty else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.hasSuffix("/") ? String(trimmed.dropLast()) : trimmed
        return URL(string: normalized)
    }

    var token: String? { settings.absToken }

    func clear() {
        settings.absServerURL = ""
        settings.absUsername = ""
        settings.absToken = ""
        settings.absServerVersion = ""
        libraries = []
        itemsByLibrary = [:]
        inProgress = []
        lastError = nil
    }

    // MARK: - Auth

    func login(username: String, password: String) async throws {
        guard var base = baseURL else {
            throw ABSError.notConfigured
        }
        base.append(path: "login")

        var request = URLRequest(url: base)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ABSCredentials(username: username, password: password))

        let (data, _) = try await perform(request)
        let login = try JSONDecoder().decode(ABSLoginResponse.self, from: data)

        settings.absUsername = username
        settings.absToken = login.user.token
        settings.absServerVersion = login.serverSettings?.version ?? ""
        lastError = nil

        libraries = []
        itemsByLibrary = [:]
        inProgress = []
    }

    // MARK: - Data

    func loadLibraries() async {
        guard let data = try? await get("/api/libraries") else { return }
        let response = try? JSONDecoder().decode(ABSLibrariesResponse.self, from: data)
        libraries = response?.libraries ?? []
    }

    func loadItems(for libraryID: String) async {
        guard libraries.contains(where: { $0.id == libraryID }) else { return }
        guard itemsByLibrary[libraryID] == nil else { return }
        guard let data = try? await get("/api/libraries/\(libraryID)/items?sort=media.metadata.title") else { return }
        let response = try? JSONDecoder().decode(ABSLibraryItemsResponse.self, from: data)
        itemsByLibrary[libraryID] = response?.results ?? []
    }

    func loadInProgress() async {
        guard let data = try? await get("/api/me/items-in-progress") else { return }
        let response = try? JSONDecoder().decode(ABSItemsInProgressResponse.self, from: data)
        inProgress = response?.libraryItems ?? []
    }

    func item(id: String) async throws -> ABSLibraryItem {
        let data = try await get("/api/items/\(id)")
        return try JSONDecoder().decode(ABSLibraryItem.self, from: data)
    }

    // MARK: - Playback

    @discardableResult
    func startPlaybackSession(itemID: String) async throws -> ABSPlaybackSession {
        var request = URLRequest(url: try url(path: "/api/items/\(itemID)/play"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            ABSPlayRequest(
                deviceInfo: ABSPlayDeviceInfo(),
                supportedMimeTypes: ["audio/mpeg", "audio/mp4", "audio/x-m4a", "audio/flac", "audio/ogg", "audio/aac"]
            )
        )
        let (data, _) = try await perform(request)
        return try JSONDecoder().decode(ABSPlaybackSession.self, from: data)
    }

    func saveProgress(itemID: String, currentTime: Double, duration: Double) async {
        guard isConnected, duration > 0 else { return }
        do {
            let progress = max(0, min(1, currentTime / duration))
            let body = try JSONEncoder().encode(
                ProgressPayload(currentTime: currentTime, duration: duration, progress: progress)
            )
            var request = URLRequest(url: try url(path: "/api/me/progress/\(itemID)"))
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
            _ = try await perform(request)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private struct ProgressPayload: Encodable {
        let currentTime: Double
        let duration: Double
        let progress: Double
    }

    // MARK: - Covers

    func coverImage(for itemID: String, width: Int = 300) async -> UIImage? {
        let key = "\(width)-\(itemID)" as NSString
        if let cached = coverCache.object(forKey: key) { return cached }
        guard let data = try? await getData(path: "/api/items/\(itemID)/cover?width=\(width)"),
              let image = UIImage(data: data)
        else { return nil }
        coverCache.setObject(image, forKey: key)
        return image
    }

    // MARK: - Networking

    private func url(path: String) throws -> URL {
        guard let base = baseURL else { throw ABSError.notConfigured }
        guard let url = URL(string: path, relativeTo: base) else { throw ABSError.invalidResponse }
        return url
    }

    private func get(_ path: String) async throws -> Data {
        let (data, _) = try await perform(URLRequest(url: try url(path: path)))
        return data
    }

    private func getData(path: String) async throws -> Data {
        let (data, _) = try await perform(URLRequest(url: try url(path: path)))
        return data
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var request = request
        if isConnected {
            request.setValue("Bearer \(settings.absToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ABSError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            lastError = "Server returned \(http.statusCode)"
            throw ABSError.badStatus(http.statusCode)
        }
        return (data, http)
    }
}