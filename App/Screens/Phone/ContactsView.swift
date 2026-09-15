import SwiftUI
import CoreLocation
import MapKit

struct ContactsView: View {
    @Environment(AppRouter.self) private var router
    @State private var contacts = ContactsService.shared
    @State private var query = ""
    @State private var isLoading = false

    private var filtered: [ContactRow] {
        guard !query.isEmpty else { return contacts.contacts }
        let q = query.lowercased()
        let digits = query.digitsOnly
        return contacts.contacts.filter {
            let nameMatch = $0.displayName.lowercased().contains(q) ||
                            $0.organization.lowercased().contains(q)
            let phoneMatch = !digits.isEmpty && $0.phones.contains { $0.contains(digits) }
            return nameMatch || phoneMatch || $0.displayName.lowercased().contains(digits)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topTitle("Contacts")
                .padding(.horizontal, 24)
                .padding(.top, 16)

            // Search
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(CarTheme.tertiaryText)
                TextField("Search", text: $query)
                    .font(CarTheme.rounded(18, .medium))
                    .foregroundStyle(CarTheme.primaryText)
                    .autocorrectionDisabled()
            }
            .padding(12)
            .background(CarTheme.field)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { contact in
                            ContactRowView(contact: contact, router: router)
                            if contact.id != filtered.last?.id {
                                Divider()
                                    .background(CarTheme.tertiaryText.opacity(0.3))
                                    .padding(.leading, 24)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .onAppear {
            Task {
                isLoading = true
                await contacts.requestAccessAndLoad()
                isLoading = false
            }
        }
    }
}

private struct ContactRowView: View {
    let contact: ContactRow
    let router: AppRouter
    @State private var isGeocoding = false

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(CarTheme.accent.opacity(0.2))
                Text(String(contact.displayName.prefix(1)))
                    .font(CarTheme.rounded(22, .bold))
                    .foregroundStyle(CarTheme.accent)
            }
            .frame(width: 48, height: 48)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.displayName)
                    .font(CarTheme.rounded(20, .semibold))
                    .foregroundStyle(CarTheme.primaryText)
                if let phone = contact.primaryPhone {
                    Text(phone)
                        .font(CarTheme.rounded(16))
                        .foregroundStyle(CarTheme.secondaryText)
                } else if !contact.organization.isEmpty {
                    Text(contact.organization)
                        .font(CarTheme.rounded(16))
                        .foregroundStyle(CarTheme.secondaryText)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 14) {
                if let phone = contact.primaryPhone {
                    Button { call(phone) } label: {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(CarTheme.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                if let address = contact.primaryAddress {
                    Button {
                        Task { await directions(to: address, name: contact.displayName) }
                    } label: {
                        if isGeocoding {
                            ProgressView()
                                .frame(width: 44, height: 44)
                        } else {
                            Image(systemName: "map.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(CarTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 14)
    }

    private func call(_ number: String) {
        let digits = number.digitsOnly
        guard let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
    }

    private func directions(to address: String, name: String) async {
        isGeocoding = true
        defer { isGeocoding = false }
        do {
            let p = try await CLGeocoder().geocodeAddressString(address).first
            guard let loc = p?.location else { return }
            let item = MKMapItem(placemark: MKPlacemark(coordinate: loc.coordinate))
            item.name = name
            NavigationState.shared.setTarget(item, title: name, subtitle: address)
            router.navigate(to: .navigation)
        } catch {}
    }
}
