import SwiftUI

struct SplashView: View {

    var body: some View {
        VStack(spacing: 20) {

            ProgressView()
                .scaleEffect(1.5)

            Text("Проверка авторизации...")
                .font(.headline)
        }
        .frame(width: 400, height: 250)
    }
}
