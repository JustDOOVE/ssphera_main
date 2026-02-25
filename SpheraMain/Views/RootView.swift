import SwiftUI

struct RootView: View {
    
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject var widgetsViewModel = WidgetsViewModel()
    
    @State private var hoveredIndex: Int? = nil
    
    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
            
            content
                .frame(minWidth: 900, minHeight: 600)
        }
        .task {
            await widgetsViewModel.fetchWidgets()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 16) {
            
            if appViewModel.authState != .authenticated {
                
                Spacer()
                LoginView()
                    .environmentObject(appViewModel)
                    .frame(maxWidth: 400)
                Spacer()
                
            } else {
                
                Text("\(appViewModel.userTitle), добро пожаловать в рабочий стол Ssphera")
                    .font(.headline)
                
                Divider()
                
                VStack(spacing: 0) {
                    
                    // MARK: - Панель вкладок
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            
                            ForEach(Array(widgetsViewModel.openedTabs.enumerated()), id: \.offset) { index, widgetName in
                                tabView(widgetName: widgetName, index: index)
                            }
                            
                            if !widgetsViewModel.availableWidgets.isEmpty {
                                Menu {
                                    ForEach(widgetsViewModel.availableWidgets, id: \.name) { widget in
                                        Button(widget.title) {
                                            widgetsViewModel.openWidget(widget.name)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "plus")
                                        .padding(8)
                                        .background(Color.gray.opacity(0.15))
                                        .cornerRadius(6)
                                }
                                .menuStyle(BorderlessButtonMenuStyle())
                            }
                        }
                        .padding(6)
                        .background(Color.gray.opacity(0.08))
                    }
                    .frame(height: 44)
                    
                    Divider()
                    
                    // MARK: - Контент вкладки
                    if let selected = widgetsViewModel.selectedWidgetName,
                       let vm = widgetsViewModel.detailViewModels[selected] {
                        
                        WidgetDetailView(
                            widgetName: selected,
                            viewModel: vm
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 8)
                        
                    } else {
                        Text("Добавьте вкладку через +")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
    }
    
    private func tabView(widgetName: String, index: Int) -> some View {
        
        let isSelected = widgetsViewModel.selectedWidgetName == widgetName
        
        return HStack(spacing: 6) {
            
            Button {
                widgetsViewModel.selectedWidgetName = widgetName
            } label: {
                Text(widgetName)
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        isSelected
                        ? Color.blue.opacity(0.3)
                        : (hoveredIndex == index ? Color.gray.opacity(0.2) : Color.clear)
                    )
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                hoveredIndex = hovering ? index : nil
            }
            
            Button {
                widgetsViewModel.closeWidget(widgetName)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
    }
}
