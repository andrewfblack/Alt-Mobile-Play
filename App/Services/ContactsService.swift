import Contacts
import ContactsUI
import Observation

struct ContactRow: Identifiable {
    let id: String
    let displayName: String
    let phones: [String]
    let addresses: [String]
    let organization: String

    var primaryPhone: String? { phones.first }
    var primaryAddress: String? { addresses.first }
}

@Observable
final class ContactsService {
    static let shared = ContactsService()

    var authStatus: CNAuthorizationStatus = .notDetermined
    var contacts: [ContactRow] = []
    var settled = false

    private let store = CNContactStore()

    private let sampleContacts: [ContactRow] = [
        ContactRow(
            id: "sample-home",
            displayName: "Home",
            phones: ["(555) 100-1000"],
            addresses: ["1 Main Street, Springfield, IL"],
            organization: ""
        ),
        ContactRow(
            id: "sample-work",
            displayName: "Work",
            phones: ["(555) 200-2000"],
            addresses: ["100 Business Park, Chicago, IL"],
            organization: "Acme Inc"
        ),
        ContactRow(
            id: "sample-mom",
            displayName: "Mom",
            phones: ["(555) 300-3000"],
            addresses: [],
            organization: ""
        ),
    ]

    func requestAccessAndLoad() async {
        authStatus = CNContactStore.authorizationStatus(for: .contacts)
        if authStatus == .notDetermined {
            do {
                let granted = try await store.requestAccess(for: .contacts)
                authStatus = granted ? .authorized : .denied
            } catch {
                authStatus = .denied
            }
        }
        if authStatus == .authorized {
            loadContacts()
        } else {
            contacts = sampleContacts
        }
        settled = true
    }

    private func loadContacts() {
        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor,
            CNContactViewController.descriptorForRequiredKeys()
        ]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var rows: [ContactRow] = []

        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let name = [contact.givenName, contact.familyName]
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespaces)

                guard !name.isEmpty else { return }

                rows.append(ContactRow(
                    id: contact.identifier,
                    displayName: name,
                    phones: contact.phoneNumbers.map(\.value.stringValue),
                    addresses: contact.postalAddresses.map {
                        CNPostalAddressFormatter.string(from: $0.value, style: .mailingAddress)
                    },
                    organization: contact.organizationName
                ))
            }
        } catch {
            // Fall back to empty
        }

        contacts = rows.isEmpty ? sampleContacts : rows
    }

    func homeAddress() -> String? {
        contacts.first(where: { $0.displayName.lowercased().contains("home") })?.primaryAddress
    }

    func workAddress() -> String? {
        contacts.first(where: { $0.displayName.lowercased().contains("work") })?.primaryAddress
    }
}
