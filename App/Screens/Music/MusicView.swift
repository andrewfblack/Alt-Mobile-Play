import SwiftUI
import MediaPlayer

enum MusicSection: String, CaseIterable, Identifiable {
    case nowPlaying = "Now Playing"
    case songs = "Songs"
    case albums = "Albums"
    case playlists = "Playlists"
    var id: String { rawValue }
}

struct MusicView: View {
    @Environment(AppRouter.self) private var router
    @State private var music = NowPlayingService.shared
    @State private var section: MusicSection = .nowPlaying

    var body: some View {
        VStack(spacing: 8) {
            Text("Apple Music")
                .font(CarTheme.rounded(24, .semibold))
                .foregroundStyle(CarTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            if music.authStatus == .authorized {
                Picker("", selection: $section) {
                    ForEach(MusicSection.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            if music.authStatus == .notDetermined {
                Task { await music.requestAccess() }
            } else if music.authStatus == .authorized, music.songs.isEmpty {
                music.loadLibrary()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if music.authStatus != .authorized {
            authPrompt
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch section {
            case .nowPlaying: nowPlayingView
            case .songs: songsView
            case .albums: albumsView
            case .playlists: playlistsView
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
                        if music.hasContent {
                            trackInfo
                        } else {
                            Text("No Apple Music track selected")
                                .font(CarTheme.rounded(24, .semibold))
                                .foregroundStyle(CarTheme.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Choose a song, album, or playlist to begin.")
                                .font(CarTheme.rounded(15))
                                .foregroundStyle(CarTheme.secondaryText)
                            Button("Browse Songs") { section = .songs }
                                .buttonStyle(.bordered)
                                .tint(CarTheme.accent)
                        }
                        Spacer(minLength: 0)
                        transportControls
                        Group {
                            if music.hasContent {
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

    private var artworkView: some View {
        Group {
            if let img = music.artwork {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    CarTheme.tile
                    Image(systemName: "music.note")
                        .font(.system(size: 80))
                        .foregroundStyle(CarTheme.accent.opacity(0.35))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var trackInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(music.title)
                .font(CarTheme.rounded(26, .bold))
                .foregroundStyle(CarTheme.primaryText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(music.artist)
                .font(CarTheme.rounded(19))
                .foregroundStyle(CarTheme.secondaryText)
                .lineLimit(1)
            Text(music.album)
                .font(CarTheme.rounded(15))
                .foregroundStyle(CarTheme.secondaryText)
                .lineLimit(1)
        }
    }

    private var transportControls: some View {
        HStack(spacing: 32) {
            Button { music.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 32))
                    .frame(width: 56, height: 52)
            }
            .accessibilityLabel("Previous track")
            Button { music.playPause() } label: {
                Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 40))
                    .frame(width: 64, height: 52)
            }
            .accessibilityLabel(music.isPlaying ? "Pause" : "Play")
            Button { music.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 32))
                    .frame(width: 56, height: 52)
            }
            .accessibilityLabel("Next track")
        }
        .buttonStyle(.plain)
        .foregroundStyle(CarTheme.primaryText)
        .disabled(!music.hasContent)
        .opacity(music.hasContent ? 1 : 0.35)
    }

    private var progressBar: some View {
        VStack(spacing: 0) {
            PlaybackSlider(
                value: Binding(
                    get: { max(0, min(music.currentTime, max(music.duration, 1))) },
                    set: { music.seek($0) }
                ),
                duration: max(music.duration, 1)
            )
            .frame(height: 44)
            .disabled(music.duration <= 0)
            HStack {
                Text(formatTime(music.currentTime))
                Spacer()
                Text("−" + formatTime(max(0, music.duration - music.currentTime)))
            }
            .font(CarTheme.rounded(13).monospacedDigit())
            .foregroundStyle(CarTheme.secondaryText)
        }
    }

    // MARK: - Songs

    private var songsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(music.songs, id: \.persistentID) { item in
                    Button {
                        music.play(item)
                        section = .nowPlaying
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "music.note")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(CarTheme.accent)
                                .frame(width: 48, height: 48)
                                .background(CarTheme.accent.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title ?? "Untitled")
                                    .font(CarTheme.rounded(19, .semibold))
                                    .foregroundStyle(CarTheme.primaryText)
                                    .lineLimit(1)
                                Text(item.artist ?? "")
                                    .font(CarTheme.rounded(15))
                                    .foregroundStyle(CarTheme.secondaryText)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(formatTime(item.playbackDuration))
                                .font(CarTheme.rounded(14).monospacedDigit())
                                .foregroundStyle(CarTheme.tertiaryText)
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(CarTheme.accent)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if item.persistentID != music.songs.last?.persistentID {
                        Divider()
                            .background(CarTheme.tertiaryText.opacity(0.3))
                            .padding(.leading, 88)
                    }
                }
            }
        }
    }

    // MARK: - Albums

    private var albumsView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                ForEach(music.albums, id: \.persistentID) { album in
                    let item = album.representativeItem
                    Button {
                        music.play(album: album)
                        section = .nowPlaying
                    } label: {
                        VStack(spacing: 10) {
                            artworkTile(item?.artwork)
                                .aspectRatio(1, contentMode: .fill)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            Text(item?.albumTitle ?? "Unknown Album")
                                .font(CarTheme.rounded(16, .semibold))
                                .foregroundStyle(CarTheme.primaryText)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(24)
        }
    }

    // MARK: - Playlists

    private var playlistsView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(music.playlists, id: \.persistentID) { playlist in
                    let item = playlist.representativeItem
                    Button {
                        music.play(playlist: playlist)
                        section = .nowPlaying
                    } label: {
                        HStack(spacing: 16) {
                            artworkTile(item?.artwork)
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(playlist.name ?? "Untitled Playlist")
                                    .font(CarTheme.rounded(20, .semibold))
                                    .foregroundStyle(CarTheme.primaryText)
                                    .lineLimit(1)
                                Text("\(playlist.items.count) songs")
                                    .font(CarTheme.rounded(15))
                                    .foregroundStyle(CarTheme.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(CarTheme.accent)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if playlist.persistentID != music.playlists.last?.persistentID {
                        Divider()
                            .background(CarTheme.tertiaryText.opacity(0.3))
                            .padding(.leading, 104)
                    }
                }
            }
        }
    }

    private func artworkTile(_ art: MPMediaItemArtwork?) -> some View {
        Group {
            if let img = art?.image(at: CGSize(width: 300, height: 300)) {
                Image(uiImage: img)
                    .resizable()
            } else {
                ZStack {
                    CarTheme.tile
                    Image(systemName: "music.note")
                        .font(.system(size: 26))
                        .foregroundStyle(CarTheme.accent.opacity(0.35))
                }
            }
        }
    }

    // MARK: - Auth

    private var authPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundStyle(CarTheme.accent)
            Text("Music Library Access")
                .font(CarTheme.rounded(24, .semibold))
                .foregroundStyle(CarTheme.primaryText)
            Text("Allow access to browse and play songs from your Apple Music library.")
                .font(CarTheme.rounded(17))
                .foregroundStyle(CarTheme.secondaryText)
                .multilineTextAlignment(.center)
            Button {
                Task { await music.requestAccess() }
            } label: {
                Text("Enable Access")
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

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}
