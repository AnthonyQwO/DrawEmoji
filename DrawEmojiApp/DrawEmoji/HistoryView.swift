import SwiftUI
import Foundation
import SwiftData

// MARK: - Data Models
struct HistoryResponse: Codable {
    let status: String
    let total: Int  // 新增 total 字段
    let history: [HistoryItem]
}

struct HistoryItem: Codable, Identifiable {
    let historyId: Int
    let imageBase64: String
    let emoji: String
    let timestamp: String
    let userName: String
    
    var id: Int { historyId }
    
    enum CodingKeys: String, CodingKey {
        case historyId = "history_id"
        case imageBase64 = "image_base64"
        case emoji
        case timestamp
        case userName = "user_name"
    }
}

// MARK: - Request Model
struct HistoryRequest: Codable {
    let offset: Int
    let limit: Int
}

// MARK: - API Service
class HistoryService: ObservableObject {
    @Published var historyItems: [HistoryItem] = []
    @Published var totalCount: Int = 0  // 新增總數量
    @Published var isLoading = false
    @Published var errorMessage: String?
        
    private var settings: [AppSettings] = []
        
    var baseURL: String {
        print(settings.first?.appURL)
        return settings.first?.appURL ?? appURL
    }
    
    // 更新設定的方法
    func updateSettings(_ newSettings: [AppSettings]) {
        self.settings = newSettings
        print("update")
        print(settings.first?.appURL)
        // 通知 UI baseURL 已改變
        objectWillChange.send()
    }

    func fetchHistory(offset: Int = 0, limit: Int = 20) {
        guard let url = URL(string: "\(baseURL)/history_all") else {
            errorMessage = "無效的 URL"
            return
        }
        
        print("history url ", url)
        
        isLoading = true
        errorMessage = nil
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"  // 改為 POST 請求
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = HistoryRequest(offset: offset, limit: limit)
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
        } catch {
            errorMessage = "請求參數編碼錯誤: \(error.localizedDescription)"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "網路錯誤: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "沒有收到資料"
                    return
                }
                
                do {
                    let historyResponse = try JSONDecoder().decode(HistoryResponse.self, from: data)
                    
                    if historyResponse.status == "ok" {
                        self?.historyItems = historyResponse.history
                        self?.totalCount = historyResponse.total  // 設定總數量
                    } else {
                        self?.errorMessage = "API 返回錯誤狀態"
                    }
                } catch {
                    self?.errorMessage = "資料解析錯誤: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // 新增：載入更多資料（分頁功能）
    func loadMoreHistory() {
        let currentOffset = historyItems.count
        guard currentOffset < totalCount else { return }
        
        guard let url = URL(string: "\(baseURL)/history_all") else {
            errorMessage = "無效的 URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = HistoryRequest(offset: currentOffset, limit: 20)
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
        } catch {
            errorMessage = "請求參數編碼錯誤: \(error.localizedDescription)"
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "網路錯誤: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "沒有收到資料"
                    return
                }
                
                do {
                    let historyResponse = try JSONDecoder().decode(HistoryResponse.self, from: data)
                    
                    if historyResponse.status == "ok" {
                        self?.historyItems.append(contentsOf: historyResponse.history)
                        self?.totalCount = historyResponse.total
                    } else {
                        self?.errorMessage = "API 返回錯誤狀態"
                    }
                } catch {
                    self?.errorMessage = "資料解析錯誤: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// MARK: - Views
struct HistoryView: View {
    @StateObject private var historyService = HistoryService()
    let onCancel: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    @State private var showingSettings = false
    
    var currentURL: String {
        settings.first?.appURL ?? appURL
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer(minLength: 10)
                if historyService.isLoading && historyService.historyItems.isEmpty {
                    ProgressView("載入中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = historyService.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("發生錯誤")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button("重試") {
                            historyService.fetchHistory()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if historyService.historyItems.isEmpty {
                    VStack {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("暫無歷史記錄")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(historyService.historyItems) { item in
                                HistoryGridItem(item: item)
                            }
                            
                            // 分頁載入更多的觸發區域
                            if hasMoreData {
                                ProgressView()
                                    .frame(height: 50)
                                    .onAppear {
                                        historyService.loadMoreHistory()
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    .refreshable {
                        historyService.fetchHistory()
                    }
                }

                // Bottom Control Buttons
                HStack {
                    // 顯示載入狀態和資料統計
                    VStack(alignment: .leading, spacing: 4) {
                        if historyService.totalCount > 0 {
                            Text("已載入 \(historyService.historyItems.count) / \(historyService.totalCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if historyService.isLoading && !historyService.historyItems.isEmpty {
                            Text("載入中...")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    Button("取消") {
                        onCancel()
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("歷史記錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        historyService.fetchHistory()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(historyService.isLoading)
                }
            }
        }
        .onAppear {
            historyService.updateSettings(settings)
            if historyService.historyItems.isEmpty {
                historyService.fetchHistory()
            }
        }
        .onChange(of: settings) { _, newSettings in
            historyService.updateSettings(newSettings)
        }
    }
    
    // 計算是否還有更多資料可以載入
    private var hasMoreData: Bool {
        return historyService.historyItems.count < historyService.totalCount
    }
    
}

struct HistoryGridItem: View {
    let item: HistoryItem
    @State private var showImageViewer = false
    
    var body: some View {
        VStack(spacing: 6) { // 減少內部間距
            // 圖片區域 - 使用固定高度防止重疊
            AsyncImageView(base64String: item.imageBase64)
                .frame(width: 160, height: 130) // 固定圖片高度，防止過大
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    showImageViewer = true
                }
                .overlay(
                    // 放大圖示提示
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                        .offset(x: 65, y: -55) // 右上角位置
                        .opacity(0.8)
                )

            
            // 資訊區域 - 更緊湊的佈局
            VStack(alignment: .leading, spacing: 2) {
                Text(item.emoji)
                    .padding(4)
                    .lineLimit(2)
                    .textSelection(.enabled)

                Text("ID: \(item.historyId)")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.blue)
                    .clipShape(Capsule())
                
                Text(item.userName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(formatTimestamp(item.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8) // 減少內邊距
        .frame(maxWidth: .infinity) // 確保寬度一致
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1) // 減少陰影
        .sheet(isPresented: $showImageViewer) {
            ImageDetailView(item: item)
        }
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = formatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM/dd HH:mm"
            return displayFormatter.string(from: date)
        }
        
        return timestamp
    }
}

// MARK: - 圖片詳細檢視
struct ImageDetailView: View {
    let item: HistoryItem
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    AsyncImageView(base64String: item.imageBase64)
                        .frame(
                            width: max(geometry.size.width * scale, geometry.size.width),
                            height: max(geometry.size.height * scale, geometry.size.height)
                        )
                        .clipped()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        // 縮放手勢
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                
                                // 限制縮放範圍
                                if scale < 1.0 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        scale = 1.0
                                        lastScale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                } else if scale > 5.0 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        scale = 5.0
                                        lastScale = 5.0
                                    }
                                }
                            },
                        
                        // 拖拽手勢
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    // 雙擊縮放
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if scale > 1.0 {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.0
                            lastScale = 2.0
                        }
                    }
                }
            }
            .background(Color.black)
            .navigationTitle("圖片詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("關閉") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            // 分享功能
                            shareImage()
                        }) {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {
                            // 儲存到相簿
                            saveToPhotos()
                        }) {
                            Label("儲存到相簿", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                // 底部資訊區域
                VStack(spacing: 8) {
                    HStack {
                        Text(item.emoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ID: \(item.historyId)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(item.userName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text(formatTimestamp(item.timestamp))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // 縮放提示
                    Text("雙擊放大 • 手勢縮放拖拽")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding()
                .background(Color.black.opacity(0.8))
            }
        }
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = formatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy/MM/dd HH:mm"
            return displayFormatter.string(from: date)
        }
        
        return timestamp
    }
    
    private func shareImage() {
        // 將 base64 轉換為 UIImage 並分享
        if let imageData = Data(base64Encoded: item.imageBase64.replacingOccurrences(of: "data:image/png;base64,", with: "")),
           let uiImage = UIImage(data: imageData) {
            
            let activityController = UIActivityViewController(
                activityItems: [uiImage],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityController, animated: true)
            }
        }
    }
    
    private func saveToPhotos() {
        // 儲存圖片到相簿
        if let imageData = Data(base64Encoded: item.imageBase64.replacingOccurrences(of: "data:image/png;base64,", with: "")),
           let uiImage = UIImage(data: imageData) {
            
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            
            // 可以加上成功提示
            // 這裡可以使用通知或其他方式提示用戶
        }
    }
}
struct AsyncImageView: View {
    let base64String: String
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        // 移除 data:image/png;base64, 前綴
        let base64Data = base64String.replacingOccurrences(of: "data:image/png;base64,", with: "")
        
        guard let data = Data(base64Encoded: base64Data),
              let uiImage = UIImage(data: data) else {
            return
        }
        
        DispatchQueue.main.async {
            self.image = uiImage
        }
    }
}

// MARK: - Preview
#Preview {
//    @State var isPresented: Bool = false
//    HistoryView(onCancel: $isPresented)
    ContentView()
}
