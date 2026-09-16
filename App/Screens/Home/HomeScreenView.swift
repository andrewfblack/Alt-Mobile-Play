import SwiftUI
import CoreLocation
import MapKit

struct HomeScreenView: View {
    @Environment(AppRouter.self) private var router
    @State private var now = Date()
    @State private var settings = AppSettings.shared
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 18)

            GeometryReader { geo in
                let widthBudget = geo.size.width * 0.44
                let heightBudget = (2 * geo.size.height - 14) / 3 - 6
                let gridWidth = max(200, min(380, min(widthBudget, heightBudget)))
                HStack(alignment: .top, spacing: 20) {
                    // Left: widgets
                    VStack(spacing: 16) {
                        NowPlayingWidget()
                        NavigationWidget()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    // Right: app grid
                    AppsGrid()
                        .frame(width: gridWidth)
                        .frame(maxHeight: .infinity, alignment: .topTrailing)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onReceive(timer) { now = $0 }
        .onAppear { settings.apply() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(now, style: .time)
                    .font(CarTheme.rounded(52))
                    .foregroundStyle(CarTheme.primaryText)
                    .monospacedDigit()

                Text(now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(CarTheme.rounded(20, .medium))
                    .foregroundStyle(CarTheme.secondaryText)
            }
            Spacer()
            BatteryIndicator()
        }
    }
}

// MARK: - Battery

private struct BatteryIndicator: View {
    @State private var level: Float = UIDevice.current.batteryLevel

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: batteryIcon)
                .font(.system(size: 22, weight: .semibold))
            if level >= 0 {
                Text("\(Int((level * 100).rounded()))%")
                    .font(CarTheme.rounded(22, .medium))
                    .monospacedDigit()
            }
        }
        .foregroundStyle(CarTheme.secondaryText)
        .onReceive(timer) { _ in level = UIDevice.current.batteryLevel }
    }

    private var batteryIcon: String {
        switch level {
        case ..<0.1: "battery.0percent"
        case ..<0.25: "battery.25percent"
        case ..<0.5: "battery.50percent"
        case ..<0.75: "battery.75percent"
        default: "battery.100percent"
        }
    }
}

// MARK: - Apps Grid

private struct AppsGrid: View {
    @Environment(AppRouter.self) private var router
    @State private var settings = AppSettings.shared
    @State private var page = 0

    private let perPage = 6

    private var pages: [[HomeApp]] {
        let apps = settings.homeApps
        guard !apps.isEmpty else { return [[]] }
        return stride(from: 0, to: apps.count, by: perPage).map {
            Array(apps[$0 ..< min($0 + perPage, apps.count)])
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        grid(pages[index]).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                if pages.count > 1 {
                    HStack {
                        pageArrow("chevron.left", enabled: page > 0) { page -= 1 }
                        Spacer()
                        pageArrow("chevron.right", enabled: page < pages.count - 1) { page += 1 }
                    }
                }
            }

            if pages.count > 1 {
                HStack(spacing: 6) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(index == page ? CarTheme.primaryText : CarTheme.tertiaryText)
                            .frame(width: 7, height: 7)
                    }
                }
            }
        }
        .onChange(of: pages.count) { _, count in
            if page >= count { page = max(0, count - 1) }
        }
    }

    private func grid(_ apps: [HomeApp]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            ForEach(apps) { app in
                Button { tap(app) } label: {
                    VStack(spacing: 12) {
                        Image(systemName: app.icon)
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(app.color)
                        Text(app.title)
                            .font(CarTheme.rounded(18, .medium))
                            .foregroundStyle(CarTheme.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())
                .aspectRatio(1.0, contentMode: .fill)
            }
        }
    }

    private func pageArrow(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(enabled ? CarTheme.primaryText : CarTheme.tertiaryText.opacity(0.4))
                .frame(width: 34, height: 34)
                .background(Circle().fill(CarTheme.field.opacity(0.85)))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func tap(_ app: HomeApp) {
        if let raw = app.screen, let screen = AppScreen(rawValue: raw) {
            router.navigate(to: screen)
        } else {
            app.open()
        }
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
