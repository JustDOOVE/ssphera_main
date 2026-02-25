import Foundation
import SwiftUI
import Combine

@MainActor
class WidgetDetailViewModel: ObservableObject {

    @Published var rawJson: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var token: String? {
        KeychainService.shared.getToken()
    }

    // Обычная загрузка (с кешем)
    func fetchWidget(name: String) async {
        await fetchWidget(name: name, ignoreCache: false)
    }

    // Принудительное обновление
    func refreshWidget(name: String) async {
        await fetchWidget(name: name, ignoreCache: true)
    }

    // Общий метод
    private func fetchWidget(name: String, ignoreCache: Bool) async {

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let url = URL(string: "https://sbps.ru/api/desktop/widgets/query") else {
            errorMessage = "Некорректный URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "name": name,
            "ignore_cache": ignoreCache
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResp = response as? HTTPURLResponse {
                if !(200...299).contains(httpResp.statusCode) {
                    errorMessage = "Сервер вернул код \(httpResp.statusCode)"
                    return
                }
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                rawJson = jsonString
            } else {
                errorMessage = "Не удалось прочитать данные"
            }

        } catch {
            errorMessage = "Ошибка запроса: \(error.localizedDescription)"
        }
    }
}
