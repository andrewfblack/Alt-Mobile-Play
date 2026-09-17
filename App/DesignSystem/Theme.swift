import SwiftUI
import UIKit
import Observation

// MARK: - Color model

struct RGBColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double

    init(_ red: Double, _ green: Double, _ blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(_ color: Color) {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        red = Double(r)
        green = Double(g)
        blue = Double(b)
    }

    var color: Color { Color(red: red, green: green, blue: blue) }

    var luminance: Double { 0.299 * red + 0.587 * green + 0.114 * blue }

    var hexString: String {
        String(format: "#%02X%02X%02X", Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
    }

    init(from decoder: Decoder) throws {
        if let hex = try? decoder.singleValueContainer().decode(String.self) {
            self.init(hex)
            return
        }
        if let arr = try? decoder.singleValueContainer().decode([Double].self), arr.count >= 3 {
            red = arr[0]
            green = arr[1]
            blue = arr[2]
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        red = try c.decodeIfPresent(Double.self, forKey: .red) ?? 0
        green = try c.decodeIfPresent(Double.self, forKey: .green) ?? 0
        blue = try c.decodeIfPresent(Double.self, forKey: .blue) ?? 0
    }

    init(_ hex: String) {
        var value: UInt64 = 0
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        Scanner(string: cleaned).scanHexInt64(&value)
        if cleaned.count >= 6 {
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
        } else {
            red = 0; green = 0; blue = 0
        }
    }
}

// MARK: - Theme model

struct Theme: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var background: RGBColor
    var widget: RGBColor
    var tile: RGBColor
    var tilePressed: RGBColor
    var field: RGBColor
    var accent: RGBColor
    var green: RGBColor
    var orange: RGBColor
    var red: RGBColor
    var purple: RGBColor
    var primaryText: RGBColor
    var secondaryText: RGBColor
    var tertiaryText: RGBColor

    enum CodingKeys: String, CodingKey {
        case id, name, background, widget, tile, tilePressed, field, accent
        case green, orange, red, purple, primaryText, secondaryText, tertiaryText
    }

    init(
        id: String, name: String,
        background: RGBColor, widget: RGBColor, tile: RGBColor,
        tilePressed: RGBColor, field: RGBColor, accent: RGBColor,
        green: RGBColor, orange: RGBColor, red: RGBColor, purple: RGBColor,
        primaryText: RGBColor, secondaryText: RGBColor, tertiaryText: RGBColor
    ) {
        self.id = id
        self.name = name
        self.background = background
        self.widget = widget
        self.tile = tile
        self.tilePressed = tilePressed
        self.field = field
        self.accent = accent
        self.green = green
        self.orange = orange
        self.red = red
        self.purple = purple
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.tertiaryText = tertiaryText
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = Theme.dark
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? "custom-\(UUID().uuidString)"
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Custom"
        background = try c.decodeIfPresent(RGBColor.self, forKey: .background) ?? fallback.background
        widget = try c.decodeIfPresent(RGBColor.self, forKey: .widget) ?? fallback.widget
        tile = try c.decodeIfPresent(RGBColor.self, forKey: .tile) ?? fallback.tile
        tilePressed = try c.decodeIfPresent(RGBColor.self, forKey: .tilePressed) ?? fallback.tilePressed
        field = try c.decodeIfPresent(RGBColor.self, forKey: .field) ?? fallback.field
        accent = try c.decodeIfPresent(RGBColor.self, forKey: .accent) ?? fallback.accent
        green = try c.decodeIfPresent(RGBColor.self, forKey: .green) ?? fallback.green
        orange = try c.decodeIfPresent(RGBColor.self, forKey: .orange) ?? fallback.orange
        red = try c.decodeIfPresent(RGBColor.self, forKey: .red) ?? fallback.red
        purple = try c.decodeIfPresent(RGBColor.self, forKey: .purple) ?? fallback.purple
        primaryText = try c.decodeIfPresent(RGBColor.self, forKey: .primaryText) ?? fallback.primaryText
        secondaryText = try c.decodeIfPresent(RGBColor.self, forKey: .secondaryText) ?? fallback.secondaryText
        tertiaryText = try c.decodeIfPresent(RGBColor.self, forKey: .tertiaryText) ?? fallback.tertiaryText
    }

    static let dark = Theme(
        id: "dark", name: "Dark",
        background: RGBColor(0.035, 0.04, 0.055),
        widget: RGBColor(0.10, 0.115, 0.15),
        tile: RGBColor(0.13, 0.145, 0.185),
        tilePressed: RGBColor(0.20, 0.22, 0.27),
        field: RGBColor(0.16, 0.17, 0.21),
        accent: RGBColor(0.19, 0.47, 0.96),
        green: RGBColor(0.24, 0.78, 0.44),
        orange: RGBColor(0.99, 0.62, 0.22),
        red: RGBColor(0.92, 0.34, 0.34),
        purple: RGBColor(0.66, 0.47, 0.95),
        primaryText: RGBColor(0.94, 0.94, 0.94),
        secondaryText: RGBColor(0.62, 0.63, 0.66),
        tertiaryText: RGBColor(0.42, 0.43, 0.47)
    )

    static let light = Theme(
        id: "light", name: "Light",
        background: RGBColor(0.93, 0.94, 0.95),
        widget: RGBColor(0.88, 0.89, 0.92),
        tile: RGBColor(0.99, 0.995, 1.0),
        tilePressed: RGBColor(0.85, 0.87, 0.91),
        field: RGBColor(0.80, 0.82, 0.86),
        accent: RGBColor(0.0, 0.34, 0.78),
        green: RGBColor(0.10, 0.64, 0.35),
        orange: RGBColor(0.90, 0.50, 0.05),
        red: RGBColor(0.85, 0.22, 0.22),
        purple: RGBColor(0.55, 0.36, 0.90),
        primaryText: RGBColor(0.12, 0.13, 0.16),
        secondaryText: RGBColor(0.38, 0.40, 0.45),
        tertiaryText: RGBColor(0.55, 0.56, 0.62)
    )
}

// MARK: - Theme manager

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    static let builtins: [Theme] = [.dark, .light]

    private(set) var customThemes: [Theme] = []

    var current: Theme {
        didSet { UserDefaults.standard.set(current.id, forKey: "themeID") }
    }

    var allThemes: [Theme] { Self.builtins + customThemes }

    var scheme: ColorScheme {
        current.background.luminance > 0.5 ? .light : .dark
    }

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("customThemes.json")
    }

    private init() {
        customThemes = Self.loadCustomThemes()
        let savedID = UserDefaults.standard.string(forKey: "themeID")
        if let theme = allThemes.first(where: { $0.id == savedID }) {
            current = theme
        } else {
            current = .dark
        }
    }

    func upsert(_ theme: Theme) {
        if let idx = customThemes.firstIndex(where: { $0.id == theme.id }) {
            customThemes[idx] = theme
        } else {
            customThemes.append(theme)
        }
        saveCustomThemes()
        current = theme
    }

    func delete(_ theme: Theme) {
        customThemes.removeAll { $0.id == theme.id }
        if current.id == theme.id {
            current = .dark
        }
        saveCustomThemes()
    }

    func reloadFromFile() {
        customThemes = Self.loadCustomThemes()
        if let savedID = UserDefaults.standard.string(forKey: "themeID"),
           let theme = allThemes.first(where: { $0.id == savedID }) {
            current = theme
        }
    }

    private func saveCustomThemes() {
        if let data = try? JSONEncoder().encode(customThemes) {
            try? data.write(to: Self.fileURL)
        }
    }

    private static func loadCustomThemes() -> [Theme] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Theme].self, from: data)) ?? []
    }
}

// MARK: - Car theme facade

enum CarTheme {
    static var background: Color { ThemeManager.shared.current.background.color }
    static var widget: Color { ThemeManager.shared.current.widget.color }
    static var tile: Color { ThemeManager.shared.current.tile.color }
    static var tilePressed: Color { ThemeManager.shared.current.tilePressed.color }
    static var field: Color { ThemeManager.shared.current.field.color }
    static var accent: Color { ThemeManager.shared.current.accent.color }
    static var green: Color { ThemeManager.shared.current.green.color }
    static var orange: Color { ThemeManager.shared.current.orange.color }
    static var red: Color { ThemeManager.shared.current.red.color }
    static var purple: Color { ThemeManager.shared.current.purple.color }
    static var primaryText: Color { ThemeManager.shared.current.primaryText.color }
    static var secondaryText: Color { ThemeManager.shared.current.secondaryText.color }
    static var tertiaryText: Color { ThemeManager.shared.current.tertiaryText.color }

    static var palette: [Color] { [accent, red, green, purple, orange, secondaryText] }

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
                        .strokeBorder(CarTheme.primaryText.opacity(0.08), lineWidth: 1)
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