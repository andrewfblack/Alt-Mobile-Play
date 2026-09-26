import AVFoundation
import Observation
import UIKit

enum LocalAudiobookError: LocalizedError {
    case catalogUnreadable
    case importInProgress

    var errorDescription: String? {
        switch self {
        case .catalogUnreadable:
            "The local audiobook catalog could not be read. Its files were left unchanged."
        case .importInProgress:
            "Wait for the current audiobook import to finish."
        }
    }
}

private actor LocalAudiobookImportGate {
    private var active = false

    func begin() -> Bool {
        guard !active else { return false }
        active = true
        return true
    }

    func end() {
        active = false
    }
}

struct LocalAudiobook: Codable, Identifiable, Equatable {
    let id: UUID
    let fileName: String
    var title: String
    var author: String
    var duration: Double
    var progress: Double
    var artworkFileName: String?
    let addedAt: Date
}

@Observable
final class LocalAudiobookLibrary {
    static let shared = LocalAudiobookLibrary()

    private(set) var books: [LocalAudiobook] = []
    private(set) var isImporting = false
    private(set) var catalogError: String?

    @ObservationIgnored private let fileManager = FileManager.default
    @ObservationIgnored private let importGate = LocalAudiobookImportGate()

    private init() {
        try? fileManager.createDirectory(at: libraryDirectory, withIntermediateDirectories: true)
        guard fileManager.fileExists(atPath: indexURL.path) else { return }
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([LocalAudiobook].self, from: data) else {
            catalogError = LocalAudiobookError.catalogUnreadable.localizedDescription
            return
        }
        books = decoded.filter { fileManager.fileExists(atPath: fileURL(for: $0).path) }
    }

    func importFiles(_ urls: [URL]) async throws {
        guard catalogError == nil else { throw LocalAudiobookError.catalogUnreadable }
        guard await importGate.begin() else { throw LocalAudiobookError.importInProgress }
        await MainActor.run { isImporting = true }
        do {
            for sourceURL in urls {
                let hasAccess = sourceURL.startAccessingSecurityScopedResource()
                defer {
                    if hasAccess { sourceURL.stopAccessingSecurityScopedResource() }
                }

                let id = UUID()
                let ext = sourceURL.pathExtension.isEmpty ? "m4b" : sourceURL.pathExtension
                let fileName = "\(id.uuidString).\(ext)"
                let destination = libraryDirectory.appendingPathComponent(fileName)
                try fileManager.copyItem(at: sourceURL, to: destination)

                let asset = AVURLAsset(url: destination)
                let cmDuration = try? await asset.load(.duration)
                let seconds = cmDuration?.seconds ?? 0
                let metadata = (try? await asset.load(.commonMetadata)) ?? []
                let metadataTitle = await metadataString(.commonIdentifierTitle, in: metadata)
                let metadataAuthor = await metadataString(.commonIdentifierArtist, in: metadata)
                let artworkFileName = await saveArtwork(from: metadata, id: id)

                let importedBook = LocalAudiobook(
                    id: id,
                    fileName: fileName,
                    title: nonempty(metadataTitle) ?? sourceURL.deletingPathExtension().lastPathComponent,
                    author: nonempty(metadataAuthor) ?? "",
                    duration: seconds.isFinite ? seconds : 0,
                    progress: 0,
                    artworkFileName: artworkFileName,
                    addedAt: Date()
                )
                do {
                    try await MainActor.run {
                        books.append(importedBook)
                        books.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
                        try save()
                    }
                } catch {
                    await MainActor.run { books.removeAll { $0.id == id } }
                    try? fileManager.removeItem(at: destination)
                    if let artworkFileName {
                        try? fileManager.removeItem(at: libraryDirectory.appendingPathComponent(artworkFileName))
                    }
                    throw error
                }
            }
            await MainActor.run { isImporting = false }
            await importGate.end()
        } catch {
            await MainActor.run { isImporting = false }
            await importGate.end()
            throw error
        }
    }

    @MainActor
    func remove(_ book: LocalAudiobook) throws {
        let originalBooks = books
        books.removeAll { $0.id == book.id }
        do {
            try save()
            try fileManager.removeItem(at: fileURL(for: book))
        } catch {
            books = originalBooks
            try? save()
            throw error
        }
        if let artworkFileName = book.artworkFileName {
            try? fileManager.removeItem(at: libraryDirectory.appendingPathComponent(artworkFileName))
        }
    }

    @MainActor
    func updateProgress(for id: UUID, time: Double, duration: Double) {
        guard let index = books.firstIndex(where: { $0.id == id }) else { return }
        if duration.isFinite, duration > 0 {
            books[index].duration = duration
        }
        books[index].progress = max(0, min(time, books[index].duration))
        do {
            try save()
        } catch {
            catalogError = "Local audiobook progress could not be saved: \(error.localizedDescription)"
        }
    }

    func fileURL(for book: LocalAudiobook) -> URL {
        libraryDirectory.appendingPathComponent(book.fileName)
    }

    func artwork(for book: LocalAudiobook) -> UIImage? {
        guard let artworkFileName = book.artworkFileName else { return nil }
        return UIImage(contentsOfFile: libraryDirectory.appendingPathComponent(artworkFileName).path)
    }

    private var libraryDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("Local Audiobooks", isDirectory: true)
    }

    private var indexURL: URL {
        libraryDirectory.appendingPathComponent("library.json")
    }

    @MainActor
    private func save() throws {
        let data = try JSONEncoder().encode(books)
        try data.write(to: indexURL, options: .atomic)
    }

    private func metadataString(
        _ identifier: AVMetadataIdentifier,
        in metadata: [AVMetadataItem]
    ) async -> String? {
        guard let item = AVMetadataItem.metadataItems(
            from: metadata,
            filteredByIdentifier: identifier
        ).first else { return nil }
        return try? await item.load(.stringValue)
    }

    private func saveArtwork(from metadata: [AVMetadataItem], id: UUID) async -> String? {
        guard let item = AVMetadataItem.metadataItems(
            from: metadata,
            filteredByIdentifier: .commonIdentifierArtwork
        ).first,
        let data = try? await item.load(.dataValue),
        let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.88)
        else { return nil }

        let fileName = "\(id.uuidString)-cover.jpg"
        do {
            try jpeg.write(to: libraryDirectory.appendingPathComponent(fileName), options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    private func nonempty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }
        return value
    }
}
