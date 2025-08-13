//
//  URLPlayerView.swift
//  YKS-Player-IOS
//
//  Created by 水月空 on 2025/8/13.
//

import SwiftUI

struct URLPlayerView: View {
    @State private var inputURL = "https://videos.strpst.com/206994915/fb92370184d0292cd5e93ae0ec448abe/hls/c4d9aed4aa711b5ad9fc66b984c4de86-stream-0/stream.m3u8"
    @State private var showingPlayer = false
    @State private var currentVideoItem: VideoItem?
    @State private var recentURLs: [String] = []
    
    // 预设的示例URL
    private let quickAccessURLs = [
        ("Apple HLS 示例", "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"),
        ("Big Buck Bunny (MP4)", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"),
        ("Elephant Dream (MP4)", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"),
        ("For Bigger Blazes (MP4)", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"),
        ("Sintel (MP4)", "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // URL输入区域
                VStack(alignment: .leading, spacing: 12) {
                    Text("输入视频URL")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        TextField("url", text: $inputURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        Button("播放") {
                            playURL(inputURL)
                        }
                        .disabled(inputURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(.borderedProminent)
                    }
                    
                    // URL格式提示
                    Text("支持 MP4, MOV, AVI, MKV, WMV, FLV 和 HLS (m3u8) 格式")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 快速访问区域
                VStack(alignment: .leading, spacing: 12) {
                    Text("快速访问")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(quickAccessURLs, id: \.0) { title, url in
                            QuickAccessRow(title: title, url: url) {
                                inputURL = url
                                playURL(url)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 最近播放区域
                if !recentURLs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("最近播放")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button("清除") {
                                recentURLs.removeAll()
                                saveRecentURLs()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        
                        LazyVStack(spacing: 8) {
                            ForEach(recentURLs, id: \.self) { url in
                                RecentURLRow(url: url) {
                                    inputURL = url
                                    playURL(url)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("URL播放")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadRecentURLs()
            }
        }
        .fullScreenCover(isPresented: $showingPlayer) {
            if let videoItem = currentVideoItem {
                VideoPlayerView(videoItem: videoItem)
                    .overlay(
                        Button(action: {
                            showingPlayer = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 20),
                        alignment: .topTrailing
                    )
            }
        }
    }
    
    private func playURL(_ urlString: String) {
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedURL.isEmpty,
              let _ = URL(string: trimmedURL) else {
            return
        }
        
        // 添加到最近播放
        addToRecentURLs(trimmedURL)
        
        // 创建临时视频项
        let title = extractTitleFromURL(trimmedURL)
        currentVideoItem = VideoItem(title: title, url: trimmedURL)
        
        showingPlayer = true
    }
    
    private func extractTitleFromURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else {
            return "未知视频"
        }
        
        let filename = url.lastPathComponent
        if filename.isEmpty || filename == "/" {
            return url.host ?? "网络视频"
        }
        
        // 移除文件扩展名
        let nameWithoutExtension = (filename as NSString).deletingPathExtension
        return nameWithoutExtension.isEmpty ? "网络视频" : nameWithoutExtension
    }
    
    private func addToRecentURLs(_ url: String) {
        // 移除已存在的相同URL
        recentURLs.removeAll { $0 == url }
        
        // 添加到开头
        recentURLs.insert(url, at: 0)
        
        // 限制最多保存10个
        if recentURLs.count > 10 {
            recentURLs = Array(recentURLs.prefix(10))
        }
        
        saveRecentURLs()
    }
    
    private func saveRecentURLs() {
        UserDefaults.standard.set(recentURLs, forKey: "RecentURLs")
    }
    
    private func loadRecentURLs() {
        recentURLs = UserDefaults.standard.stringArray(forKey: "RecentURLs") ?? []
    }
}

// MARK: - 快速访问行视图
struct QuickAccessRow: View {
    let title: String
    let url: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 最近播放行视图
struct RecentURLRow: View {
    let url: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(extractTitleFromURL(url))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func extractTitleFromURL(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else {
            return "未知视频"
        }
        
        let filename = url.lastPathComponent
        if filename.isEmpty || filename == "/" {
            return url.host ?? "网络视频"
        }
        
        let nameWithoutExtension = (filename as NSString).deletingPathExtension
        return nameWithoutExtension.isEmpty ? "网络视频" : nameWithoutExtension
    }
}

#Preview {
    URLPlayerView()
}
