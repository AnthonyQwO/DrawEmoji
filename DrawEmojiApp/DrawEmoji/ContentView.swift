//
//  ContentView.swift
//  DrawEmoji
//
//  Created by Tang Anthony on 2025/5/15.
//

import SwiftUI
import PhotosUI
import UIKit
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = ImageUploadViewModel()
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var showingHistoryView = false
    @State private var selectedImage: UIImage?
    @State private var prompt = ""
    @State private var userName = "user123"
    @State private var lines: [Line] = []
    @State private var showingDrawingView = false
    @State private var drawnImage: UIImage?
    @State private var showingCameraPermissionAlert = false
    
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    @State private var showingSettings = false
    
    var currentURL: String {
        settings.first?.appURL ?? appURL
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Drawing Emoji")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // Text(currentURL)
                    
                    // User Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("使用者名稱")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("輸入使用者名稱", text: $userName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 4)
                    }
                    
                    // Image Selection Section
                    VStack(spacing: 16) {
                        //                        Text("選擇圖片")
                        //                            .font(.headline)
                        //                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            // Camera Button
                            Button(action: {
                                checkCameraPermissionAndOpen()
                            }) {
                                VStack {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 24))
                                    Text("拍照")
                                        .font(.caption)
                                }
                                .frame(width: 70, height: 70)
                                .background(
                                    LinearGradient(
                                        colors: isCameraAvailable() ? [.blue, .cyan] : [.gray, .gray.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(!isCameraAvailable())
                            
                            // Photo Library Button
                            //                            Button(action: {
                            //                                showingPhotoPicker = true
                            //                            }) {
                            //                                VStack {
                            //                                    Image(systemName: "photo.fill")
                            //                                        .font(.system(size: 24))
                            //                                    Text("相簿")
                            //                                        .font(.caption)
                            //                                }
                            //                                .frame(width: 70, height: 70)
                            //                                .background(
                            //                                    LinearGradient(
                            //                                        colors: [.purple, .pink],
                            //                                        startPoint: .topLeading,
                            //                                        endPoint: .bottomTrailing
                            //                                    )
                            //                                )
                            //                                .foregroundColor(.white)
                            //                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            //                            }
                            
                            // Drawing Button
                            Button(action: {
                                showingDrawingView = true
                            }) {
                                VStack {
                                    Image(systemName: "pencil.tip")
                                        .font(.system(size: 24))
                                    Text("繪圖")
                                        .font(.caption)
                                }
                                .frame(width: 70, height: 70)
                                .background(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            // Drawing Button
                            Button(action: {
                                showingHistoryView = true
                            }) {
                                VStack {
                                    Image(systemName: "folder")
                                        .font(.system(size: 24))
                                    Text("歷史")
                                        .font(.caption)
                                }
                                .frame(width: 70, height: 70)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    
                    // Image Preview
                    if let selectedImage = selectedImage {
                        VStack(spacing: 12) {
                            Text("圖片預覽")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            Button("重新選擇") {
                                self.selectedImage = nil
                                self.drawnImage = nil
                                self.lines = []
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    
                    // Prompt Input
                    //                    VStack(alignment: .leading, spacing: 8) {
                    //                        Text("提示文字")
                    //                            .font(.headline)
                    //                            .foregroundColor(.primary)
                    //
                    //                        TextField("輸入提示文字", text: $prompt)
                    //                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    //                            .padding(.horizontal, 4)
                    //                    }
                    
                    // Send Button
                    Button(action: {
                        sendImage()
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(viewModel.isLoading ? "發送中..." : "發送圖片")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: selectedImage != nil && !userName.isEmpty ? [.blue, .purple] : [.gray, .gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .disabled(selectedImage == nil || userName.isEmpty || viewModel.isLoading)
                    }
                    
                    // Response Section - 顯示 Emoji
                    if let response = viewModel.response {
                        VStack(spacing: 16) {
                            Text("AI 回應")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Emoji 顯示區域
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                
                                VStack(spacing: 12) {
                                    // 檢查是否有解析後的服務器響應
                                    if let serverResponse = viewModel.serverResponse {
                                        // 使用解析後的 emoji 數據
                                        let emojis = parseEmojisFromString(serverResponse.emoji)
                                        
                                        if emojis.isEmpty {
                                            Text("🤔")
                                                .font(.system(size: 60))
                                                .scaleEffect(viewModel.emojiScale)
                                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.emojiScale)
                                            
                                            Text("無法識別 emoji")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        } else {
                                            // 顯示多個 emoji
                                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(emojis.count, 4)), spacing: 16) {
                                                ForEach(Array(emojis.enumerated()), id: \.offset) { index, emoji in
                                                    Text(emoji)
                                                        .font(.system(size: 50))
                                                        .scaleEffect(viewModel.emojiScale)
                                                        .rotationEffect(.degrees(viewModel.emojiRotation))
                                                        .textSelection(.enabled)
                                                        .animation(.default, value: emojis.isEmpty)
                                                    //                                                        .animation(
                                                    //                                                            .easeInOut(duration: 0.8)
                                                    //                                                            .delay(Double(index) * 0.2)
                                                    //                                                            .repeatForever(autoreverses: true),
                                                    //                                                            value: viewModel.emojiScale
                                                    //                                                        )
                                                    //                                                        .animation(
                                                    //                                                            .linear(duration: 2.0)
                                                    //                                                            .delay(Double(index) * 0.3)
                                                    //                                                            .repeatForever(autoreverses: false),
                                                    //                                                            value: viewModel.emojiRotation
                                                    //                                                        )
                                                }
                                            }
                                            .padding()
                                        }
                                        
                                        // 顯示狀態和歷史 ID
                                        HStack {
                                            Text("狀態: \(serverResponse.status)")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                            
                                            Spacer()
                                            
                                            Text("ID: \(serverResponse.historyId)")
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal)
                                        
                                    } else {
                                        // 回退到原來的解析方式（處理字符串響應）
                                        let emojis = parseEmojisFromResponse(response)
                                        
                                        if emojis.isEmpty {
                                            Text("🤔")
                                                .font(.system(size: 60))
                                                .scaleEffect(viewModel.emojiScale)
                                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.emojiScale)
                                            
                                            Text("無法識別 emoji")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        } else {
                                            // 顯示多個 emoji
                                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(emojis.count, 4)), spacing: 16) {
                                                ForEach(Array(emojis.enumerated()), id: \.offset) { index, emoji in
                                                    Text(emoji)
                                                        .font(.system(size: 50))
                                                        .scaleEffect(viewModel.emojiScale)
                                                        .rotationEffect(.degrees(viewModel.emojiRotation))
                                                    //                                                        .animation(
                                                    //                                                            .easeInOut(duration: 0.8)
                                                    //                                                            .delay(Double(index) * 0.2)
                                                    //                                                            .repeatForever(autoreverses: true),
                                                    //                                                            value: viewModel.emojiScale
                                                    //                                                        )
                                                    //                                                        .animation(
                                                    //                                                            .linear(duration: 2.0)
                                                    //                                                            .delay(Double(index) * 0.3)
                                                    //                                                            .repeatForever(autoreverses: false),
                                                    //                                                            value: viewModel.emojiRotation
                                                    //                                                        )
                                                }
                                            }
                                            .padding()
                                        }
                                        
                                        // 原始回應（小字顯示）
                                        Text(response)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(3)
                                            .padding(.horizontal)
                                    }
                                }
                                .padding()
                            }
                            .frame(minHeight: 150)
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        .onAppear {
                            viewModel.startEmojiAnimation()
                            // viewModel.updateBaseURL(currentURL)
                        }
                    }
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
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
        .fullScreenCover(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                Text("選擇照片")
            }
        }
        .onChange(of: viewModel.selectedPhotoItem) { newItem in
            if newItem != nil {
                showingPhotoPicker = false
            }
        }
        .fullScreenCover(isPresented: $showingHistoryView) {
            HistoryView {
                showingHistoryView = false
            }
        }
        .fullScreenCover(isPresented: $showingDrawingView) {
            DrawingView(lines: $lines, onSave: { image in
                selectedImage = image
                drawnImage = image
                showingDrawingView = false
            }, onCancel: {
                showingDrawingView = false
            })
        }
        .alert("相機權限", isPresented: $showingCameraPermissionAlert) {
            Button("前往設定") {
                openAppSettings()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("請在設定中允許此應用使用相機功能")
        }
        .onChange(of: viewModel.selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    drawnImage = nil
                    lines = []
                }
            }
        }
        .onAppear {
            // 只在首次載入時設定
            viewModel.updateSettings(settings)
        }
        .onChange(of: settings) { _, newSettings in
            // 🔥 這裡會即時監聽 settings 的變化
            viewModel.updateSettings(newSettings)
        }
    }
    
    private func initializeDefaultSettings() {
        if settings.isEmpty {
            let defaultSettings = AppSettings(appURL: appURL)
            modelContext.insert(defaultSettings)
            try? modelContext.save()
        }
    }
    
    
    // MARK: - Camera Helper Functions
    /// 檢查相機是否可用
    private func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    /// 檢查相機權限並打開相機
    private func checkCameraPermissionAndOpen() {
        guard isCameraAvailable() else {
            print("Camera not available on this device")
            return
        }
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .authorized:
            // 已授權，直接打開相機
            showingCamera = true
            
        case .notDetermined:
            // 未決定，請求權限
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    } else {
                        showingCameraPermissionAlert = true
                    }
                }
            }
            
        case .denied, .restricted:
            // 被拒絕或受限制，顯示提示
            showingCameraPermissionAlert = true
            
        @unknown default:
            print("Unknown camera authorization status")
        }
    }
    
    /// 打開應用設定
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // MARK: - Helper Functions
    /// 從純 emoji 字串中解析最多 8 個不重複的 emoji
    private func parseEmojisFromString(_ emojiString: String) -> [String] {
        var uniqueEmojis = Set<String>()
        
        emojiString.enumerateSubstrings(in: emojiString.startIndex..<emojiString.endIndex,
                                        options: [.byComposedCharacterSequences]) { substring, _, _, _ in
            guard let substring = substring else { return }
            
            // 檢查是否為 emoji 且尚未收集滿 8 個
            if substring.unicodeScalars.contains(where: { $0.properties.isEmoji }) && uniqueEmojis.count < 8 {
                uniqueEmojis.insert(substring)
            }
        }
        
        return Array(uniqueEmojis)
    }
    
    private func sendImage() {
        guard let image = selectedImage else { return }
        
        Task {
            await viewModel.sendImage(
                image: image,
                userName: userName,
                prompt: prompt.isEmpty ? "emoji" : prompt
            )
        }
    }
    
    // 解析回應中的 emoji
    private func parseEmojisFromResponse(_ response: String) -> [String] {
        let emojiPattern = "[\\p{Emoji_Presentation}\\p{Emoji}\\u{FE0F}]+"
        let regex = try? NSRegularExpression(pattern: emojiPattern, options: [])
        let range = NSRange(location: 0, length: response.utf16.count)
        
        let matches = regex?.matches(in: response, options: [], range: range) ?? []
        let emojis = matches.compactMap { match in
            Range(match.range, in: response).map { String(response[$0]) }
        }
        
        // 如果沒有找到 emoji，嘗試從常見的文字回應中推斷
        if emojis.isEmpty {
            return inferEmojisFromText(response)
        }
        
        return Array(Set(emojis)).prefix(6).map { String($0) } // 最多顯示6個不重複的emoji
    }
    
    // 從文字推斷 emoji
    private func inferEmojisFromText(_ text: String) -> [String] {
        let lowercased = text.lowercased()
        var emojis: [String] = []
        
        // 根據關鍵字推斷 emoji
        if lowercased.contains("happy") || lowercased.contains("smile") || lowercased.contains("開心") || lowercased.contains("笑") {
            emojis.append("😊")
        }
        if lowercased.contains("sad") || lowercased.contains("cry") || lowercased.contains("傷心") || lowercased.contains("哭") {
            emojis.append("😢")
        }
        if lowercased.contains("love") || lowercased.contains("heart") || lowercased.contains("愛") || lowercased.contains("❤") {
            emojis.append("❤️")
        }
        if lowercased.contains("cat") || lowercased.contains("貓") {
            emojis.append("🐱")
        }
        if lowercased.contains("dog") || lowercased.contains("狗") {
            emojis.append("🐶")
        }
        if lowercased.contains("fire") || lowercased.contains("熱") || lowercased.contains("火") {
            emojis.append("🔥")
        }
        if lowercased.contains("star") || lowercased.contains("星") {
            emojis.append("⭐")
        }
        if lowercased.contains("sun") || lowercased.contains("sunny") || lowercased.contains("陽光") {
            emojis.append("☀️")
        }
        if lowercased.contains("food") || lowercased.contains("eat") || lowercased.contains("食物") || lowercased.contains("吃") {
            emojis.append("🍕")
        }
        
        return emojis.isEmpty ? ["🤖"] : emojis // 如果都沒有，顯示機器人 emoji
    }
}

// MARK: - ImagePicker (UIViewControllerRepresentable)
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        
        // 針對相機進行額外設定
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didCancel: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Drawing View
struct DrawingView: View {
    @Binding var lines: [Line]
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                //                Text("繪圖")
                //                    .font(.title2)
                //                    .fontWeight(.semibold)
                //                    .padding(.top)
                
                // Drawing Canvas - 限制為正方形
                GeometryReader { geometry in
                    let canvasSize = min(geometry.size.width, geometry.size.height) - 40
                    
                    VStack {
                        Spacer()
                        
                        DrawingCanvasView(lines: $lines)
                            .frame(width: canvasSize, height: canvasSize)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, 20)
                
                // Control Buttons
                HStack(spacing: 20) {
                    Button("清除") {
                        lines.removeAll()
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Spacer()
                    
                    Button("取消") {
                        onCancel()
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    Button("完成") {
                        saveDrawing()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .disabled(lines.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .navigationTitle("繪圖")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    
    private func saveDrawing(scale: CGFloat = 1.0, canvasSize: CGSize? = nil) {
        // 如果沒有提供畫布尺寸，使用 iPad 適配的默認值
        let defaultSize: CGSize = {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad 常見的畫布尺寸，可根據你的實際情況調整
                return CGSize(width: 600, height: 600)  // 或者 CGSize(width: 1024, height: 768)
            } else {
                // iPhone 尺寸
                return CGSize(width: 400, height: 400)
            }
        }()
        
        let actualCanvasSize = canvasSize ?? defaultSize
        let scaledWidth = actualCanvasSize.width * scale
        let scaledHeight = actualCanvasSize.height * scale
        
        let renderer = ImageRenderer(content:
                                        DrawingCanvasView(lines: .constant(lines))
            .frame(width: actualCanvasSize.width, height: actualCanvasSize.height)
            .background(Color.white)
            .scaleEffect(scale)
            .frame(width: scaledWidth, height: scaledHeight)
            .clipped()
        )
        
        // 設置渲染器的大小
        renderer.proposedSize = ProposedViewSize(width: scaledWidth, height: scaledHeight)
        
        if let image = renderer.uiImage {
            onSave(image)
        }
    }
    
    // 使用範例：
    // 1. 如果你能獲取到實際畫布尺寸
    // let actualSize = CGSize(width: canvasWidth, height: canvasHeight)
    // saveDrawing(scale: 0.5, canvasSize: actualSize)
    
    // 2. 或者在 DrawingCanvasView 中添加 GeometryReader 來獲取尺寸
    // saveDrawing()           // 使用默認尺寸 400x400
    // saveDrawing(scale: 0.5) // 縮小到 50%
    
    // 建議的完整解決方案：
    // 在你的 DrawingCanvasView 外層包裝一個 GeometryReader，
    // 然後將實際尺寸傳遞給 saveDrawing 函數
}

// MARK: - Drawing Canvas View
struct DrawingCanvasView: View {
    @Binding var lines: [Line]
    @GestureState private var gestureLine = Line()
    @State private var latestLine = Line()
    
    var body: some View {
        ZStack {
            // 已完成線條
            ForEach(lines) { line in
                Path { path in
                    guard let first = line.points.first else { return }
                    path.move(to: first)
                    for point in line.points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(Color.black, lineWidth: 3)
            }
            
            // 當前繪圖中線條（灰色）
            Path { path in
                guard let first = gestureLine.points.first else { return }
                path.move(to: first)
                for point in gestureLine.points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(Color.gray, lineWidth: 2)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0.1)
                .updating($gestureLine) { value, state, _ in
                    state.points.append(value.location)
                }
                .onChanged { value in
                    latestLine.points.append(value.location)
                }
                .onEnded { _ in
                    lines.append(latestLine)
                    latestLine = Line()
                }
        )
    }
}

// MARK: - Drawing Data Model
struct Line: Identifiable {
    var id = UUID()
    var points: [CGPoint] = []
}

// MARK: - ViewModel
@MainActor
class ImageUploadViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var response: String?
    @Published var errorMessage: String?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var emojiScale: CGFloat = 1.0
    @Published var emojiRotation: Double = 0.0
    @Published var serverResponse: ServerResponse? // 新增：儲存解析後的服務器響應
    
    var baseURL: String {
        return settings.first?.appURL ?? appURL
    }
    private var settings: [AppSettings] = []
        
    // 更新設定的方法
    func updateSettings(_ newSettings: [AppSettings]) {
        self.settings = newSettings
        // 通知 UI baseURL 已改變
        objectWillChange.send()
    }

    func startEmojiAnimation() {
        withAnimation {
            emojiScale = 1.2
            emojiRotation = 360.0
        }
    }
    
    func sendImage(image: UIImage, userName: String, prompt: String) async {
        isLoading = true
        errorMessage = nil
        response = nil
        serverResponse = nil // 重置服務器響應
        
        // 重置動畫狀態
        emojiScale = 1.0
        emojiRotation = 0.0
        
        do {
            // 確保圖片是正方形並調整大小
            let processedImage = resizeToSquare(image: image, size: 512)
            
            // Convert image to base64
            guard let imageData = processedImage.jpegData(compressionQuality: 0.8) else {
                throw ImageUploadError.imageConversionFailed
            }
            
            let base64String = imageData.base64EncodedString()
            
            // Prepare request
            guard let url = URL(string: "\(baseURL)/send_image") else {
                throw ImageUploadError.invalidURL
            }
            
            print(url)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let requestBody: [String: Any] = [
                "user_name": userName,
                "image_base64": "\(base64String)",
                "prompt": prompt
            ]
            
            // print(requestBody)
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            // Send request
            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = urlResponse as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // 嘗試解析 JSON 響應
                    do {
                        let decoder = JSONDecoder()
                        let parsedResponse = try decoder.decode(ServerResponse.self, from: data)
                        serverResponse = parsedResponse
                        response = parsedResponse.emoji // 將 emoji 字符串設置為 response，以便現有的 UI 邏輯繼續工作
                    } catch {
                        // 如果 JSON 解析失敗，回退到原始字符串處理
                        if let responseString = String(data: data, encoding: .utf8) {
                            response = responseString
                        } else {
                            response = "請求成功，但無法解析回應"
                        }
                        print("JSON 解析錯誤: \(error)")
                    }
                } else {
                    let errorData = String(data: data, encoding: .utf8) ?? "未知錯誤"
                    throw ImageUploadError.serverError(httpResponse.statusCode, errorData)
                }
            }
            
        } catch {
            errorMessage = "發送失敗: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // 將圖片調整為正方形
    private func resizeToSquare(image: UIImage, size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        return renderer.image { context in
            // 白色背景
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
            
            // 計算圖片縮放比例，保持長寬比
            let imageSize = image.size
            let scale = min(size / imageSize.width, size / imageSize.height)
            let scaledWidth = imageSize.width * scale
            let scaledHeight = imageSize.height * scale
            
            // 居中繪製
            let x = (size - scaledWidth) / 2
            let y = (size - scaledHeight) / 2
            
            image.draw(in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))
        }
    }
}

// MARK: - Error Types
enum ImageUploadError: LocalizedError {
    case imageConversionFailed
    case invalidURL
    case serverError(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "圖片轉換失敗"
        case .invalidURL:
            return "無效的 URL"
        case .serverError(let code, let message):
            return "伺服器錯誤 (狀態碼: \(code)): \(message)"
        }
    }
}

// MARK: - Response Model
struct ServerResponse: Codable {
    let emoji: String
    let historyId: Int
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case emoji
        case historyId = "history_id"
        case status
    }
}

#Preview {
    ContentView()
}
