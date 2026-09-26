import CoreLocation
import Foundation
import MapKit
import Observation

struct WazeTrafficAlert: Decodable, Identifiable {
    let id: String
    let city: String?
    let type: String
    let street: String?
    let subtype: String?
    let location: WazeTrafficPoint
    let thumbsUp: Int?
    let reliability: Int?

    enum CodingKeys: String, CodingKey {
        case id, city, type, street, subtype, location, reliability
        case thumbsUp = "thumbs_up"
    }
}

struct WazeTrafficJam: Decodable, Identifiable {
    let id: String
    let city: String?
    let line: [WazeTrafficPoint]
    let level: Int
    let street: String?
    let lengthMeters: Double?
    let speedKilometersPerHour: Double?
    let delaySeconds: Double?

    enum CodingKeys: String, CodingKey {
        case id, city, line, level, street
        case lengthMeters = "length_m"
        case speedKilometersPerHour = "speed_kmh"
        case delaySeconds = "delay_seconds"
    }
}

struct WazeTrafficPoint: Decodable {
    let lat: Double
    let lng: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

enum WazeTrafficError: LocalizedError {
    case invalidResponse
    case server(Int, String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "WazeAPI returned an invalid response."
        case .server(let status, let message):
            message ?? "WazeAPI returned status \(status)."
        }
    }
}

@MainActor
@Observable
final class WazeTrafficService {
    static let shared = WazeTrafficService()

    private(set) var alerts: [WazeTrafficAlert] = []
    private(set) var jams: [WazeTrafficJam] = []
    private(set) var isLoading = false
    private(set) var lastUpdated: Date?
    private(set) var quotaRemaining: Int?
    var lastError: String?

    @ObservationIgnored private let settings = AppSettings.shared
    @ObservationIgnored private let session: URLSession
    @ObservationIgnored private var requestID = UUID()
    @ObservationIgnored private var loadedRouteKey: String?
    @ObservationIgnored private var blockedKeyHash: Int?

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.waitsForConnectivity = false
        session = URLSession(configuration: configuration)
    }

    var isConfigured: Bool {
        settings.wazeTrafficEnabled && !settings.wazeAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canAutomaticallyRefresh: Bool {
        blockedKeyHash != settings.wazeAPIKey.hashValue
    }

    func loadTraffic(for route: MKRoute) async {
        guard isConfigured else {
            clear()
            return
        }
        guard canAutomaticallyRefresh else { return }

        let currentRequestID = UUID()
        requestID = currentRequestID
        isLoading = true
        lastError = nil

        do {
            let coordinates = Self.sampledCoordinates(route.polyline.coordinates, limit: 120)
            guard coordinates.count >= 2 else { throw WazeTrafficError.invalidResponse }
            let routeKey = Self.routeKey(for: coordinates)
            if loadedRouteKey != routeKey {
                alerts = []
                jams = []
                lastUpdated = nil
                loadedRouteKey = routeKey
            }

            var request = URLRequest(url: URL(string: "https://api.wazeapi.com/v1/route/danger")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(settings.wazeAPIKey.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "X-API-Key")
            request.setValue(settings.wazeCountry, forHTTPHeaderField: "X-Country")
            request.httpBody = try JSONEncoder().encode(RouteTrafficRequest(
                geojson: .init(
                    type: "LineString",
                    coordinates: coordinates.map { [$0.latitude, $0.longitude] }
                )
            ))

            let (data, response) = try await session.data(for: request)
            guard requestID == currentRequestID else { return }
            guard let http = response as? HTTPURLResponse else {
                throw WazeTrafficError.invalidResponse
            }
            quotaRemaining = http.value(forHTTPHeaderField: "X-Quota-Remaining").flatMap(Int.init)
            guard (200..<300).contains(http.statusCode) else {
                let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data).error
                if http.statusCode == 401 || http.statusCode == 403 {
                    blockedKeyHash = settings.wazeAPIKey.hashValue
                }
                throw WazeTrafficError.server(http.statusCode, apiError?.message)
            }

            let result = try JSONDecoder().decode(RouteTrafficResponse.self, from: data)
            alerts = result.alerts ?? []
            jams = result.jams ?? []
            lastUpdated = Date()
        } catch {
            guard requestID == currentRequestID else { return }
            alerts = []
            jams = []
            lastUpdated = nil
            lastError = error.localizedDescription
        }

        if requestID == currentRequestID { isLoading = false }
    }

    func clear() {
        requestID = UUID()
        alerts = []
        jams = []
        isLoading = false
        lastUpdated = nil
        quotaRemaining = nil
        lastError = nil
        loadedRouteKey = nil
    }

    private static func sampledCoordinates(
        _ coordinates: [CLLocationCoordinate2D],
        limit: Int
    ) -> [CLLocationCoordinate2D] {
        guard coordinates.count > limit else { return coordinates }
        let stride = Double(coordinates.count - 1) / Double(limit - 1)
        return (0..<limit).map { coordinates[Int((Double($0) * stride).rounded())] }
    }

    private static func routeKey(for coordinates: [CLLocationCoordinate2D]) -> String {
        guard let first = coordinates.first, let last = coordinates.last else { return "empty" }
        let middle = coordinates[coordinates.count / 2]
        return "\(coordinates.count)-\(first.latitude)-\(first.longitude)-\(middle.latitude)-\(middle.longitude)-\(last.latitude)-\(last.longitude)"
    }
}

private struct RouteTrafficRequest: Encodable {
    let geojson: GeoJSONLineString
}

private struct GeoJSONLineString: Encodable {
    let type: String
    let coordinates: [[Double]]
}

private struct RouteTrafficResponse: Decodable {
    let alerts: [WazeTrafficAlert]?
    let jams: [WazeTrafficJam]?
}

private struct APIErrorResponse: Decodable {
    let error: APIErrorBody
}

private struct APIErrorBody: Decodable {
    let code: String
    let message: String
}
