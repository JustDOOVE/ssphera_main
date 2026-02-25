import Foundation
import SwiftUI
import Combine

@MainActor
class WidgetsViewModel: ObservableObject {
    
    @Published var allWidgets: [DesktopWidget] = []
    @Published var openedTabs: [String] = []
    @Published var selectedWidgetName: String? = nil
    
    // 🔥 отдельный ViewModel для каждой вкладки
    @Published var detailViewModels: [String: WidgetDetailViewModel] = [:]
    
    private let storageKey = "openedTabs"
    
    init() {
        loadTabs()
    }
    
    // MARK: - Загрузка списка виджетов
    func fetchWidgets() async {
        guard let url = URL(string: "https://sbps.ru/api/desktop/widgets") else { return }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            if let token = KeychainService.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode([DesktopWidget].self, from: data)
            allWidgets = decoded
            
        } catch {
            print("Ошибка загрузки виджетов:", error)
        }
    }
    
    var availableWidgets: [DesktopWidget] {
        allWidgets.filter { !openedTabs.contains($0.name) }
    }
    
    // MARK: - Открыть вкладку
    func openWidget(_ name: String) {
        if !openedTabs.contains(name) {
            openedTabs.append(name)
            
            let vm = WidgetDetailViewModel()
            detailViewModels[name] = vm
            
            Task {
                await vm.fetchWidget(name: name)
            }
            
            saveTabs()
        }
        
        selectedWidgetName = name
    }
    
    // MARK: - Закрыть вкладку
    func closeWidget(_ name: String) {
        openedTabs.removeAll { $0 == name }
        detailViewModels.removeValue(forKey: name)
        
        if selectedWidgetName == name {
            selectedWidgetName = openedTabs.last
        }
        
        saveTabs()
    }
    
    // MARK: - Persistence
    
    private func saveTabs() {
        UserDefaults.standard.set(openedTabs, forKey: storageKey)
    }
    
    private func loadTabs() {
        guard let saved = UserDefaults.standard.array(forKey: storageKey) as? [String] else {
            return
        }
        
        openedTabs = saved
        selectedWidgetName = saved.last
        
        for name in saved {
            let vm = WidgetDetailViewModel()
            detailViewModels[name] = vm
            
            Task {
                await vm.fetchWidget(name: name)
            }
        }
    }
}
