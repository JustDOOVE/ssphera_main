import Foundation

struct UserResponse: Codable {
    let id: Int
    let title: String
    let email: String
    let roles: [String]
    let real_user: String?
}
