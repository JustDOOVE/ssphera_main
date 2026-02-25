import Foundation
import SwiftUI
import Combine

@MainActor
class WidgetDetailViewModel: ObservableObject {

    // MARK: - Сырой JSON виджета
    @Published var rawJson: String?

    // MARK: - Статусы
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Токен пользователя (если требуется авторизация)
    var token: String? {
        KeychainService.shared.getToken()
    }

    // MARK: - Загрузка данных виджета
    func fetchWidget(name: String) async {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "https://sbps.ru/api/desktop/widgets/query") else {
            errorMessage = "Некорректный URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Добавляем токен, если есть
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "name": name,
            "ignore_cache": false
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

            let (data, response) = try await URLSession.shared.data(for: request)

            // Логируем HTTP статус
            if let httpResp = response as? HTTPURLResponse {
                print("Status code for \(name): \(httpResp.statusCode)")
                if !(200...299).contains(httpResp.statusCode) {
                    print("Response headers: \(httpResp.allHeaderFields)")
                    print("Response body: \(String(data: data, encoding: .utf8) ?? "")")
                    errorMessage = "Сервер вернул код \(httpResp.statusCode)"
                    return
                }
            }

            // Преобразуем данные в строку
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON for \(name):\n\(jsonString)")
                self.rawJson = jsonString
            } else {
                errorMessage = "Не удалось прочитать данные как строку"
            }

        } catch {
            errorMessage = "Ошибка запроса: \(error.localizedDescription)"
            print("Widget fetch error: \(error)")
        }
    }
}
