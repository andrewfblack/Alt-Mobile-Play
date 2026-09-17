import SwiftUI
import UIKit

enum AudiobooksSection: String, CaseIterable, Identifiable {
    case nowPlaying = "Now Playing"
    case library = "Library"
    var id: String { rawValue }
}

struct AudiobooksView: View {
    @Environment(AppRouter.self) private var router
    @State private var absService = AudiobookshelfService.shared
    @State private var player = AudiobookPlayerService.shared
    @State private var section: AudiobooksSection = .nowPlaying
    @State private var selectedLibrary: String?
    @State private var libraryItems: [ABSLibraryItem] = []

    var body: some View {
        VStack(spacing: 8) {
            topTitle("Audiobooks")
                .padding(.horizontal, 24)
                .padding(.top, 16)

            if absService.isConnected {
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
        .onAppear { load() }
        .onChange(of: absService.libraries) { _, libs in
            if selectedLibrary == nil, let first = libs.first {
                selectedLibrary = first.id
            }
            refreshLibraryItems()
        }
        .onChange(of: selectedLibrary) { _, _ in refreshLibraryItems() }
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

    // MARK: - Now Playing

    private var nowPlayingView: some View {
        GeometryReader { geo in
            let artworkSize = max(0, min(280, geo.size.width * 0.34, geo.size.height - 24))
            HStack(spacing: 24) {
                artworkView
                    .frame(width: artworkSize, height: artworkSize)
                VStack(alignment: .leading, spacing: 8) {
                    if player.hasContent {
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
                            if !absService.inProgress.isEmpty {
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
                        if player.hasContent {
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
            if let img = player.artwork {
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
        .disabled(!player.hasContent)
        .opacity(player.hasContent ? 1 : 0.35)
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
        .opacity(player.hasContent ? 1 : 0.35)
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