import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum AudiobooksSection: String, CaseIterable, Identifiable {
    case nowPlaying = "Now Playing"
    case library = "Library"
    var id: String { rawValue }
}

struct AudiobooksView: View {
    @Environment(AppRouter.self) private var router
    @State private var absService = AudiobookshelfService.shared
    @State private var localLibrary = LocalAudiobookLibrary.shared
    @State private var player = AudiobookPlayerService.shared
    @State private var source: AudiobookSource?
    @State private var section: AudiobooksSection = .nowPlaying
    @State private var selectedLibrary: String?
    @State private var libraryItems: [ABSLibraryItem] = []
    @State private var showFileImporter = false
    @State private var importError: String?

    var body: some View {
        VStack(spacing: 8) {
            header

            if source == .local || (source == .audiobookshelf && absService.isConnected) {
                Picker("", selection: $section) {
                    ForEach(AudiobooksSection.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                importError = nil
                Task {
                    do {
                        try await localLibrary.importFiles(urls)
                    } catch {
                        importError = error.localizedDescription
                    }
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .onChange(of: source) { _, newSource in
            section = newSource == .local && player.source != .local ? .library : .nowPlaying
            if newSource == .audiobookshelf { load() }
        }
        .onChange(of: absService.libraries) { _, libs in
            if selectedLibrary == nil, let first = libs.first {
                selectedLibrary = first.id
            }
            refreshLibraryItems()
        }
        .onChange(of: selectedLibrary) { _, _ in refreshLibraryItems() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            if source != nil {
                Button { source = nil } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(CarTheme.primaryText)
                        .frame(width: 40, height: 40)
                        .background(CarTheme.field)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Choose audiobook source")
            }
            Text(sourceTitle)
                .font(CarTheme.rounded(30, .bold))
                .foregroundStyle(CarTheme.primaryText)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var sourceTitle: String {
        switch source {
        case .audiobookshelf: "Audiobookshelf"
        case .local: "Local Audiobooks"
        case nil: "Audiobooks"
        }
    }

    private func load() {
        guard absService.isConnected else { return }
        Task {
            await absService.loadLibraries()
            await absService.loadInProgress()
        }
    }

    private func refreshLibraryItems() {
        guard let selectedLibrary else { return }
        if let cached = absService.itemsByLibrary[selectedLibrary] {
            libraryItems = cached
        }
        Task {
            await absService.loadItems(for: selectedLibrary)
            libraryItems = absService.itemsByLibrary[selectedLibrary] ?? []
        }
    }

    @ViewBuilder
    private var content: some View {
        switch source {
        case nil:
            sourceChooser
        case .audiobookshelf:
            audiobookshelfContent
        case .local:
            localContent
        }
    }

    @ViewBuilder
    private var audiobookshelfContent: some View {
        if !absService.isConnected {
            connectPrompt
        } else if absService.libraries.isEmpty {
            if !absService.isConfigured {
                connectPrompt
            } else {
                loadingView("Loading libraries…")
            }
        } else {
            switch section {
            case .nowPlaying: nowPlayingView
            case .library: libraryView
            }
        }
    }

    @ViewBuilder
    private var localContent: some View {
        switch section {
        case .nowPlaying: nowPlayingView
        case .library: localLibraryView
        }
    }

    private var sourceChooser: some View {
        GeometryReader { geo in
            let width = min(360, (geo.size.width - 72) / 2)
            HStack(spacing: 24) {
                sourceCard(
                    source: .audiobookshelf,
                    icon: "server.rack",
                    title: "Audiobookshelf",
                    subtitle: absService.isConnected
                        ? "Browse your connected server"
                        : "Connect to your self-hosted library"
                )
                .frame(width: width)

                sourceCard(
                    source: .local,
                    icon: "folder.fill",
                    title: "Local Audiobooks",
                    subtitle: localLibrary.books.isEmpty
                        ? "Import audio files from Files"
                        : "\(localLibrary.books.count) book\(localLibrary.books.count == 1 ? "" : "s") available"
                )
                .frame(width: width)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        }
    }

    private func sourceCard(
        source cardSource: AudiobookSource,
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        Button { source = cardSource } label: {
            VStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(CarTheme.accent)
                    .frame(height: 52)
                Text(title)
                    .font(CarTheme.rounded(22, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
                Text(subtitle)
                    .font(CarTheme.rounded(15))
                    .foregroundStyle(CarTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(CarTheme.accent)
            }
            .padding(22)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tileBackground()
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Now Playing

    private var nowPlayingView: some View {
        GeometryReader { geo in
            let artworkSize = max(0, min(280, geo.size.width * 0.34, geo.size.height - 24))
            HStack(spacing: 24) {
                artworkView
                    .frame(width: artworkSize, height: artworkSize)
                VStack(alignment: .leading, spacing: 8) {
                    if hasSelectedContent {
                        bookInfo
                    } else {
                        Text("No audiobook playing")
                            .font(CarTheme.rounded(24, .semibold))
                            .foregroundStyle(CarTheme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Pick a book from your library or continue listening.")
                            .font(CarTheme.rounded(15))
                            .foregroundStyle(CarTheme.secondaryText)
                        HStack(spacing: 12) {
                            Button("Open Library") { section = .library }
                                .buttonStyle(.bordered)
                                .tint(CarTheme.accent)
                            if source == .audiobookshelf && !absService.inProgress.isEmpty {
                                Button("Continue") { section = .library }
                                    .buttonStyle(.bordered)
                                    .tint(CarTheme.green)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    transportControls
                    speedControls
                    Group {
                        if hasSelectedContent {
                            progressBar
                        } else {
                            Color.clear
                        }
                    }
                    .frame(height: 62)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }

    private var bookInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(player.title)
                .font(CarTheme.rounded(26, .bold))
                .foregroundStyle(CarTheme.primaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if !player.author.isEmpty {
                Text(player.author)
                    .font(CarTheme.rounded(19))
                    .foregroundStyle(CarTheme.secondaryText)
                    .lineLimit(1)
            }
            if !player.series.isEmpty {
                Text(player.series)
                    .font(CarTheme.rounded(15))
                    .foregroundStyle(CarTheme.secondaryText)
                    .lineLimit(1)
            }
        }
    }

    private var artworkView: some View {
        Group {
            if hasSelectedContent, let img = player.artwork {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    CarTheme.tile
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(CarTheme.accent.opacity(0.4))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var transportControls: some View {
        HStack(spacing: 32) {
            Button { player.skipBack() } label: {
                Image(systemName: "gobackward.30")
                    .font(.system(size: 32))
                    .frame(width: 56, height: 52)
            }
            .accessibilityLabel("Back 30 seconds")
            Button { player.playPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 40))
                    .frame(width: 64, height: 52)
            }
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            Button { player.skipForward() } label: {
                Image(systemName: "goforward.30")
                    .font(.system(size: 32))
                    .frame(width: 56, height: 52)
            }
            .accessibilityLabel("Forward 30 seconds")
        }
        .buttonStyle(.plain)
        .foregroundStyle(CarTheme.primaryText)
        .disabled(!hasSelectedContent)
        .opacity(hasSelectedContent ? 1 : 0.35)
    }

    private var speedControls: some View {
        HStack(spacing: 10) {
            ForEach(player.supportedSpeeds, id: \.self) { rate in
                Button { player.setSpeed(rate) } label: {
                    Text(rateText(rate))
                        .font(CarTheme.rounded(14, .semibold))
                        .foregroundStyle(player.speed == rate ? .white : CarTheme.primaryText)
                        .frame(minWidth: 46, minHeight: 30)
                        .background(
                            Capsule().fill(player.speed == rate ? CarTheme.accent : CarTheme.field)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
        .disabled(!hasSelectedContent)
        .opacity(hasSelectedContent ? 1 : 0.35)
    }

    private var progressBar: some View {
        VStack(spacing: 0) {
            PlaybackSlider(
                value: Binding(
                    get: { max(0, min(player.currentTime, max(player.duration, 1))) },
                    set: { player.seek(to: $0) }
                ),
                duration: max(player.duration, 1)
            )
            .frame(height: 44)
            .disabled(player.duration <= 0)
            HStack {
                Text(formatHMS(player.currentTime))
                Spacer()
                Text("−" + formatHMS(max(0, player.duration - player.currentTime)))
            }
            .font(CarTheme.rounded(13).monospacedDigit())
            .foregroundStyle(CarTheme.secondaryText)
        }
    }

    // MARK: - Library

    private var localLibraryView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("LOCAL LIBRARY")
                            .font(CarTheme.rounded(12, .semibold))
                            .foregroundStyle(CarTheme.secondaryText)
                            .tracking(0.8)
                        Text("Audio files are copied into AltPlay and stay available offline.")
                            .font(CarTheme.rounded(14))
                            .foregroundStyle(CarTheme.secondaryText)
                    }
                    Spacer()
                    Button { showFileImporter = true } label: {
                        Label(localLibrary.isImporting ? "Importing" : "Import", systemImage: "plus")
                            .font(CarTheme.rounded(16, .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(minHeight: 44)
                            .background(CarTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(localLibrary.isImporting || localLibrary.catalogError != nil)
                    .opacity(localLibrary.isImporting ? 0.65 : 1)
                }

                if let error = importError ?? localLibrary.catalogError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(CarTheme.rounded(14, .medium))
                        .foregroundStyle(CarTheme.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(CarTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if localLibrary.books.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 38))
                            .foregroundStyle(CarTheme.accent.opacity(0.7))
                        Text("No local audiobooks")
                            .font(CarTheme.rounded(20, .semibold))
                            .foregroundStyle(CarTheme.primaryText)
                        Text("Import M4B, MP3, M4A, or other audio files from Files.")
                            .font(CarTheme.rounded(15))
                            .foregroundStyle(CarTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 34)
                    .tileBackground()
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 150), spacing: 16)],
                        spacing: 16
                    ) {
                        ForEach(localLibrary.books) { book in
                            localBookTile(book)
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private func localBookTile(_ book: LocalAudiobook) -> some View {
        VStack(spacing: 8) {
            Button {
                player.play(book)
                section = .nowPlaying
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    LocalAudiobookCover(book: book)
                        .aspectRatio(1, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    Text(book.title)
                        .font(CarTheme.rounded(16, .semibold))
                        .foregroundStyle(CarTheme.primaryText)
                        .lineLimit(2)
                    if !book.author.isEmpty {
                        Text(book.author)
                            .font(CarTheme.rounded(14))
                            .foregroundStyle(CarTheme.secondaryText)
                            .lineLimit(1)
                    }
                    if book.duration > 0, book.progress > 0 {
                        ProgressView(value: min(1, book.progress / book.duration))
                            .tint(CarTheme.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PressableButtonStyle())

            Button(role: .destructive) {
                player.stopLocalPlayback(ifPlaying: book)
                do {
                    try localLibrary.remove(book)
                } catch {
                    importError = "Could not remove \(book.title): \(error.localizedDescription)"
                }
            } label: {
                Label("Remove", systemImage: "trash")
                    .font(CarTheme.rounded(13, .semibold))
                    .foregroundStyle(CarTheme.red)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .background(CarTheme.field)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var libraryView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !absService.inProgress.isEmpty {
                    continueListeningSection
                        .padding(.bottom, 8)
                }

                libraryPicker
                    .padding(.bottom, 12)

                if libraryItems.isEmpty {
                    Text("No books found")
                        .font(CarTheme.rounded(16))
                        .foregroundStyle(CarTheme.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 140), spacing: 16)],
                        spacing: 16
                    ) {
                        ForEach(libraryItems) { item in
                            bookTile(item)
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var continueListeningSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CONTINUE LISTENING")
                .font(CarTheme.rounded(12, .semibold))
                .foregroundStyle(CarTheme.secondaryText)
                .tracking(0.8)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(absService.inProgress) { item in
                        Button {
                            Task { await playItem(item) }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                ABSCoverView(itemID: item.id)
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                Text(item.media?.title ?? "Untitled")
                                    .font(CarTheme.rounded(15, .semibold))
                                    .foregroundStyle(CarTheme.primaryText)
                                    .lineLimit(2)
                                ProgressView(value: item.media?.mediaProgress?.fraction ?? 0)
                                    .tint(CarTheme.accent)
                            }
                            .frame(width: 120)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
        }
    }

    private var libraryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(absService.libraries.filter { $0.mediaType == "book" || $0.mediaType == nil }) { lib in
                    Button {
                        selectedLibrary = lib.id
                    } label: {
                        Text(lib.name)
                            .font(CarTheme.rounded(15, .semibold))
                            .foregroundStyle(selectedLibrary == lib.id ? .white : CarTheme.primaryText)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 36)
                            .background(
                                Capsule().fill(selectedLibrary == lib.id ? CarTheme.accent : CarTheme.field)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func bookTile(_ item: ABSLibraryItem) -> some View {
        Button {
            Task { await playItem(item) }
        } label: {
            VStack(spacing: 10) {
                ABSCoverView(itemID: item.id)
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                HStack(spacing: 6) {
                    Text(item.media?.title ?? "Untitled")
                        .font(CarTheme.rounded(16, .semibold))
                        .foregroundStyle(CarTheme.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Spacer(minLength: 0)
                }
                if let author = item.media?.authorName, !author.isEmpty {
                    Text(author)
                        .font(CarTheme.rounded(14))
                        .foregroundStyle(CarTheme.secondaryText)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let progress = item.media?.mediaProgress, progress.fraction > 0 {
                    ProgressView(value: progress.fraction)
                        .tint(CarTheme.accent)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func playItem(_ item: ABSLibraryItem) async {
        await player.play(item)
        section = .nowPlaying
    }

    // MARK: - Connection prompt

    private var connectPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "server.rack")
                .font(.system(size: 44))
                .foregroundStyle(CarTheme.accent)
            Text("Audiobookshelf")
                .font(CarTheme.rounded(24, .semibold))
                .foregroundStyle(CarTheme.primaryText)
            Text("Connect to your Audiobookshelf server to browse and play your audiobooks.")
                .font(CarTheme.rounded(17))
                .foregroundStyle(CarTheme.secondaryText)
                .multilineTextAlignment(.center)
            Button {
                router.navigate(to: .settings)
            } label: {
                Text("Connect Server")
                    .font(CarTheme.rounded(18, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(CarTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: 480)
        .padding(24)
        .tileBackground()
    }

    private func loadingView(_ text: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .tint(CarTheme.accent)
            Text(text)
                .font(CarTheme.rounded(16))
                .foregroundStyle(CarTheme.secondaryText)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func rateText(_ rate: Float) -> String {
        rate == 1.0 ? "1×" : String(format: "%.2g×", rate)
    }

    private func formatHMS(_ t: TimeInterval) -> String {
        let total = max(0, Int(t))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }

    private var hasSelectedContent: Bool {
        player.hasContent && player.source == source
    }
}

// MARK: - Cover artwork

private struct ABSCoverView: View {
    let itemID: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else {
                ZStack {
                    CarTheme.tile
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(CarTheme.accent.opacity(0.35))
                }
            }
        }
        .task(id: itemID) {
            image = await AudiobookshelfService.shared.coverImage(for: itemID, width: 400)
        }
    }
}

private struct LocalAudiobookCover: View {
    let book: LocalAudiobook

    var body: some View {
        Group {
            if let image = LocalAudiobookLibrary.shared.artwork(for: book) {
                Image(uiImage: image)
                    .resizable()
            } else {
                ZStack {
                    CarTheme.tile
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(CarTheme.accent.opacity(0.4))
                }
            }
        }
    }
}
