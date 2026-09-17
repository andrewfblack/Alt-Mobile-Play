import SwiftUI
import CoreLocation
import MapKit

struct HomeWidgetView: View {
    let kind: HomeWidgetKind

    var body: some View {
        switch kind {
        case .nowPlaying: NowPlayingWidget()
        case .navigation: NavigationWidget()
        case .quickMessages: MessagesWidget()
        }
    }
}

// MARK: - Now Playing Widget

private struct NowPlayingWidget: View {
    @Environment(AppRouter.self) private var router
    @State private var music = NowPlayingService.shared
    @State private var audioBook = AudiobookPlayerService.shared

    var body: some View {
        Group {
            if audioBook.hasContent {
                audiobookLayout
            } else {
                musicLayout
            }
        }
        .padding(14)
        .contentShape(Rectangle())
        .onTapGesture { router.navigate(to: audioBook.hasContent ? .audiobooks : .music) }
    }

    // MARK: - Apple Music

    private var musicLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("APPLE MUSIC")
                .font(CarTheme.rounded(10, .semibold))
                .foregroundStyle(CarTheme.accent)
                .tracking(0.8)
            GeometryReader { geo in
                let side = max(0, min(geo.size.width, geo.size.height))
                artworkView
                    .frame(width: side, height: side)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                Text(music.title)
                    .font(CarTheme.rounded(19, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
                    .lineLimit(2)
                if !music.artist.isEmpty {
                    Text(music.artist)
                        .font(CarTheme.rounded(15))
                        .foregroundStyle(CarTheme.secondaryText)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)

            controls
        }
    }

    // MARK: - Audiobook

    private var audiobookLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AUDIOBOOK")
                .font(CarTheme.rounded(10, .semibold))
                .foregroundStyle(CarTheme.accent)
                .tracking(0.8)
            GeometryReader { geo in
                let side = max(0, min(geo.size.width, geo.size.height))
                Group {
                    if let img = audioBook.artwork {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ZStack {
                            CarTheme.accent.opacity(0.18)
                            Image(systemName: "book.closed.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(CarTheme.accent.opacity(0.5))
                        }
                    }
                }
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task { await audioBook.refreshArtwork() }
            }
            .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                Text(audioBook.title)
                    .font(CarTheme.rounded(19, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
                    .lineLimit(2)
                if !audioBook.author.isEmpty {
                    Text(audioBook.author)
                        .font(CarTheme.rounded(15))
                        .foregroundStyle(CarTheme.secondaryText)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)

            audiobookControls
        }
    }

    @ViewBuilder
    private var artworkView: some View {
        Group {
            if let img = music.artwork {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    CarTheme.accent.opacity(0.18)
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundStyle(CarTheme.accent.opacity(0.5))
                }
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 26) {
            Button { music.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(CarTheme.primaryText)
                    .frame(width: 52, height: 44)
            }
            .accessibilityLabel("Previous track")
            Button { music.playPause() } label: {
                Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(CarTheme.primaryText)
                    .frame(width: 56, height: 44)
            }
            .accessibilityLabel(music.isPlaying ? "Pause" : "Play")
            Button { music.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(CarTheme.primaryText)
                    .frame(width: 52, height: 44)
            }
            .accessibilityLabel("Next track")
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .disabled(!music.hasContent)
        .opacity(music.hasContent ? 1 : 0.35)
    }

    private var audiobookControls: some View {
        HStack(spacing: 26) {
            Button { audioBook.skipBack() } label: {
                Image(systemName: "gobackward.30")
                    .font(.system(size: 22))
                    .foregroundStyle(CarTheme.primaryText)
                    .frame(width: 52, height: 44)
            }
            .accessibilityLabel("Back 30 seconds")
            Button { audioBook.playPause() } label: {
                Image(systemName: audioBook.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(CarTheme.primaryText)
                    .frame(width: 56, height: 44)
            }
            .accessibilityLabel(audioBook.isPlaying ? "Pause" : "Play")
            Button { audioBook.skipForward() } label: {
                Image(systemName: "goforward.30")
                    .font(.system(size: 22))
                    .foregroundStyle(CarTheme.primaryText)
                    .frame(width: 52, height: 44)
            }
            .accessibilityLabel("Forward 30 seconds")
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .disabled(!audioBook.hasContent)
        .opacity(audioBook.hasContent ? 1 : 0.35)
    }
}

// MARK: - Navigation Widget

private struct NavigationWidget: View {
    @Environment(AppRouter.self) private var router
    @State private var nav = NavigationState.shared
    @State private var contacts = ContactsService.shared
    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NAVIGATION")
                .font(CarTheme.rounded(10, .semibold))
                .foregroundStyle(CarTheme.accent)
                .tracking(0.8)

            ZStack {
                Map(position: $camera, interactionModes: []) {
                    UserAnnotation()
                    if nav.isNavigating, let route = nav.route {
                        MapPolyline(route.polyline)
                            .stroke(CarTheme.accent, lineWidth: 4)
                    }
                }
                .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                if !nav.locationAuthorized {
                    Button(action: enableLocation) {
                        Label("Enable location", systemImage: "location.fill")
                            .font(CarTheme.rounded(15, .semibold))
                            .padding(12)
                            .background(CarTheme.tile, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(CarTheme.primaryText)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                if nav.isNavigating {
                    Text(nav.nextInstruction.isEmpty ? "Continue on route" : nav.nextInstruction)
                        .font(CarTheme.rounded(19, .semibold))
                        .foregroundStyle(CarTheme.primaryText)
                        .lineLimit(2)
                    Text(nav.destinationTitle)
                        .font(CarTheme.rounded(15))
                        .foregroundStyle(CarTheme.secondaryText)
                        .lineLimit(1)
                    Text(nav.routeSummary)
                        .font(CarTheme.rounded(15))
                        .foregroundStyle(CarTheme.secondaryText)
                        .lineLimit(1)
                } else {
                    Text("Where to?")
                        .font(CarTheme.rounded(19, .semibold))
                        .foregroundStyle(CarTheme.primaryText)
                    quickNavButtons
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .contentShape(Rectangle())
        .onTapGesture { router.navigate(to: .navigation) }
        .onAppear { nav.requestLocationPermission() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                nav.requestLocationPermission()
                camera = .userLocation(fallback: .automatic)
            }
        }
    }

    private func enableLocation() {
        let status = CLLocationManager().authorizationStatus
        if status == .denied || status == .restricted {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } else {
            nav.requestLocationPermission()
        }
    }

    @ViewBuilder
    private var quickNavButtons: some View {
        HStack(spacing: 8) {
            Button { router.navigate(to: .navigation) } label: {
                Label("Search", systemImage: "magnifyingglass")
                    .font(CarTheme.rounded(14, .medium))
                    .padding(.horizontal, 10)
                    .frame(minHeight: 44)
                    .background(CarTheme.accent.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(CarTheme.primaryText)
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
                .font(CarTheme.rounded(14, .medium))
                .foregroundStyle(CarTheme.primaryText)
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
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

// MARK: - Messages Widget

private struct MessagesWidget: View {
    @Environment(AppRouter.self) private var router
    @State private var contacts = ContactsService.shared

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(CarTheme.accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "message.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(CarTheme.accent)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("MESSAGES")
                    .font(CarTheme.rounded(10, .semibold))
                    .foregroundStyle(CarTheme.accent)
                    .tracking(0.8)
                if let contact = contacts.contacts.first {
                    Text(contact.displayName)
                        .font(CarTheme.rounded(19, .semibold))
                        .foregroundStyle(CarTheme.primaryText)
                        .lineLimit(1)
                } else {
                    Text("No contacts yet")
                        .font(CarTheme.rounded(15))
                        .foregroundStyle(CarTheme.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if let contact = contacts.contacts.first {
                HStack(spacing: 8) {
                    ForEach(QuickMessageCatalog.all.prefix(2)) { msg in
                        Button { send(msg, to: contact) } label: {
                            Text(msg.text)
                                .font(CarTheme.rounded(14, .medium))
                                .foregroundStyle(CarTheme.primaryText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(CarTheme.accent.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .contentShape(Rectangle())
        .onTapGesture { router.navigate(to: .messages) }
    }

    private func send(_ msg: QuickMessage, to contact: ContactRow) {
        guard let phone = contact.primaryPhone else { return }
        guard let url = URL(string: "sms:\(phone.digitsOnly)") else { return }
        UIApplication.shared.open(url)
    }
}
