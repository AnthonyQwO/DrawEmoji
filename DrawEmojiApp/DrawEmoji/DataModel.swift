//
//  Untitled.swift
//  DrawEmoji
//
//  Created by Tang Anthony on 2025/6/7.
//

import SwiftUI
import SwiftData

// MARK: - SwiftData Model
@Model
class AppSettings {
    var appURL: String
    var createdAt: Date
    
    init(appURL: String) {
        self.appURL = appURL
        self.createdAt = Date()
    }
}


// MARK: - Main View
struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    @State private var showingSettings = false
    
    var currentURL: String {
        settings.first?.appURL ?? "https://7d60-36-224-62-77.ngrok-free.app/"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 顯示當前 URL
                VStack(alignment: .leading, spacing: 8) {
                    Text("當前 App URL:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(currentURL)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                
                // 狀態指示器
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("URL 已設定")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 測試按鈕
                Button(action: {
                    // 這裡可以添加 URL 測試邏輯
                    print("測試 URL: \(currentURL)")
                }) {
                    HStack {
                        Image(systemName: "network")
                        Text("測試連接")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("應用設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                initializeDefaultSettings()
            }
        }
    }
    
    private func initializeDefaultSettings() {
        if settings.isEmpty {
            let defaultSettings = AppSettings(appURL: "https://7d60-36-224-62-77.ngrok-free.app/")
            modelContext.insert(defaultSettings)
            try? modelContext.save()
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [AppSettings]
    
    @State private var urlText: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("App URL")
                            .font(.headline)
                        
                        TextField("輸入 URL", text: $urlText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                        
                        Text("請輸入完整的 URL，包含 http:// 或 https://")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("URL 設定")
                } footer: {
                    Text("此 URL 將用於應用的 API 連接")
                }
                
                Section {
                    if let currentSetting = settings.first {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("當前 URL:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(currentSetting.appURL)
                                .font(.system(.caption, design: .monospaced))
                            
                            Text("設定時間:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                            Text(currentSetting.createdAt, style: .date)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("當前設定")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("儲存") {
                        saveSettings()
                    }
                    .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                urlText = settings.first?.appURL ?? ""
            }
            .alert("設定結果", isPresented: $showingAlert) {
                Button("確定") {
                    if alertMessage.contains("成功") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveSettings() {
        let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 簡單的 URL 驗證
        guard isValidURL(trimmedURL) else {
            alertMessage = "請輸入有效的 URL 格式"
            showingAlert = true
            return
        }
        
        do {
            if let existingSetting = settings.first {
                // 更新現有設定
                existingSetting.appURL = trimmedURL
                existingSetting.createdAt = Date()
            } else {
                // 創建新設定
                let newSetting = AppSettings(appURL: trimmedURL)
                modelContext.insert(newSetting)
            }
            
            try modelContext.save()
            alertMessage = "URL 設定儲存成功！"
            showingAlert = true
            
        } catch {
            alertMessage = "儲存失敗：\(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme != nil && url.host != nil
    }
}

// MARK: - Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .modelContainer(for: AppSettings.self, inMemory: true)
    }
}
