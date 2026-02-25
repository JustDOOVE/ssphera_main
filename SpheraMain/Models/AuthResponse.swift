import Foundation

struct AuthResponse: Codable {
    let access_token: String
    let token_type: String?
}

