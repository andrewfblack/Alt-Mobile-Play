import ActivityKit
import Foundation

struct ReturnToAppActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var message: String
    }

    var appName: String
}
