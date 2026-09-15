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
        player.setQueue(with: MPMediaQuery.songs())
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
