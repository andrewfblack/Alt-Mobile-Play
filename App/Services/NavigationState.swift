import MapKit
import CoreLocation
import AVFoundation
import Observation

@MainActor
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

@MainActor
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

    @ObservationIgnored private let locationManager = CLLocationManager()
    @ObservationIgnored private let synthesizer = AVSpeechSynthesizer()

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
    }

    func calculateRoute() async {
        guard let target else { return }
        routingError = false
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = target.mapItem
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        do {
            let response = try await MKDirections(request: request).calculate()
            if let r = response.routes.first {
                self.route = r
            } else {
                routingError = true
            }
        } catch {
            routingError = true
        }
    }

    func startNavigation() {
        guard let route else { return }
        isNavigating = true
        currentStep = 0
        locationManager.startUpdatingLocation()
        speak(route.steps.first?.instructions)
    }

    func endNavigation() {
        isNavigating = false
        route = nil
        currentStep = 0
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

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in updateAuthStatus() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard isNavigating, let route, let loc = locations.last,
                  currentStep < route.steps.count else { return }
            let end = stepEndpoint(route.steps[currentStep])
            let dist = loc.distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude))
            if dist < 50 { advance() }
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
}
