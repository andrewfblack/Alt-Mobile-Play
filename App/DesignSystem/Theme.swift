import SwiftUI

enum CarTheme {
    static let background = Color(red: 0.035, green: 0.04, blue: 0.055)
    static let widget = Color(red: 0.10, green: 0.115, blue: 0.15)
    static let tile = Color(red: 0.13, green: 0.145, blue: 0.185)
    static let tilePressed = Color(red: 0.20, green: 0.22, blue: 0.27)
    static let field = Color(red: 0.16, green: 0.17, blue: 0.21)
    static let accent = Color(red: 0.19, green: 0.47, blue: 0.96)
    static let green = Color(red: 0.24, green: 0.78, blue: 0.44)
    static let orange = Color(red: 0.99, green: 0.62, blue: 0.22)
    static let red = Color(red: 0.92, green: 0.34, blue: 0.34)
    static let purple = Color(red: 0.66, green: 0.47, blue: 0.95)
    static let primaryText = Color.white.opacity(0.94)
    static let secondaryText = Color.white.opacity(0.6)
    static let tertiaryText = Color.white.opacity(0.38)

    static let palette: [Color] = [accent, red, green, purple, orange, secondaryText]

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct TileBackground: ViewModifier {
    var radius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(CarTheme.tile)
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                }
            )
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension View {
    func tileBackground(_ radius: CGFloat = 22) -> some View {
        modifier(TileBackground(radius: radius))
    }

    func topTitle(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(CarTheme.rounded(30, .bold))
                .foregroundStyle(CarTheme.primaryText)
            Spacer()
        }
    }
}

extension String {
    var digitsOnly: String {
        filter(\.isNumber)
    }
}

func formattedETA(seconds: TimeInterval) -> String {
    let minutes = Int((seconds / 60).rounded())
    if minutes < 60 { return "\(minutes) min" }
    let hours = minutes / 60
    let mins = minutes % 60
    return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
}

func formattedDistance(_ meters: Double) -> String {
    if meters > 1000 {
        return String(format: "%.1f mi", meters / 1609.344)
    }
    return String(format: "%.0f ft", meters / 0.3048)
}
