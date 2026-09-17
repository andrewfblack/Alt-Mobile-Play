import SwiftUI

struct QuickMessage: Identifiable {
    let id = UUID()
    let text: String
    let icon: String
}

enum QuickMessageCatalog {
    static let all: [QuickMessage] = [
        QuickMessage(text: "On my way!", icon: "car.fill"),
        QuickMessage(text: "Running late", icon: "clock.fill"),
        QuickMessage(text: "Call me when you can", icon: "phone.fill"),
        QuickMessage(text: "Home safe", icon: "house.fill"),
        QuickMessage(text: "On my way home", icon: "arrow.triangle.turn.up.right.diamond.fill"),
        QuickMessage(text: "Just left", icon: "figure.walk"),
        QuickMessage(text: "At the store", icon: "bag.fill"),
        QuickMessage(text: "In a meeting", icon: "person.2.fill"),
    ]
}