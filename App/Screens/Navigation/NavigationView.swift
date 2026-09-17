import SwiftUI
import MapKit

struct NavigationView: View {
    @Environment(AppRouter.self) private var router
    @State private var nav = NavigationState.shared
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var searchText = ""
    @State private var results: [MKMapItem] = []
    @State private var showResults = false
    @State private var isSearching = false
    @State private var searchNotice: String?
    @State private var mapType: CarMapType = .standard
    @FocusState private var searchFocused: Bool

    var body: some View {
        GeometryReader { geo in
        ZStack(alignment: .topLeading) {
            map
                .ignoresSafeArea()

            searchBar
                .padding(.top, 14)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)

            if showResults {
                resultsList
                    .frame(width: min(340, geo.size.width - 32))
                    .padding(.leading, 16)
                    .padding(.top, 56)
            } else if isSearching || searchNotice != nil {
                searchStatus
                    .frame(width: min(340, geo.size.width - 32))
                    .padding(.leading, 16)
                    .padding(.top, 56)
            }

            if nav.target != nil && !showResults {
                VStack {
                    Spacer()
                    bottomBanner
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .frame(maxWidth: .infinity)
                }
            }

            mapControls
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .onAppear {
            nav.requestLocationPermission()
            if let target = nav.target, nav.route == nil {
                Task { await nav.calculateRoute() }
                zoom(to: target.coordinate)
            }
        }
        .task(id: nav.isNavigating) {
            if nav.isNavigating, let route = nav.route {
                position = .region(MKCoordinateRegion(route.polyline.boundingMapRect))
            }
        }
        }
    }

    // MARK: - Map

    @ViewBuilder
    private var map: some View {
        Map(position: $position, interactionModes: [.pan, .zoom, .rotate]) {
            UserAnnotation()

            if let target = nav.target {
                Annotation(target.title, coordinate: target.coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(CarTheme.red)
                        .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                }
            }

            if let route = nav.route {
                MapPolyline(coordinates: route.polyline.coordinates)
                    .stroke(CarTheme.accent, style: StrokeStyle(
                        lineWidth: 6, lineCap: .round, lineJoin: .round
                    ))
            }
        }
        .mapStyle(mapStyle)
    }

    private var mapStyle: MapStyle {
        switch mapType {
        case .standard:  return .standard(elevation: .realistic)
        case .hybrid:    return .hybrid(elevation: .realistic)
        case .satellite: return .imagery(elevation: .realistic)
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(CarTheme.tertiaryText)
                .font(.system(size: 18))
            TextField("Search destination", text: $searchText)
                .font(CarTheme.rounded(20, .medium))
                .foregroundStyle(CarTheme.primaryText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { Task { await runSearch() } }
            if !searchText.isEmpty {
                Button { searchText = ""; showResults = false; searchNotice = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(CarTheme.tertiaryText)
                }
                .buttonStyle(.plain)
            }
            Button { Task { await runSearch() } } label: {
                Image(systemName: "arrow.forward.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(canSearch ? CarTheme.accent : CarTheme.tertiaryText)
            }
            .buttonStyle(.plain)
            .disabled(!canSearch)
        }
        .padding(14)
        .background(CarTheme.field.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(searchFocused ? CarTheme.accent : Color.clear, lineWidth: 2)
        )
    }

    private var canSearch: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var searchStatus: some View {
        HStack(spacing: 12) {
            if isSearching {
                ProgressView().tint(CarTheme.primaryText)
            } else {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(CarTheme.tertiaryText)
            }
            Text(isSearching ? "Searching…" : (searchNotice ?? ""))
                .font(CarTheme.rounded(16, .medium))
                .foregroundStyle(CarTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(CarTheme.field.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Results

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(Array(results.enumerated()), id: \.offset) { _, item in
                    Button {
                        selectResult(item)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name ?? "Unknown")
                                .font(CarTheme.rounded(18, .semibold))
                                .foregroundStyle(CarTheme.primaryText)
                                .lineLimit(1)
                            Text(item.placemark.title ?? "")
                                .font(CarTheme.rounded(14))
                                .foregroundStyle(CarTheme.secondaryText)
                                .lineLimit(2)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().background(CarTheme.tertiaryText).padding(.horizontal, 14)
                }
            }
        }
        .background(CarTheme.field.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Bottom Banner

    private var bottomBanner: some View {
        Group {
            if nav.isNavigating { turnBanner }
            else if let target = nav.target { startBanner(target) }
        }
    }

    private func startBanner(_ target: NavigationTarget) -> some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Route to")
                    .font(CarTheme.rounded(14))
                    .foregroundStyle(CarTheme.secondaryText)
                Text(target.title)
                    .font(CarTheme.rounded(26, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
                    .lineLimit(1)
                if !nav.routeSummary.isEmpty {
                    Text(nav.routeSummary)
                        .font(CarTheme.rounded(18))
                        .foregroundStyle(CarTheme.secondaryText)
                } else if nav.routingError {
                    Text("Couldn't calculate a route to here")
                        .font(CarTheme.rounded(18, .medium))
                        .foregroundStyle(CarTheme.red)
                } else {
                    Text("Calculating route…")
                        .font(CarTheme.rounded(18))
                        .foregroundStyle(CarTheme.secondaryText)
                }
            }
            Spacer()
            Button { nav.startNavigation() } label: {
                Text("Go")
                    .font(CarTheme.rounded(24, .bold))
                    .foregroundStyle(.white)
                    .frame(width: 88, height: 64)
                    .background(CarTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(nav.route == nil)
        }
        .padding(20)
        .tileBackground()
    }

    private var turnBanner: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(nav.nextInstruction)
                    .font(CarTheme.rounded(24, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
                    .lineLimit(2)
                if !nav.upcomingInstruction.isEmpty {
                    Text("Then: \(nav.upcomingInstruction)")
                        .font(CarTheme.rounded(16))
                        .foregroundStyle(CarTheme.secondaryText)
                        .lineLimit(1)
                }
                Text(nav.routeSummary)
                    .font(CarTheme.rounded(16))
                    .foregroundStyle(CarTheme.secondaryText)
            }
            Spacer()
            VStack(spacing: 12) {
                Button { nav.setVoice(!nav.voiceEnabled) } label: {
                    Image(systemName: nav.voiceEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(CarTheme.primaryText)
                }
                Button { nav.endNavigation() } label: {
                    Text("End")
                        .font(CarTheme.rounded(18, .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 40)
                        .background(CarTheme.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .tileBackground()
    }

    // MARK: - Map Controls

    private var mapControls: some View {
        VStack(spacing: 14) {
            Button {
                if let r = position.region { zoom(to: r.center) }
                else if let loc = nav.target?.coordinate { zoom(to: loc) }
            } label: {
                controlIcon("location.fill")
            }

            Menu {
                ForEach(CarMapType.allCases) { type in
                    Button { mapType = type } label: {
                        Label(type.title, systemImage: type.icon)
                    }
                }
            } label: {
                controlIcon("map")
            }

            Button { zoom(by: 0.5) } label: {
                controlIcon("plus.magnifyingglass")
            }
            Button { zoom(by: 2.0) } label: {
                controlIcon("minus.magnifyingglass")
            }
        }
    }

    private func controlIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(CarTheme.primaryText)
            .frame(width: 44, height: 44)
            .background(CarTheme.field.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Helpers

    private func runSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        searchFocused = false
        isSearching = true
        searchNotice = nil
        showResults = false
        results = []
        defer { isSearching = false }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        do {
            let resp = try await MKLocalSearch(request: request).start()
            results = resp.mapItems
            if results.isEmpty {
                searchNotice = "No results for “\(query)”. Try a town, address, or landmark."
            } else {
                showResults = true
            }
        } catch {
            results = []
            searchNotice = "Search failed. Check your connection and try again."
        }
    }

    private func selectResult(_ item: MKMapItem) {
        nav.setTarget(item)
        searchText = ""
        showResults = false
        searchNotice = nil
        Task { await nav.calculateRoute(); zoom(to: item.placemark.coordinate) }
    }

    private func zoom(to coord: CLLocationCoordinate2D?) {
        guard let coord else { return }
        let region = MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        )
        position = .region(region)
    }

    private func zoom(by factor: Double) {
        if let r = position.region {
            position = .region(MKCoordinateRegion(
                center: r.center,
                span: MKCoordinateSpan(
                    latitudeDelta: max(0.005, r.span.latitudeDelta * factor),
                    longitudeDelta: max(0.005, r.span.longitudeDelta * factor)
                )
            ))
        }
    }
}

// MARK: - Helpers

enum CarMapType: String, CaseIterable, Identifiable {
    case standard, hybrid, satellite
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .standard: "map"
        case .hybrid: "square.split.2x2"
        case .satellite: "globe"
        }
    }
}
