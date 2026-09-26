import MapKit
import CoreLocation
import AVFoundation
import Observation

final class NavigationTarget: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
    let title: String
    let subtitle: String

    var coordinate: CLLocationCoordinate2D { mapItem.placemark.coordinate }

    init(mapItem: MKMapItem, title: String? = nil, subtitle: String? = nil) {
        self.mapItem = mapItem
        self.title = title ?? mapItem.name ?? "Destination"
        self.subtitle = subtitle ?? (mapItem.placemark.title ?? "")
    }
}

@Observable
final class NavigationState: NSObject, CLLocationManagerDelegate {
    static let shared = NavigationState()

    var target: NavigationTarget?
    var route: MKRoute?
    var isNavigating = false
    var currentStep = 0
    var voiceEnabled: Bool
    var locationAuthorized = false
    var routingError = false
    var currentCoordinate: CLLocationCoordinate2D?
    var travelHeading: CLLocationDirection = 0
    var isRerouting = false

    @ObservationIgnored private let locationManager = CLLocationManager()
    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private let settings = AppSettings.shared
    @ObservationIgnored private var lastProcessedLocationAt: Date?
    @ObservationIgnored private var offRouteFixCount = 0
    @ObservationIgnored private var lastOffRouteFixAt: Date?
    @ObservationIgnored private var lastRerouteAt: Date?
    @ObservationIgnored private var routeRequestID = UUID()
    @ObservationIgnored private var activeRerouteID: UUID?

    var destinationTitle: String { target?.title ?? "Destination" }

    var nextInstruction: String {
        guard let route, currentStep < route.steps.count else { return "" }
        return route.steps[currentStep].instructions
    }

    var upcomingInstruction: String {
        let idx = currentStep + 1
        guard let route else { return "Continue" }
        guard idx < route.steps.count else { return "Arrive at \(destinationTitle)" }
        return route.steps[idx].instructions
    }

    var routeSummary: String {
        guard let route else { return "" }
        return "\(formattedETA(seconds: route.expectedTravelTime))  \(formattedDistance(route.distance))"
    }

    override init() {
        voiceEnabled = UserDefaults.standard.object(forKey: "voiceGuidance") as? Bool ?? true
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }

    func requestLocationPermission() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        updateAuthStatus()
    }

    func setTarget(_ item: MKMapItem, title: String? = nil, subtitle: String? = nil) {
        target = NavigationTarget(mapItem: item, title: title, subtitle: subtitle)
        route = nil
        isNavigating = false
        currentStep = 0
        routingError = false
        isRerouting = false
        offRouteFixCount = 0
        lastOffRouteFixAt = nil
        routeRequestID = UUID()
        activeRerouteID = nil
    }

    @MainActor
    func calculateRoute() async {
        _ = await calculateRoute(from: nil, isReroute: false)
    }

    @discardableResult
    @MainActor
    private func calculateRoute(
        from coordinate: CLLocationCoordinate2D?,
        isReroute: Bool
    ) async -> Bool {
        guard let target else { return false }
        let requestID = UUID()
        routeRequestID = requestID
        if !isReroute { routingError = false }
        let request = MKDirections.Request()
        if let coordinate {
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        } else {
            request.source = MKMapItem.forCurrentLocation()
        }
        request.destination = target.mapItem
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        do {
            let response = try await MKDirections(request: request).calculate()
            guard routeRequestID == requestID else { return false }
            if isReroute {
                guard settings.automaticRerouting, isNavigating, isRerouting else { return false }
            }
            if let r = response.routes.first {
                self.route = r
                currentStep = 0
                routingError = false
                return true
            } else {
                if !isReroute { routingError = true }
            }
        } catch {
            guard routeRequestID == requestID else { return false }
            if !isReroute { routingError = true }
        }
        return false
    }

    func startNavigation() {
        guard let route else { return }
        isNavigating = true
        currentStep = 0
        offRouteFixCount = 0
        lastOffRouteFixAt = nil
        lastRerouteAt = nil
        locationManager.startUpdatingLocation()
        speak(route.steps.first?.instructions)
    }

    func endNavigation() {
        isNavigating = false
        route = nil
        currentStep = 0
        isRerouting = false
        offRouteFixCount = 0
        lastOffRouteFixAt = nil
        routeRequestID = UUID()
        activeRerouteID = nil
        synthesizer.stopSpeaking(at: .immediate)
        locationManager.stopUpdatingLocation()
    }

    func cancelAll() {
        endNavigation()
        target = nil
        routingError = false
    }

    func setVoice(_ enabled: Bool) {
        voiceEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "voiceGuidance")
        if !enabled { synthesizer.stopSpeaking(at: .immediate) }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in updateAuthStatus() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let loc = locations.last else { return }
            if let lastProcessedLocationAt,
               loc.timestamp <= lastProcessedLocationAt { return }
            lastProcessedLocationAt = loc.timestamp
            currentCoordinate = loc.coordinate
            if loc.course >= 0 {
                travelHeading = loc.course
            }

            guard isNavigating, let route else { return }

            evaluateRerouting(for: loc, route: route)

            if currentStep < route.steps.count {
                let end = stepEndpoint(route.steps[currentStep])
                let dist = loc.distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
                if dist < 50 { advance() }
            }
        }
    }

    // MARK: - Private

    private func updateAuthStatus() {
        let s = locationManager.authorizationStatus
        locationAuthorized = s == .authorizedWhenInUse || s == .authorizedAlways
    }

    private func advance() {
        guard let route else { return }
        let next = currentStep + 1
        if next < route.steps.count {
            currentStep = next
            speak(route.steps[next].instructions)
        } else {
            speak("You have arrived at \(destinationTitle)")
            isNavigating = false
            locationManager.stopUpdatingLocation()
        }
    }

    private func evaluateRerouting(for location: CLLocation, route: MKRoute) {
        guard settings.automaticRerouting, !isRerouting else {
            offRouteFixCount = 0
            lastOffRouteFixAt = nil
            return
        }
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 65,
              abs(location.timestamp.timeIntervalSinceNow) < 10,
              location.speed >= 1 else {
            offRouteFixCount = 0
            lastOffRouteFixAt = nil
            return
        }

        if let target,
           location.distance(from: CLLocation(
               latitude: target.coordinate.latitude,
               longitude: target.coordinate.longitude
            )) < 60 {
            offRouteFixCount = 0
            lastOffRouteFixAt = nil
            return
        }

        let corridor = max(45, location.horizontalAccuracy * 2)
        let remainingSteps = route.steps.dropFirst(min(currentStep, route.steps.count))
        let routeDistance = remainingSteps
            .map { $0.polyline.distance(to: location.coordinate) }
            .min() ?? route.polyline.distance(to: location.coordinate)
        if routeDistance > corridor {
            if let lastOffRouteFixAt {
                let interval = location.timestamp.timeIntervalSince(lastOffRouteFixAt)
                guard interval > 0 else { return }
                if interval > 8 { offRouteFixCount = 0 }
            }
            offRouteFixCount += 1
            lastOffRouteFixAt = location.timestamp
        } else {
            offRouteFixCount = 0
            lastOffRouteFixAt = nil
        }

        guard offRouteFixCount >= 3 else { return }
        if let lastRerouteAt, Date().timeIntervalSince(lastRerouteAt) < 30 { return }

        offRouteFixCount = 0
        lastOffRouteFixAt = nil
        lastRerouteAt = Date()
        isRerouting = true
        let rerouteID = UUID()
        activeRerouteID = rerouteID
        let coordinate = location.coordinate
        Task { @MainActor [weak self] in
            guard let self else { return }
            let updated = await calculateRoute(from: coordinate, isReroute: true)
            guard activeRerouteID == rerouteID else { return }
            activeRerouteID = nil
            isRerouting = false
            if updated {
                let instruction = nextInstruction
                speak(instruction.isEmpty ? "Route updated" : "Route updated. \(instruction)")
            }
        }
    }

    @MainActor
    func setAutomaticRerouting(_ enabled: Bool) {
        guard !enabled else { return }
        if isRerouting {
            routeRequestID = UUID()
            activeRerouteID = nil
            isRerouting = false
        }
        offRouteFixCount = 0
        lastOffRouteFixAt = nil
    }

    private func speak(_ text: String?) {
        guard voiceEnabled, let text, !text.isEmpty else { return }
        synthesizer.stopSpeaking(at: .word)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52
        synthesizer.speak(utterance)
    }

    private func stepEndpoint(_ step: MKRoute.Step) -> CLLocationCoordinate2D {
        let poly = step.polyline
        guard poly.pointCount > 0 else { return poly.coordinate }
        let pts = poly.points()
        let last = pts[poly.pointCount - 1]
        return last.coordinate
    }
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D]()
        let pts = points()
        for i in 0..<pointCount { coords.append(pts[i].coordinate) }
        return coords
    }

    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        guard pointCount > 0 else { return .infinity }
        let target = MKMapPoint(coordinate)
        let points = points()
        if pointCount == 1 {
            return target.distance(to: points[0])
        }

        var minimumMapPoints = Double.infinity
        for index in 0..<(pointCount - 1) {
            let start = points[index]
            let end = points[index + 1]
            let dx = end.x - start.x
            let dy = end.y - start.y
            let lengthSquared = dx * dx + dy * dy
            let fraction: Double
            if lengthSquared == 0 {
                fraction = 0
            } else {
                fraction = max(0, min(1,
                    ((target.x - start.x) * dx + (target.y - start.y) * dy) / lengthSquared
                ))
            }
            let nearestX = start.x + fraction * dx
            let nearestY = start.y + fraction * dy
            minimumMapPoints = min(minimumMapPoints, hypot(target.x - nearestX, target.y - nearestY))
        }
        return minimumMapPoints * MKMetersPerMapPointAtLatitude(coordinate.latitude)
    }
}
