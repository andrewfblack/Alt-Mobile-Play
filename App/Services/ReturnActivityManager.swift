import ActivityKit
import Foundation

@MainActor
final class ReturnActivityManager {
    static let shared = ReturnActivityManager()

    private init() {}

    func start() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard Activity<ReturnToAppActivityAttributes>.activities.isEmpty else { return }

        let attributes = ReturnToAppActivityAttributes(appName: "AltPlay")
        let content = ActivityContent(
            state: ReturnToAppActivityAttributes.ContentState(message: "Tap to return to AltPlay"),
            staleDate: nil
        )

        do {
            _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            // Live Activities are optional; ignore failures.
        }
    }

    func endAll() {
        Task {
            for activity in Activity<ReturnToAppActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
