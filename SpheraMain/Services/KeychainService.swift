import Foundation
import Security

class KeychainService {

    static let shared = KeychainService()
    
    private init() {}
    
    private let service = "spheraMain"
    private let account = "authToken"

    func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!

        // Удаляем старый токен если есть
        deleteToken()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        SecItemCopyMatching(query as CFDictionary, &item)

        if let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}
