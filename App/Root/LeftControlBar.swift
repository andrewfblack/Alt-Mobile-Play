import SwiftUI
import UIKit

struct LeftControlBar: View {
    @Environment(AppRouter.self) private var router
    let width: CGFloat
    let onHome: () -> Void
    let onVolume: () -> Void

    @State private var now = Date()
    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: width * 0.13) {
                Text(now, style: .time)
                    .font(CarTheme.rounded(width * 0.27, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                BarBattery(width: width)
            }
            .padding(.top, width * 0.11)

            Spacer(minLength: 0)

            VStack(spacing: width * 0.20) {
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
            .padding(.bottom, width * 0.15)
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
        .background(CarTheme.background)
        .onReceive(clockTimer) { now = $0 }
    }

    private func barIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: width * 0.19, weight: .semibold))
            .foregroundStyle(CarTheme.primaryText)
            .frame(width: width * 0.52, height: width * 0.52)
            .background(Circle().fill(CarTheme.tile))
            .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
    }
}

private struct BarBattery: View {
    let width: CGFloat
    @State private var level: Float = UIDevice.current.batteryLevel
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: width * 0.04) {
            Image(systemName: batteryIcon)
                .font(.system(size: width * 0.16, weight: .semibold))
            if level >= 0 {
                Text("\(Int((level * 100).rounded()))%")
                    .font(CarTheme.rounded(width * 0.135, .medium))
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