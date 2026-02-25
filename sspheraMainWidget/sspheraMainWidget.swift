import WidgetKit
import SwiftUI

// MARK: - Entry

struct WorkhoursEntry: TimelineEntry {
    let date: Date
    let value: String
}


// MARK: - Provider

struct WorkhoursProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> WorkhoursEntry {
        WorkhoursEntry(date: Date(), value: "—")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WorkhoursEntry) -> Void) {
        Task {
            let value = await fetchWorkhours()
            completion(WorkhoursEntry(date: Date(), value: value))
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkhoursEntry>) -> Void) {
        Task {
            let value = await fetchWorkhours()
            
            let entry = WorkhoursEntry(date: Date(), value: value)
            
            // обновление каждые 30 минут
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
            
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}


// MARK: - Network

func fetchWorkhours() async -> String {
    
    guard let token = KeychainService.shared.getToken() else {
        return "?"
    }
    
    guard let url = URL(string: "https://sbps.ru/api/desktop/widgets/query") else {
        return "?"
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let body: [String: Any] = [
        "name": "RedmineSelfAverageWorkhoursWidget",
        "ignore_cache": false
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let value = jsonObject["value"] as? String {
            return value
        }
        
    } catch {
        print("Widget fetch error:", error)
    }
    
    return "?"
}


// MARK: - View

struct WorkhoursWidgetEntryView : View {
    var entry: WorkhoursProvider.Entry
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Средние трудочасы")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(entry.value)
                .font(.system(size: 44, weight: .bold))
        }
        .padding()
        .containerBackground(for: .widget) {
            // Здесь вы можете задать фон
            Color.clear // или любой другой цвет/вьюху
        }
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
