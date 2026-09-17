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

    var body: some View {
        HStack(spacing: 12) {
            artworkView
            VStack(alignment: .leading, spacing: 5) {
                Text("NOW PLAYING")
                    .font(CarTheme.rounded(10, .semibold))
                    .foregroundStyle(CarTheme.accent)
                    .tracking(0.8)
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
            Spacer(minLength: 4)
            controls
        }
        .padding(14)
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
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(CarTheme.accent.opacity(0.18))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 22))
                        .foregroundStyle(CarTheme.accent.opacity(0.5))
                }
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button { music.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(CarTheme.primaryText)
            }
            Button { music.playPause() } label: {
                Image(systemName: music.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(CarTheme.primaryText)
            }
            Button { music.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 18))
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
        HStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.system(size: 22))
                .foregroundStyle(CarTheme.accent)
                .frame(width: 44, height: 44)
                .background(CarTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text("NAVIGATION")
                    .font(CarTheme.rounded(10, .semibold))
                    .foregroundStyle(CarTheme.accent)
                    .tracking(0.8)

                if nav.isNavigating {
                    Text(nav.destinationTitle)
                        .font(CarTheme.rounded(19, .semibold))
                        .foregroundStyle(CarTheme.primaryText)
                        .lineLimit(1)
                    Text(nav.routeSummary)
                        .font(CarTheme.rounded(15))
                        .foregroundStyle(CarTheme.secondaryText)
                        .lineLimit(1)
                } else {
                    quickNavButtons
                }
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(CarTheme.tertiaryText)
        }
        .padding(14)
        .tileBackground()
        .contentShape(Rectangle())
        .onTapGesture { router.navigate(to: .navigation) }
    }

    @ViewBuilder
    private var quickNavButtons: some View {
        HStack(spacing: 8) {
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
                .padding(.vertical, 6)
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
        .tileBackground()
        .contentShape(Rectangle())
        .onTapGesture { router.navigate(to: .messages) }
    }

    private func send(_ msg: QuickMessage, to contact: ContactRow) {
        guard let phone = contact.primaryPhone else { return }
        guard let url = URL(string: "sms:\(phone.digitsOnly)") else { return }
        UIApplication.shared.open(url)
    }
}