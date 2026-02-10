import Foundation
import Security

/// Secure storage for the API key using the iOS Keychain.
/// The API key is app-specific (not user-specific).
final class SecureStorage {

    static let shared = SecureStorage()

    private let service = "com.onlinepicketline.opl"
    private let apiKeyAccount = "api_key"

    private init() {}

    var apiKey: String? {
        get { read(account: apiKeyAccount) }
        set {
            if let value = newValue {
                save(account: apiKeyAccount, value: value)
            } else {
                delete(account: apiKeyAccount)
            }
        }
    }

    var hasApiKey: Bool { apiKey != nil }

    // MARK: - Keychain Operations

    private func save(account: String, value: String) {
        delete(account: account) // Remove existing

        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
