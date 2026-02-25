import SwiftUI

@MainActor
struct WidgetDetailView: View {
    
    let widgetName: String
    @ObservedObject var viewModel: WidgetDetailViewModel
    
    @State private var isRotating = false
    @State private var statusMessage: String?
    @State private var isSuccess: Bool = true
    @State private var showStatus: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            
            // 🔄 Кнопка обновления
            Button {
                Task {
                    await refresh()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .animation(
                        isRotating
                        ? .linear(duration: 1).repeatForever(autoreverses: false)
                        : .default,
                        value: isRotating
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .help("Обновить данные")
            
            
            // 🟢🔴 Статус обновления
            if let message = statusMessage, showStatus {
                Text(message)
                    .font(.caption)
                    .foregroundColor(isSuccess ? .green : .red)
                    .transition(.opacity)
            }
            
            
            // 📊 Контент
            if viewModel.isLoading && viewModel.rawJson == nil {
                ProgressView("Загрузка данных...")
                
            } else if let error = viewModel.errorMessage {
                Text("Ошибка: \(error)")
                    .foregroundColor(.red)
                
            } else if let rawJson = viewModel.rawJson {
                
                if widgetName == "RedmineSelfAverageWorkhoursWidget" {
                    renderAverageWorkhours(from: rawJson)
                    
                } else if widgetName == "GiteaTeamPullRequestsWidget" {
                    renderGiteaPullRequests(from: rawJson)
                    
                } else {
                    renderJsonTable(from: rawJson)
                }
                
            } else {
                Text("Нет данных")
            }
        }
        .padding()
        .onChange(of: viewModel.isLoading) { _, newValue in
            isRotating = newValue
        }
    }
    
    // MARK: - Универсальная таблица
    func renderJsonTable(from jsonString: String) -> some View {
        guard
            let data = jsonString.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let headers = jsonObject["headers"] as? [String],
            let rows = jsonObject["rows"] as? [[String]]
        else {
            return AnyView(Text("Невозможно прочитать JSON").foregroundColor(.red))
        }
        
        let columnWidth: CGFloat = 200
        
        return AnyView(
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 6) {
                    
                    HStack(spacing: 4) {
                        ForEach(headers, id: \.self) { header in
                            Text(header)
                                .bold()
                                .frame(width: columnWidth, alignment: .center)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    
                    Divider()
                    
                    ForEach(rows, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(row, id: \.self) { col in
                                renderMarkdownOrText(col)
                                    .frame(width: columnWidth, alignment: .center)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                        Divider()
                    }
                }
                .padding(.vertical, 4)
            }
        )
    }
    
    // MARK: - Average Workhours
    func renderAverageWorkhours(from jsonString: String) -> some View {
        guard
            let data = jsonString.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let value = jsonObject["value"] as? String
        else {
            return AnyView(Text("Невозможно прочитать JSON").foregroundColor(.red))
        }
        
        return AnyView(
            VStack {
                Text("Среднее значение трудочасов:")
                    .font(.headline)
                Text(value)
                    .font(.system(size: 48, weight: .bold))
                    .padding(.top, 8)
            }
        )
    }
    
    // MARK: - Gitea Pull Requests
    func renderGiteaPullRequests(from jsonString: String) -> some View {
        guard
            let data = jsonString.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let headers = jsonObject["headers"] as? [String],
            let rows = jsonObject["rows"] as? [[String]]
        else {
            return AnyView(Text("Невозможно прочитать JSON").foregroundColor(.red))
        }
        
        let columnWidth: CGFloat = 200
        
        return AnyView(
            ScrollView([.horizontal, .vertical]) {
                VStack(spacing: 6) {
                    
                    HStack(spacing: 4) {
                        ForEach(headers, id: \.self) { header in
                            Text(header)
                                .bold()
                                .frame(width: columnWidth, alignment: .center)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    
                    Divider()
                    
                    ForEach(rows, id: \.self) { row in
                        HStack(spacing: 4) {
                            
                            if let userCol = row.first {
                                renderAvatarOnly(from: userCol)
                                    .frame(width: columnWidth, alignment: .center)
                            }
                            
                            let middleCols = row.dropFirst().dropLast()
                            ForEach(middleCols, id: \.self) { col in
                                renderMarkdownOrText(col)
                                    .frame(width: columnWidth, alignment: .center)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            
                            if let reviewersCol = row.last, !reviewersCol.isEmpty {
                                HStack(spacing: 4) {
                                    let avatars = reviewersCol.components(separatedBy: "],")
                                    ForEach(avatars, id: \.self) { reviewer in
                                        renderAvatarOnly(from: reviewer)
                                            .frame(width: columnWidth, alignment: .center)
                                    }
                                }
                            } else {
                                Spacer().frame(width: columnWidth)
                            }
                        }
                        Divider()
                    }
                }
                .padding(.vertical, 4)
            }
        )
    }
    
    // MARK: - Markdown/Text
    func renderMarkdownOrText(_ markdown: String) -> some View {
        
        if markdown.contains("!["), markdown.contains("avatars") {
            return AnyView(renderAvatarOnly(from: markdown))
        }
        
        if let match = try? NSRegularExpression(pattern: "\\[(.*?)\\]\\((.*?)\\)")
            .firstMatch(in: markdown, range: NSRange(location: 0, length: markdown.utf16.count)),
           let textRange = Range(match.range(at: 1), in: markdown),
           let urlRange = Range(match.range(at: 2), in: markdown),
           let url = URL(string: String(markdown[urlRange])) {
            
            let text = String(markdown[textRange])
            
            return AnyView(
                Link(destination: url) {
                    Text(text)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            )
        }
        
        return AnyView(
            Text(markdown)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .center)
        )
    }
    
    // MARK: - Avatar
    func renderAvatarOnly(from markdown: String) -> some View {
        guard
            let avatarMatch = try? NSRegularExpression(pattern: "\\!\\[.*?\\]\\((.*?)\\)")
                .firstMatch(in: markdown, range: NSRange(location: 0, length: markdown.utf16.count)),
            let avatarRange = Range(avatarMatch.range(at: 1), in: markdown),
            let avatarURL = URL(string: String(markdown[avatarRange]))
        else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            AsyncImage(url: avatarURL) { image in
                image.resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 24, height: 24)
            .clipShape(Circle())
        )
    }
}


// MARK: - Refresh logic
private extension WidgetDetailView {
    
    func refresh() async {
        await viewModel.refreshWidget(name: widgetName)
        
        withAnimation {
            if viewModel.errorMessage == nil {
                statusMessage = "Данные обновлены"
                isSuccess = true
            } else {
                statusMessage = "Не смогли получить актуальные данные для этого виджета"
                isSuccess = false
            }
            showStatus = true
        }
        
        // плавное исчезновение через 3 секунды
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        
        withAnimation {
            showStatus = false
        }
    }
}
