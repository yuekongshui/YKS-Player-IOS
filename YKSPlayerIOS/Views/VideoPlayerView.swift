//
//  VideoPlayerView.swift
//  YKS-Player-IOS
//
//  Created by 水月空 on 2025/8/13.
//

import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    @StateObject private var playerManager = VideoPlayerManager()
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var showSpeedMenu = false
    @State private var showQualityMenu = false
    
    let videoItem: VideoItem
    let onPlaybackEnd: (() -> Void)?
    
    init(videoItem: VideoItem, onPlaybackEnd: (() -> Void)? = nil) {
        self.videoItem = videoItem
        self.onPlaybackEnd = onPlaybackEnd
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 视频播放器
                VideoPlayer(player: playerManager.player)
                    .onTapGesture {
                        toggleControls()
                    }
                    .onAppear {
                        playerManager.setupPlayer(with: videoItem.url)
                        playerManager.onPlaybackEnd = onPlaybackEnd
                    }
                    .onDisappear {
                        playerManager.pause()
                    }
                
                // 控制栏
                if showControls {
                    VStack {
                        Spacer()
                        
                        // 底部控制栏
                        VStack(spacing: 8) {
                            // 进度条
                            HStack {
                                Text(formatTime(playerManager.currentTime))
                                    .font(.caption)
                                    .foregroundColor(.white)
                                
                                Slider(value: Binding(
                                    get: { playerManager.currentTime },
                                    set: { playerManager.seek(to: $0) }
                                ), in: 0...max(playerManager.duration, 1))
                                .accentColor(.white)
                                
                                Text(formatTime(playerManager.duration))
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            
                            // 控制按钮
                            HStack(spacing: 20) {
                                // 快退
                                Button(action: { playerManager.seekBackward() }) {
                                    Image(systemName: "gobackward.15")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                // 播放/暂停
                                Button(action: { playerManager.togglePlayPause() }) {
                                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                                
                                // 快进
                                Button(action: { playerManager.seekForward() }) {
                                    Image(systemName: "goforward.15")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                // 倍速
                                Button(action: { showSpeedMenu.toggle() }) {
                                    Text("\(playerManager.playbackRate, specifier: "%.1f")x")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.black.opacity(0.5))
                                        .cornerRadius(4)
                                }
                                .popover(isPresented: $showSpeedMenu) {
                                    SpeedSelectionView(selectedSpeed: $playerManager.playbackRate)
                                }
                                
                                // 画中画
                                Button(action: { playerManager.togglePictureInPicture() }) {
                                    Image(systemName: "pip")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .transition(.opacity)
                }
                
                // 加载指示器
                if playerManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                // 错误提示
                if let errorMessage = playerManager.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                }
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
        .statusBarHidden(true)
        .ignoresSafeArea(.all)
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        
        if showControls {
            resetControlsTimer()
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    

    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 倍速选择视图
struct SpeedSelectionView: View {
    @Binding var selectedSpeed: Float
    @Environment(\.dismiss) private var dismiss
    
    let speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题
            Text("播放速度")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            Divider()
                .padding(.horizontal, 8)
            
            // 速度选项
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(speeds, id: \.self) { speed in
                        Button(action: {
                            selectedSpeed = speed
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Text("\(speed, specifier: "%.2f")x")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if speed == selectedSpeed {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                speed == selectedSpeed ? 
                                Color.blue.opacity(0.1) : Color.clear
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if speed != speeds.last {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .frame(width: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

#Preview {
    VideoPlayerView(videoItem: VideoItem(title: "测试视频", url: "https://videos.strpst.com/206994915/fb92370184d0292cd5e93ae0ec448abe/hls/c4d9aed4aa711b5ad9fc66b984c4de86-stream-0/stream.m3u8"))
}
