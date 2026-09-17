import AVFoundation
import MediaPlayer
import Observation
import UIKit

@Observable
final class AudiobookPlayerService {
    static let shared = AudiobookPlayerService()

    private(set) var currentBook: ABSLibraryItem?
    private(set) var session: ABSPlaybackSession?
    private(set) var isPlaying = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    private(set) var speed: Float = 1.0
    private(set) var artwork: UIImage?

    @ObservationIgnored private let absService = AudiobookshelfService.shared
    @ObservationIgnored private var player = AVPlayer()
    @ObservationIgnored private var periodicObserver: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?
    @ObservationIgnored private var progressTimer: Timer?
    @ObservationIgnored private var tracks: [ABSAudioTrack] = []
    @ObservationIgnored private var activeTrackIndex = 0
    @ObservationIgnored private var commandTargets: [Any] = []

    let skipInterval: Double = 30
    let supportedSpeeds: [Float] = [0.75, 1.0, 1.25, 1.5, 2.0]

    var hasContent: Bool { currentBook != nil }
    var title: String { session?.displayTitle ?? currentBook?.media?.title ?? "" }
    var author: String { session?.displayAuthor ?? currentBook?.media?.authorName ?? "" }
    var series: String { currentBook?.media?.metadata?.seriesName ?? "" }

    private init() {
        periodicObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in
            self?.syncTime()
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleTrackEnd()
        }

        setupRemoteCommands()
    }

    // MARK: - Playback

    func play(_ book: ABSLibraryItem, startAt startTime: Double? = nil) async {
        do {
            guard let liveBook = try? await absService.item(id: book.id) else { return }
            let sessionInfo = try await absService.startPlaybackSession(itemID: liveBook.id)
            let loadedTracks = (sessionInfo.audioTracks ?? [])
                .sorted { ($0.startOffset ?? 0) < ($1.startOffset ?? 0) }
            guard !loadedTracks.isEmpty else { return }

            currentBook = liveBook
            session = sessionInfo
            tracks = loadedTracks
            duration = sessionInfo.duration ?? book.media?.duration ?? 0
            speed = 1.0
            activeTrackIndex = Self.trackIndex(at: startTime ?? 0, tracks: loadedTracks)

            activateAudioSession()
            isPlaying = true
            loadTrack(activeTrackIndex, startTime: (startTime ?? 0) - Self.start(for: activeTrackIndex, tracks: loadedTracks))
            player.rate = speed

            startProgressTimer()
            updateNowPlaying()
            await refreshArtwork()
            syncProgress()
        } catch {
            absService.lastError = error.localizedDescription
        }
    }

    func playPause() {
        guard hasContent else { return }
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    func pause() {
        guard isPlaying else { return }
        player.pause()
        isPlaying = false
        updateNowPlaying()
        syncProgress()
    }

    func resume() {
        guard hasContent, !isPlaying else { return }
        activateAudioSession()
        player.play()
        player.rate = speed
        isPlaying = true
        updateNowPlaying()
    }

    func seek(to time: Double) {
        guard hasContent else { return }
        let clamped = max(0, min(time, duration))
        let index = Self.trackIndex(at: clamped, tracks: tracks)
        let trackStart = Self.start(for: index, tracks: tracks)
        if index != activeTrackIndex {
            loadTrack(index, startTime: clamped - trackStart)
        } else {
            player.seek(to: CMTime(seconds: clamped - trackStart, preferredTimescale: 600),
                         toleranceBefore: .zero, toleranceAfter: .zero)
        }
        currentTime = clamped
        updateNowPlaying()
        syncProgress()
    }

    func skipBack() {
        seek(to: currentTime - skipInterval)
    }

    func skipForward() {
        seek(to: currentTime + skipInterval)
    }

    func setSpeed(_ newSpeed: Float) {
        guard supportedSpeeds.contains(newSpeed) else { return }
        speed = newSpeed
        player.rate = isPlaying ? newSpeed : 0
        updateNowPlaying()
    }

    // MARK: - Track sequencing

    private func loadTrack(_ index: Int, startTime: Double) {
        guard index >= 0, index < tracks.count else { return }
        let track = tracks[index]
        guard let url = streamURL(for: track) else { return }

        activeTrackIndex = index
        currentTime = Self.start(for: index, tracks: tracks) + (startTime > 0 ? startTime : 0)
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        if startTime > 0 {
            player.seek(to: CMTime(seconds: startTime, preferredTimescale: 600),
                        toleranceBefore: .zero, toleranceAfter: .zero)
        }
        if isPlaying {
            player.play()
            player.rate = speed
        }
    }

    private func handleTrackEnd() {
        guard hasContent else { return }
        let next = activeTrackIndex + 1
        if next < tracks.count {
            loadTrack(next, startTime: 0)
        } else {
            finishBook()
        }
    }

    private func finishBook() {
        player.pause()
        isPlaying = false
        currentTime = duration
        stopProgressTimer()
        updateNowPlaying()
        syncProgress()
    }

    private func streamURL(for track: ABSAudioTrack) -> URL? {
        guard let path = track.contentUrl, let base = absService.baseURL,
              let url = URL(string: path, relativeTo: base),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else { return nil }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "token", value: absService.token))
        components.queryItems = items
        return components.url
    }

    private static func start(for index: Int, tracks: [ABSAudioTrack]) -> Double {
        tracks.prefix(index).reduce(0) { $0 + ($1.duration ?? 0) }
    }

    private static func trackIndex(at time: Double, tracks: [ABSAudioTrack]) -> Int {
        guard !tracks.isEmpty else { return 0 }
        for (index, track) in tracks.enumerated() {
            let nextStart = index + 1 < tracks.count ? (tracks[index + 1].startOffset ?? 0) : .infinity
            if time < nextStart, time >= (track.startOffset ?? 0) {
                return index
            }
        }
        return tracks.count - 1
    }

    private func syncTime() {
        guard hasContent else { return }
        let playbackTime = player.currentTime().seconds
        guard playbackTime.isFinite else { return }
        currentTime = Self.start(for: activeTrackIndex, tracks: tracks) + playbackTime
        updateNowPlaying(light: true)
    }

    func refreshArtwork() async {
        guard let book = currentBook else { return }
        artwork = await absService.coverImage(for: book.id, width: 600)
        updateNowPlaying()
    }

    // MARK: - Progress sync

    private func startProgressTimer() {
        stopProgressTimer()
        let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.syncProgress()
        }
        RunLoop.main.add(timer, forMode: .common)
        progressTimer = timer
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func syncProgress() {
        guard let book = currentBook else { return }
        Task {
            await absService.saveProgress(itemID: book.id, currentTime: currentTime, duration: duration)
        }
    }

    // MARK: - Now playing / lock screen

    private func activateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
    }

    private func updateNowPlaying(light: Bool = false) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: author,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? speed : 0,
        ]
        if !series.isEmpty {
            info[MPMediaItemPropertyAlbumTitle] = series
        }
        if let artwork {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in artwork }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.skipForwardCommand.isEnabled = true
        center.skipBackwardCommand.isEnabled = true
        center.changePlaybackPositionCommand.isEnabled = true

        center.skipForwardCommand.preferredIntervals = [NSNumber(value: skipInterval)]
        center.skipBackwardCommand.preferredIntervals = [NSNumber(value: skipInterval)]

        commandTargets.append(center.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        })
        commandTargets.append(center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        })
        commandTargets.append(center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.playPause()
            return .success
        })
        commandTargets.append(center.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward()
            return .success
        })
        commandTargets.append(center.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBack()
            return .success
        })
        commandTargets.append(center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let changeEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: changeEvent.positionTime)
            return .success
        })
    }
}