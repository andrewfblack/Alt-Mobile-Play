import SwiftUI
import CoreLocation
import MapKit

struct HomeScreenView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            NowPlayingWidget()
                .frame(maxWidth: .infinity, alignment: .leading)
            NavigationWidget()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .onAppear { settings.apply() }
    }
}

// MARK: - Now Playing Widget

private struct NowPlayingWidget: View {
    @Environment(AppRouter.self) private var router
    @State private var music = NowPlayingService.shared

    var body: some View {
        HStack(spacing: 16) {
            artworkView
            VStack(alignment: .leading, spacing: 6) {
                Text("NOW PLAYING")
                    .font(CarTheme.rounded(11, .semibold))
                    .foregroundStyle(CarTheme.accent)
                    .tracking(0.8)
                Text(music.title)
                    .font(CarTheme.rounded(24, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
                    .lineLimit(2)
                if !music.artist.isEmpty {
                    Text(music.artist)
                        .font(CarTheme.rounded(18))
                        .foregroundStyle(CarTheme.secondaryText)
                        .lineLimit(1)
                }
            }
            Spacer()
            controls
        }
        .padding(18)
        .tileBackground()
        .contentShape(Rectangle())
        .onTapGesture { router.navigate(to: .music) }
    }

    @ViewBuilder
    private var artworkView: some View {
        if let img = music.artwork {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(CarTheme.accent.opacity(0.18))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 30))
                        .foregroundStyle(CarTheme.accent.opacity(0.5))
                }
        }
    }

    private var controls: some View {
        HStack(spacing: 22) {
            Button { music.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(CarTheme.primaryText)
            }
            Button { music.playPause() } label: {
                Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(CarTheme.primaryText)
            }
            Button { music.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(CarTheme.primaryText)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Navigation Widget

private struct NavigationWidget: View {
    @Environment(AppRouter.self) private var router
    @State private var nav = NavigationState.shared
    @State private var contacts = ContactsService.shared

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.system(size: 28))
                .foregroundStyle(CarTheme.accent)
                .frame(width: 56, height: 56)
                .background(CarTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("NAVIGATION")
                    .font(CarTheme.rounded(11, .semibold))
                    .foregroundStyle(CarTheme.accent)
                    .tracking(0.8)

                if nav.isNavigating {
                    Text(nav.destinationTitle)
                        .font(CarTheme.rounded(22, .semibold))
                        .foregroundStyle(CarTheme.primaryText)
                        .lineLimit(1)
                    Text(nav.routeSummary)
                        .font(CarTheme.rounded(16))
                        .foregroundStyle(CarTheme.secondaryText)
                } else {
                    quickNavButtons
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(CarTheme.tertiaryText)
        }
        .padding(18)
        .tileBackground()
        .contentShape(Rectangle())
        .onTapGesture { router.navigate(to: .navigation) }
    }

    @ViewBuilder
    private var quickNavButtons: some View {
        HStack(spacing: 10) {
            if let home = contacts.homeAddress() {
                suggestionChip(label: "Home", address: home)
            }
            if let work = contacts.workAddress() {
                suggestionChip(label: "Work", address: work)
            }
        }
    }

    private func suggestionChip(label: String, address: String) -> some View {
        Button {
            Task { await geocodeAndNavigate(address: address, title: label) }
        } label: {
            Text(label)
                .font(CarTheme.rounded(15, .medium))
                .foregroundStyle(CarTheme.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(CarTheme.accent.opacity(0.15))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func geocodeAndNavigate(address: String, title: String) async {
        do {
            let placemarks = try await CLGeocoder().geocodeAddressString(address)
            if let p = placemarks.first, let loc = p.location {
                let item = MKMapItem(placemark: MKPlacemark(coordinate: loc.coordinate))
                item.name = title
                nav.setTarget(item, title: title, subtitle: address)
                router.navigate(to: .navigation)
            }
        } catch {}
    }
}
