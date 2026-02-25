import Foundation
import SwiftUI
import Combine

enum AuthState {
    case checking
    case authenticated
    case unauthenticated
}

@MainActor
class AppViewModel: ObservableObject {

    @Published var authState: AuthState = .checking
    @Published var userTitle: String = ""

    init() {
        Task {
            await checkAuthOnLaunch()
        }
    }

    func checkAuthOnLaunch() async {

        guard let token = KeychainService.shared.getToken() else {
            authState = .unauthenticated
            return
        }

        do {
            let user = try await UserService.shared.fetchCurrentUser(token: token)
            userTitle = user.title
            authState = .authenticated
        } catch {
            KeychainService.shared.deleteToken()
            authState = .unauthenticated
        }
    }

    func login(username: String, password: String) async throws {

        let response = try await AuthService.shared.login(
            username: username,
            password: password
        )

        KeychainService.shared.saveToken(response.access_token)

        let user = try await UserService.shared.fetchCurrentUser(
            token: response.access_token
        )

        userTitle = user.title
        authState = .authenticated
    }

    func logout() {
        KeychainService.shared.deleteToken()
        userTitle = ""
        authState = .unauthenticated
    }
}
