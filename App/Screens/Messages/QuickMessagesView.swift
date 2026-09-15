import SwiftUI

private struct QuickMessage: Identifiable {
    let id = UUID()
    let text: String
    let icon: String
}

private let quickMessages: [QuickMessage] = [
    QuickMessage(text: "On my way!", icon: "car.fill"),
    QuickMessage(text: "Running late", icon: "clock.fill"),
    QuickMessage(text: "Call me when you can", icon: "phone.fill"),
    QuickMessage(text: "Home safe", icon: "house.fill"),
    QuickMessage(text: "On my way home", icon: "arrow.triangle.turn.up.right.diamond.fill"),
    QuickMessage(text: "Just left", icon: "figure.walk"),
    QuickMessage(text: "At the store", icon: "bag.fill"),
    QuickMessage(text: "In a meeting", icon: "person.2.fill"),
]

struct QuickMessagesView: View {
    @Environment(AppRouter.self) private var router
    @State private var contacts = ContactsService.shared
    @State private var selectedContact: ContactRow?
    @State private var showSent = false

    var body: some View {
        VStack(spacing: 0) {
            topTitle("Messages")
                .padding(.horizontal, 24)
                .padding(.top, 16)

            // Recipient picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Send to")
                    .font(CarTheme.rounded(14, .medium))
                    .foregroundStyle(CarTheme.secondaryText)
                    .padding(.leading, 4)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(contacts.contacts) { contact in
                            Button {
                                selectedContact = contact
                            } label: {
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedContact?.id == contact.id ? CarTheme.accent : CarTheme.accent.opacity(0.2))
                                        Text(String(contact.displayName.prefix(1)))
                                            .font(CarTheme.rounded(16, .bold))
                                            .foregroundStyle(selectedContact?.id == contact.id ? .white : CarTheme.accent)
                                    }
                                    .frame(width: 32, height: 32)
                                    Text(contact.displayName)
                                        .font(CarTheme.rounded(16, .medium))
                                        .foregroundStyle(CarTheme.primaryText)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(CarTheme.accent.opacity(selectedContact?.id == contact.id ? 0.15 : 0.06))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            if showSent {
                sentConfirmation
                    .padding(.top, 16)
            }

            // Message grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    ForEach(quickMessages) { msg in
                        Button {
                            send(msg)
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: msg.icon)
                                    .font(.system(size: 30))
                                    .foregroundStyle(CarTheme.accent)
                                Text(msg.text)
                                    .font(CarTheme.rounded(18, .medium))
                                    .foregroundStyle(CarTheme.primaryText)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .padding(14)
                            .tileBackground()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(24)
            }
        }
        .onAppear {
            if selectedContact == nil, !contacts.contacts.isEmpty {
                selectedContact = contacts.contacts.first
            }
        }
    }

    private var sentConfirmation: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(CarTheme.green)
            Text("Opening Messages...")
                .font(CarTheme.rounded(18, .medium))
                .foregroundStyle(CarTheme.primaryText)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(CarTheme.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 24)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) { showSent = false }
        }
    }

    private func send(_ msg: QuickMessage) {
        guard let contact = selectedContact, let phone = contact.primaryPhone else { return }
        let number = phone.digitsOnly
        guard let url = URL(string: "sms:\(number)") else { return }
        UIApplication.shared.open(url)
        showSent = true
    }
}
