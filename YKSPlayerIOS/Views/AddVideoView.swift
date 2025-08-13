//
//  AddVideoView.swift
//  YKS-Player-IOS
//
//  Created by 水月空 on 2025/8/13.
//

import SwiftUI
import SwiftData

struct AddVideoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingVideos: [VideoItem]
    
    @State private var videoTitle = ""
    @State private var videoURL = ""
    @State private var isValidating = false
    @State private var validationMessage = ""
    @State private var isURLValid = false
    
    // 预设的示例URL
    private let sampleURLs = [
        ("Apple HLS 示例", "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"),
        ("Big Buck Bunny", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"),
        ("Elephant Dream", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"),
        ("For Bigger Blazes", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("视频信息")) {
                    TextField("视频标题", text: $videoTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    VStack(alignment: .leading) {
                        TextField("视频URL", text: $videoURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: videoURL) { _, newValue in
                                validateURL(newValue)
                            }
                        
                        if !validationMessage.isEmpty {
                            Text(validationMessage)
                                .font(.caption)
                                .foregroundColor(isURLValid ? .green : .red)
                        }
                    }
                }
                
                Section(header: Text("示例视频")) {
                    ForEach(sampleURLs, id: \.0) { title, url in
                        Button(action: {
                            videoTitle = title
                            videoURL = url
                            validateURL(url)
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(title)
                                        .foregroundColor(.primary)
                                    Text(url)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Section(header: Text("支持的格式")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("视频格式: MP4, MOV, AVI, MKV, WMV, FLV")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("流媒体: HLS (m3u8), HTTP/HTTPS 视频流")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("URL示例:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("• https://example.com/video.mp4")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• https://example.com/playlist.m3u8")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("添加视频")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        addVideo()
                    }
                    .disabled(!canAddVideo)
                }
            }
        }
    }
    
    private var canAddVideo: Bool {
        !videoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !videoURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isURLValid &&
        !isValidating
    }
    
    private func validateURL(_ url: String) {
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedURL.isEmpty else {
            validationMessage = ""
            isURLValid = false
            return
        }
        
        isValidating = true
        
        // 检查URL格式
        guard let _ = URL(string: trimmedURL) else {
            validationMessage = "无效的URL格式"
            isURLValid = false
            isValidating = false
            return
        }
        
        // 检查是否为支持的协议
        guard trimmedURL.hasPrefix("http://") || trimmedURL.hasPrefix("https://") else {
            validationMessage = "仅支持 HTTP/HTTPS 协议"
            isURLValid = false
            isValidating = false
            return
        }
        
        // 检查是否为支持的视频格式
        if VideoPlayerManager.isSupportedVideoFormat(trimmedURL) {
            validationMessage = "支持的视频格式"
            isURLValid = true
        } else {
            validationMessage = "可能不支持的格式，但仍可尝试播放"
            isURLValid = true // 允许用户尝试
        }
        
        // 检查是否已存在
        if existingVideos.contains(where: { $0.url == trimmedURL }) {
            validationMessage = "该视频已存在于播放列表中"
            isURLValid = false
        }
        
        isValidating = false
    }
    
    private func addVideo() {
        let trimmedTitle = videoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = videoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty && !trimmedURL.isEmpty else { return }
        
        // 计算新的排序顺序
        let maxSortOrder = existingVideos.map { $0.sortOrder }.max() ?? -1
        
        let newVideo = VideoItem(
            title: trimmedTitle,
            url: trimmedURL,
            sortOrder: maxSortOrder + 1
        )
        
        modelContext.insert(newVideo)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("保存视频失败: \(error)")
            // 这里可以显示错误提示
        }
    }
}

#Preview {
    AddVideoView()
        .modelContainer(for: VideoItem.self, inMemory: true)
}