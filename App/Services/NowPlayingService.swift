import MediaPlayer
import Observation

@Observable
final class NowPlayingService {
    static let shared = NowPlayingService()

    var authStatus: MPMediaLibraryAuthorizationStatus = .notDetermined
    var nowItem: MPMediaItem?
    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 0
    var songs: [MPMediaItem] = []
    var albums: [MPMediaItemCollection] = []
    var playlists: [MPMediaPlaylist] = []

    var hasContent: Bool { nowItem != nil }
    var artwork: UIImage? { nowItem?.artwork?.image(at: CGSize(width: 300, height: 300)) }
    var title: String { nowItem?.title ?? "Not Playing" }
    var artist: String { nowItem?.artist ?? "" }
    var album: String { nowItem?.albumTitle ?? "" }

    @ObservationIgnored private let player = MPMusicPlayerController.systemMusicPlayer
    @ObservationIgnored private var timer: Timer?

    private init() {
        authStatus = MPMediaLibrary.authorizationStatus()
        player.beginGeneratingPlaybackNotifications()

        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: player,
            queue: .main
        ) { [weak self] _ in self?.syncNow() }

        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: player,
            queue: .main
        ) { [weak self] _ in self?.syncState() }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTime = self?.player.currentPlaybackTime ?? 0
        }
        RunLoop.main.add(timer!, forMode: .common)
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
        albums = MPMediaQuery.albums().collections ?? []
        playlists = MPMediaQuery.playlists().collections ?? []
        player.setQueue(with: MPMediaQuery.songs())
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

    func next() { player.skipToNextItem() }
    func previous() { player.skipToPreviousItem() }
    func seek(_ t: Double) { player.currentPlaybackTime = t }

    private func syncNow() {
        nowItem = player.nowPlayingItem
        duration = nowItem?.playbackDuration ?? 0
        currentTime = player.currentPlaybackTime
    }

    private func syncState() {
        isPlaying = player.playbackState == .playing
    }
}
