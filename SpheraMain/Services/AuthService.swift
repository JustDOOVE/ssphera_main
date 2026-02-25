import Foundation

class AuthService {

    static let shared = AuthService()
    
    private init() {}

    func login(username: String, password: String) async throws -> AuthResponse {
        
        guard let url = URL(string: "https://sbps.ru/api/auth/token") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // ВАЖНО: сервер ждёт form-urlencoded
        request.setValue("application/x-www-form-urlencoded;charset=UTF-8",
                         forHTTPHeaderField: "Content-Type")
        
        // Формируем body как в браузере
        let bodyString = "username=\(username)&password=\(password)"
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
        return decoded
    }
}
