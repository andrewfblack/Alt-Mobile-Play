import ActivityKit
import WidgetKit
import SwiftUI

struct ReturnToAppActivityWidget: Widget {
    private let openURL = URL(string: "altplay://")!

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReturnToAppActivityAttributes.self) { context in
            ReturnToAppLockScreenView(message: context.state.message)
                .widgetURL(openURL)
                .activityBackgroundTint(Color(red: 0.05, green: 0.06, blue: 0.09))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.blue)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("AltPlay")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Tap to return to AltPlay")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: "car.fill")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } minimal: {
                Image(systemName: "car.fill")
                    .foregroundStyle(.blue)
            }
            .keylineTint(.blue)
            .widgetURL(openURL)
        }
    }
}

private struct ReturnToAppLockScreenView: View {
    let message: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "car.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(Color.blue.opacity(0.3), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("AltPlay")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(16)
    }
}
