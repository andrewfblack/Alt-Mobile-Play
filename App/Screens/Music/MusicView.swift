import SwiftUI
import MediaPlayer

struct MusicView: View {
    @Environment(AppRouter.self) private var router
    @State private var music = NowPlayingService.shared

    var body: some View {
        VStack(spacing: 24) {
            topTitle("Music")
            HStack(spacing: 28) {
                artworkView
                    .frame(width: 280, height: 280)
                VStack(alignment: .leading, spacing: 24) {
                    if music.authStatus != .authorized {
                        authPrompt
                    } else {
                        trackInfo
                        transportControls
                        progressBar
                        volumeBar
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 32)
            Spacer()
        }
        .padding(.top, 24)
        .onAppear {
            if music.authStatus == .notDetermined {
                Task { await music.requestAccess() }
            }
        }
    }

    // MARK: - Components

    private var artworkView: some View {
        Group {
            if let img = music.artwork {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(music.title)
                .font(CarTheme.rounded(30, .bold))
                .foregroundStyle(CarTheme.primaryText)
                .lineLimit(2)
            Text(music.artist)
                .font(CarTheme.rounded(22))
                .foregroundStyle(CarTheme.secondaryText)
                .lineLimit(1)
            Text(music.album)
                .font(CarTheme.rounded(18))
                .foregroundStyle(CarTheme.tertiaryText)
                .lineLimit(1)
        }
    }

    private var transportControls: some View {
        HStack(spacing: 32) {
            Button { music.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 32))
            }
            Button { music.playPause() } label: {
                Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 48))
            }
            Button { music.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 32))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(CarTheme.primaryText)
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { music.currentTime },
                    set: { music.seek($0) }
                ),
                in: 0 ... max(music.duration, 1)
            ) {
                EmptyView()
            } minimumValueLabel: {
                Text(formatTime(music.currentTime))
                    .font(CarTheme.rounded(13).monospacedDigit())
                    .foregroundStyle(CarTheme.secondaryText)
            } maximumValueLabel: {
                Text(formatTime(music.duration))
                    .font(CarTheme.rounded(13).monospacedDigit())
                    .foregroundStyle(CarTheme.secondaryText)
            }
            .tint(CarTheme.accent)
        }
    }

    private var volumeBar: some View {
        SystemVolumeView()
            .frame(maxWidth: 260)
    }

    private var authPrompt: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 32))
                .foregroundStyle(CarTheme.accent)
            Text("Music Library Access")
                .font(CarTheme.rounded(24, .semibold))
                .foregroundStyle(CarTheme.primaryText)
            Text("Allow access to play songs from your Apple Music library.")
                .font(CarTheme.rounded(17))
                .foregroundStyle(CarTheme.secondaryText)
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
        }
        .padding(24)
        .tileBackground()
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - System Volume

private struct SystemVolumeView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.tintColor = UIColor(CarTheme.accent)
        view.showsVolumeSlider = true
        return view
    }
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
