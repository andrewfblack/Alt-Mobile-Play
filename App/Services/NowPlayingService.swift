import MediaPlayer
import Observation

@Observable
@MainActor
final class NowPlayingService {
    static let shared = NowPlayingService()

    var authStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    private(set) var hasContent = false
    private(set) var artwork: UIImage?
    private(set) var title = "No Apple Music track selected"
    private(set) var artist = ""
    private(set) var album = ""
    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 0
    var songs: [MPMediaItem] = []
    var albums: [MPMediaItemCollection] = []
    var playlists: [MPMediaPlaylist] = []

    @ObservationIgnored private let player = MPMusicPlayerController.systemMusicPlayer
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var syncScheduled = false

    private init() {
        authStatus = MPMediaLibrary.authorizationStatus()
        player.beginGeneratingPlaybackNotifications()

        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.scheduleNowSync() }
        }

        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: player,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.syncState() }
        }

        scheduleNowSync()
        syncState()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.syncPlaybackState() }
        }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }

    func requestAccess() async {
        guard authStatus == .notDetermined || authStatus == .denied else { return }
        authStatus = await MPMediaLibrary.requestAuthorization()
        if authStatus == .authorized { loadLibrary() }
    }

    func loadLibrary() {
        guard authStatus == .authorized else { return }
        songs = (MPMediaQuery.songs().items ?? []).sorted {
            ($0.title ?? "").caseInsensitiveCompare($1.title ?? "") == .orderedAscending
        }
        albums = MPMediaQuery.albums().collections ?? [MPMediaItemCollection]()
        playlists = (MPMediaQuery.playlists().collections ?? []).compactMap { $0 as? MPMediaPlaylist }
    }

    func play(_ item: MPMediaItem) {
        guard let idx = songs.firstIndex(where: { $0.persistentID == item.persistentID }) else {
            player.setQueue(with: MPMediaItemCollection(items: [item]))
            player.play()
            return
        }
        player.setQueue(with: MPMediaItemCollection(items: songs))
        player.nowPlayingItem = songs[idx]
        player.play()
    }

    func play(album: MPMediaItemCollection) {
        guard !album.items.isEmpty else { return }
        player.setQueue(with: album)
        player.play()
    }

    func play(playlist: MPMediaPlaylist) {
        guard !playlist.items.isEmpty else { return }
        player.setQueue(with: MPMediaItemCollection(items: playlist.items))
        player.play()
    }

    func playPause() {
        guard hasContent else { return }
        isPlaying ? player.pause() : player.play()
    }

    func next() { if hasContent { player.skipToNextItem() } }
    func previous() { if hasContent { player.skipToPreviousItem() } }
    func seek(_ t: Double) { if hasContent { player.currentPlaybackTime = t } }

    private func scheduleNowSync() {
        guard !syncScheduled else { return }
        syncScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            syncScheduled = false
            syncNow()
            syncState()
        }
    }

    private func syncNow() {
        guard let item = player.nowPlayingItem else {
            hasContent = false
            artwork = nil
            title = "No Apple Music track selected"
            artist = ""
            album = ""
            duration = 0
            currentTime = 0
            return
        }

        let itemArtwork = item.artwork?.image(at: CGSize(width: 300, height: 300))
        hasContent = true
        artwork = itemArtwork
        title = item.title ?? "Unknown Track"
        artist = item.artist ?? ""
        album = item.albumTitle ?? ""
        duration = item.playbackDuration
        currentTime = player.currentPlaybackTime
    }

    private func syncPlaybackState() {
        if hasContent { currentTime = player.currentPlaybackTime }
        syncState()
    }

    private func syncState() {
        isPlaying = hasContent && player.playbackState == .playing
    }
}
