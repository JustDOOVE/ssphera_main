import SwiftUI

struct WidgetsListView: View {
    @StateObject var viewModel = WidgetsViewModel()

    var body: some View {
        VStack {
            if viewModel.allWidgets.isEmpty {
                Text("Загрузка виджетов...")
                    .padding()
            } else {
                List(viewModel.allWidgets) { widget in
                    Text(widget.title)
                        .font(.headline)
                }
            }
        }
        .task {
            await viewModel.fetchWidgets()
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}
