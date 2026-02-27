import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Entry

struct EmployeesEntry: TimelineEntry {
    let date: Date
    let rows: [[String]]
}

// MARK: - Provider

struct EmployeesProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> EmployeesEntry {
        EmployeesEntry(date: Date(), rows: [])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (EmployeesEntry) -> Void) {
        Task {
            let rows = await fetchEmployees(ignoreCache: true)
            completion(EmployeesEntry(date: Date(), rows: rows))
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<EmployeesEntry>) -> Void) {
        Task {
            let rows = await fetchEmployees(ignoreCache: true)
            let entry = EmployeesEntry(date: Date(), rows: rows)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }
}

// MARK: - Network

func fetchEmployees(ignoreCache: Bool) async -> [[String]] {
    
    guard let token = KeychainService.shared.getToken(),
          let url = URL(string: "https://sbps.ru/api/desktop/widgets/query") else {
        return []
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let body: [String: Any] = [
        "name": "RedmineAverageWorkhoursWidget",
        "ignore_cache": ignoreCache
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let rows = json["rows"] as? [[String]] {
            return rows
        }
        
    } catch {
        print("Employees widget error:", error)
    }
    
    return []
}

// MARK: - Intent

struct RefreshEmployeesIntent: AppIntent {
    static var title: LocalizedStringResource = "Обновить список"
    
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - View

struct EmployeesWidgetEntryView: View {
    
    var entry: EmployeesEntry
    
    var body: some View {
        VStack(spacing: 6) {
            
            // Заголовки
            HStack {
                Text("ФИО")
                    .frame(maxWidth: .infinity)
                
                Text("Часы")
                    .frame(maxWidth: .infinity)
            }
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            
            Divider()
            
            if sortedRows.isEmpty {
                Text("Нет данных")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedRows.prefix(10).indices, id: \.self) { index in
                    
                    let row = sortedRows[index]
                    
                    let name = row.count > 0 ? row[0] : "-"
                    let value = row.count > 2 ? row[2] : "-"
                    let number = Double(value.replacingOccurrences(of: ",", with: "."))
                    
                    HStack {
                        Text(name)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                        
                        Text(value)
                            .foregroundStyle(colorForValue(number))
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    .font(.system(size: 14))
                }
            }
            
            Spacer()
            
            Divider()
            
            // Нижняя панель
            HStack {
                Text("Обновлено \(entry.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(intent: RefreshEmployeesIntent()) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
    
    // MARK: - Sorting
    
    var sortedRows: [[String]] {
        entry.rows.sorted { lhs, rhs in
            let leftValue = lhs.count > 2 ? Double(lhs[2].replacingOccurrences(of: ",", with: ".")) ?? 0 : 0
            let rightValue = rhs.count > 2 ? Double(rhs[2].replacingOccurrences(of: ",", with: ".")) ?? 0 : 0
            return leftValue > rightValue
        }
    }
    
    func colorForValue(_ value: Double?) -> Color {
        guard let value else { return .secondary }
        return value >= 6.0 ? .green : .red
    }
}

// MARK: - Widget

struct EmployeeWorkhoursWidget: Widget {
    
    let kind: String = "EmployeeWorkhoursWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EmployeesProvider()) { entry in
            EmployeesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Трудозатраты сотрудников")
        .description("Показывает сотрудников и их средние трудочасы.")
        .supportedFamilies([.systemLarge])
    }
}
