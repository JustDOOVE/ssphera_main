import SwiftUI

struct MainView: View {

    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        VStack(spacing: 20) {

            Text("\(appVM.userTitle), добро пожаловать в рабочий стол Ssphera")
                .font(.title)

            Button("Выход из профиля") {
                appVM.logout()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 500, height: 300)
    }
}
