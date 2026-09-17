import SwiftUI
import UIKit

struct LeftControlBar: View {
    @Environment(AppRouter.self) private var router
    let onHome: () -> Void
    let onVolume: () -> Void

    @State private var now = Date()
    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    static let width: CGFloat = 116

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(now, style: .time)
                    .font(CarTheme.rounded(30, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                BarBattery()
            }
            .padding(.top, 12)

            Spacer(minLength: 0)

            VStack(spacing: 22) {
                Button(action: onVolume) {
                    barIcon("speaker.wave.2.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Volume")

                Button(action: onHome) {
                    barIcon(router.current == .home ? "square.grid.2x2.fill" : "house.fill")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(router.current == .home ? "Apps" : "Home")
            }
            .padding(.bottom, 16)
        }
        .frame(width: Self.width)
        .frame(maxHeight: .infinity)
        .background(CarTheme.background)
        .onReceive(clockTimer) { now = $0 }
    }

    private func barIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(CarTheme.primaryText)
            .frame(width: 56, height: 56)
            .background(Circle().fill(CarTheme.tile))
            .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
    }
}

private struct BarBattery: View {
    @State private var level: Float = UIDevice.current.batteryLevel
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: batteryIcon)
                .font(.system(size: 20, weight: .semibold))
            if level >= 0 {
                Text("\(Int((level * 100).rounded()))%")
                    .font(CarTheme.rounded(16, .medium))
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
