import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("Войдите в систему").font(.title)

            TextField("Имя пользователя", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)

            SecureField("Пароль", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 250)

            if let error = errorMessage {
                Text(error).foregroundColor(.red).font(.caption)
            }

            Button(action: {
                Task {
                    isLoading = true
                    do {
                        try await appViewModel.login(username: username, password: password)
                        errorMessage = nil
                    } catch {
                        errorMessage = "Неверный логин или пароль"
                    }
                    isLoading = false
                }
            }) {
                if isLoading { ProgressView() }
                else { Text("Войти") }
            }
        }
        .padding()
    }
}
