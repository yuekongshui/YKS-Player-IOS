//
//  PlaylistView.swift
//  YKS-Player-IOS
//
//  Created by 水月空 on 2025/8/13.
//

import SwiftUI
import SwiftData

struct PlaylistView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VideoItem.sortOrder) private var videoItems: [VideoItem]
    
    @State private var isEditMode = false
    @State private var playbackMode: PlaybackMode = .sequential
    @State private var showingAddVideo = false
    @State private var selectedVideo: VideoItem?
    @State private var showingPlayer = false
    
    var body: some View {
        NavigationView {
            VStack {
                // 播放模式和编辑按钮
                HStack {
                    // 播放模式切换
                    Button(action: { togglePlaybackMode() }) {
                        HStack {
                            Image(systemName: playbackMode.iconName)
                            Text(playbackMode.displayName)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // 编辑模式切换
                    Button(action: { isEditMode.toggle() }) {
                        Text(isEditMode ? "完成" : "编辑")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // 视频列表
                if videoItems.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "video.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("暂无视频")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .padding(.top)
                        Text("点击右上角 + 添加视频")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(videoItems) { video in
                            VideoRowView(
                                video: video,
                                isEditMode: isEditMode,
                                onPlay: { playVideo(video) },
                                onMoveUp: { moveVideoUp(video) },
                                onMoveDown: { moveVideoDown(video) },
                                onDelete: { deleteVideo(video) }
                            )
                        }
                        .onMove(perform: isEditMode ? moveVideos : nil)
                        .onDelete(perform: deleteVideos)
                    }
                    .environment(\.editMode, .constant(isEditMode ? .active : .inactive))
                }
            }
            .navigationTitle("播放列表")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddVideo = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddVideo) {
                AddVideoView()
            }
            .fullScreenCover(isPresented: $showingPlayer) {
                if let selectedVideo = selectedVideo {
                    VideoPlayerView(videoItem: selectedVideo) {
                        // 播放结束回调
                        handlePlaybackEnd()
                    }
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
    }
    
    // MARK: - 播放控制方法
    
    private func playVideo(_ video: VideoItem) {
        selectedVideo = video
        showingPlayer = true
    }
    
    private func handlePlaybackEnd() {
        guard let currentVideo = selectedVideo else { return }
        
        switch playbackMode {
        case .sequential:
            playNextVideo(after: currentVideo)
        case .random:
            playRandomVideo()
        case .single:
            // 单曲播放，不自动播放下一首
            break
        }
    }
    
    private func playNextVideo(after currentVideo: VideoItem) {
        guard let currentIndex = videoItems.firstIndex(where: { $0.id == currentVideo.id }) else { return }
        
        let nextIndex = currentIndex + 1
        if nextIndex < videoItems.count {
            selectedVideo = videoItems[nextIndex]
        } else {
            // 播放完毕，关闭播放器
            showingPlayer = false
        }
    }
    
    private func playRandomVideo() {
        guard !videoItems.isEmpty else { return }
        
        let randomVideo = videoItems.randomElement()
        selectedVideo = randomVideo
    }
    
    private func togglePlaybackMode() {
        let allModes = PlaybackMode.allCases
        if let currentIndex = allModes.firstIndex(of: playbackMode) {
            let nextIndex = (currentIndex + 1) % allModes.count
            playbackMode = allModes[nextIndex]
        }
    }
    
    // MARK: - 列表管理方法
    
    private func moveVideoUp(_ video: VideoItem) {
        guard let currentIndex = videoItems.firstIndex(where: { $0.id == video.id }),
              currentIndex > 0 else { return }
        
        let previousVideo = videoItems[currentIndex - 1]
        
        // 交换排序顺序
        let tempOrder = video.sortOrder
        video.sortOrder = previousVideo.sortOrder
        previousVideo.sortOrder = tempOrder
        
        saveContext()
    }
    
    private func moveVideoDown(_ video: VideoItem) {
        guard let currentIndex = videoItems.firstIndex(where: { $0.id == video.id }),
              currentIndex < videoItems.count - 1 else { return }
        
        let nextVideo = videoItems[currentIndex + 1]
        
        // 交换排序顺序
        let tempOrder = video.sortOrder
        video.sortOrder = nextVideo.sortOrder
        nextVideo.sortOrder = tempOrder
        
        saveContext()
    }
    
    private func moveVideos(from source: IndexSet, to destination: Int) {
        var updatedItems = videoItems
        updatedItems.move(fromOffsets: source, toOffset: destination)
        
        // 更新排序顺序
        for (index, item) in updatedItems.enumerated() {
            item.sortOrder = index
        }
        
        saveContext()
    }
    
    private func deleteVideo(_ video: VideoItem) {
        modelContext.delete(video)
        saveContext()
    }
    
    private func deleteVideos(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(videoItems[index])
        }
        saveContext()
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("保存失败: \(error)")
        }
    }
}

// MARK: - 视频行视图
struct VideoRowView: View {
    let video: VideoItem
    let isEditMode: Bool
    let onPlay: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // 视频缩略图
            AsyncImage(url: URL(string: video.url)) { image in
                image
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "video")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 80, height: 45)
            .cornerRadius(8)
            
            // 视频信息
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(video.url)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if video.duration > 0 {
                    Text(formatDuration(video.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 编辑模式按钮
            if isEditMode {
                VStack {
                    Button(action: onMoveUp) {
                        Image(systemName: "chevron.up")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: onMoveDown) {
                        Image(systemName: "chevron.down")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            } else {
                // 播放按钮
                Button(action: onPlay) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditMode {
                onPlay()
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    PlaylistView()
        .modelContainer(for: VideoItem.self, inMemory: true)
}