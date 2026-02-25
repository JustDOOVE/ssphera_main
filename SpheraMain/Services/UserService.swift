import Foundation

class UserService {

    static let shared = UserService()
    private init() {}

    func fetchCurrentUser(token: String) async throws -> UserResponse {

        guard let url = URL(string: "https://sbps.ru/api/auth/me") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // 🔴 Если токен протух
        if httpResponse.statusCode == 401 {
            throw AuthError.unauthorized
        }

        let decoded = try JSONDecoder().decode(UserResponse.self, from: data)
        return decoded
    }
}

enum AuthError: Error {
    case unauthorized
}
