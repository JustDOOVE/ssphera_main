import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Entry

struct WorkhoursEntry: TimelineEntry {
    let date: Date
    let value: String
    let numericValue: Double?
}



// MARK: - Provider

struct WorkhoursProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> WorkhoursEntry {
        WorkhoursEntry(date: Date(), value: "7.2", numericValue: 7.2)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WorkhoursEntry) -> Void) {
        Task {
            let result = await fetchWorkhours(ignoreCache: true)
            completion(
                WorkhoursEntry(
                    date: Date(),
                    value: result.string,
                    numericValue: result.number
                )
            )
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkhoursEntry>) -> Void) {
        Task {
            let result = await fetchWorkhours(ignoreCache: true)
            
            let entry = WorkhoursEntry(
                date: Date(),
                value: result.string,
                numericValue: result.number
            )
            
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            
            completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
        }
    }
}


// MARK: - Network

func fetchWorkhours(ignoreCache: Bool) async -> (string: String, number: Double?) {
    
    guard let token = KeychainService.shared.getToken(),
          let url = URL(string: "https://sbps.ru/api/desktop/widgets/query") else {
        return ("?", nil)
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let body: [String: Any] = [
        "name": "RedmineSelfAverageWorkhoursWidget",
        "ignore_cache": ignoreCache
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let valueString = json["value"] as? String,
           let number = Double(valueString.replacingOccurrences(of: ",", with: ".")) {
            return (valueString, number)
        }
        
    } catch {
        print("Widget error:", error)
    }
    
    return ("?", nil)
}


// MARK: - AppIntent (ручное обновление)

struct RefreshWorkhoursIntent: AppIntent {
    static var title: LocalizedStringResource = "Обновить данные"
    
    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}


// MARK: - View

struct WorkhoursWidgetEntryView : View {
    var entry: WorkhoursEntry
    
    var body: some View {
        VStack(spacing: 8) {
            
            HStack {
                Text("Средние трудочасы")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(intent: RefreshWorkhoursIntent()) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
            
            Text(entry.value)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(colorForValue(entry.numericValue))
            
            Text("Обновлено \(entry.date.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
    
    func colorForValue(_ value: Double?) -> Color {
        guard let value else { return .secondary }
        return value >= 6.0 ? .green : .red
    }
}


// MARK: - Widget

struct WorkhoursWidget: Widget {
    
    let kind: String = "WorkhoursWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkhoursProvider()) { entry in
            WorkhoursWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Средние трудочасы")
        .description("Показывает среднее количество трудочасов.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}


// MARK: - Bundle

@main
struct WorkhoursWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkhoursWidget()
        EmployeeWorkhoursWidget()
    }
}
