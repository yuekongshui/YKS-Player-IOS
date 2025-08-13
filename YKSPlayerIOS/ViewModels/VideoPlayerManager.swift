//
//  VideoPlayerManager.swift
//  YKS-Player-IOS
//
//  Created by 水月空 on 2025/8/13.
//

import Foundation
import AVKit
import AVFoundation
import Combine

class VideoPlayerManager: NSObject, ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var playbackRate: Float = 1.0 {
        didSet {
            player?.rate = isPlaying ? playbackRate : 0
        }
    }
    
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var playerItem: AVPlayerItem?
    
    var onPlaybackEnd: (() -> Void)?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    deinit {
        removeTimeObserver()
        removePlayerItemObservers()
    }
    
    func setupPlayer(with urlString: String) {
        guard let url = URL(string: urlString) else {
            errorMessage = "无效的视频URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // 移除之前的观察者
        removeTimeObserver()
        removePlayerItemObservers()
        
        // 创建新的播放项
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // 添加观察者
        addPlayerItemObservers()
        addTimeObserver()
        
        // 设置画中画支持
        setupPictureInPicture()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("音频会话设置失败: \(error)")
        }
    }
    
    private func setupPictureInPicture() {
        guard player != nil else { return }
        
        // 确保支持画中画
        if AVPictureInPictureController.isPictureInPictureSupported() {
            // 这里可以添加画中画控制器的设置
            print("画中画功能可用")
        }
    }
    
    private func addPlayerItemObservers() {
        guard let playerItem = playerItem else { return }
        
        // 监听播放状态
        playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .readyToPlay:
                        self?.isLoading = false
                        self?.duration = playerItem.duration.seconds
                        self?.errorMessage = nil
                    case .failed:
                        self?.isLoading = false
                        self?.errorMessage = playerItem.error?.localizedDescription ?? "播放失败"
                    case .unknown:
                        self?.isLoading = true
                    @unknown default:
                        break
                    }
                }
            }
            .store(in: &cancellables)
        
        // 监听缓冲状态
        playerItem.publisher(for: \.isPlaybackBufferEmpty)
            .sink { [weak self] isEmpty in
                DispatchQueue.main.async {
                    if isEmpty && self?.isPlaying == true {
                        self?.isLoading = true
                    }
                }
            }
            .store(in: &cancellables)
        
        playerItem.publisher(for: \.isPlaybackLikelyToKeepUp)
            .sink { [weak self] isLikelyToKeepUp in
                DispatchQueue.main.async {
                    if isLikelyToKeepUp {
                        self?.isLoading = false
                    }
                }
            }
            .store(in: &cancellables)
        
        // 监听播放结束
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isPlaying = false
                    self?.onPlaybackEnd?()
                }
            }
            .store(in: &cancellables)
    }
    
    private func removePlayerItemObservers() {
        cancellables.removeAll()
    }
    
    private func addTimeObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }
    
    private func removeTimeObserver() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    // MARK: - 播放控制方法
    
    func play() {
        player?.rate = playbackRate
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    func seekForward(_ seconds: TimeInterval = 15) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func seekBackward(_ seconds: TimeInterval = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    func togglePictureInPicture() {
        // 这里可以实现画中画切换逻辑
        // 需要配合AVPlayerViewController使用
        print("切换画中画模式")
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player?.rate = rate
        }
    }
}

// MARK: - 扩展：支持的视频格式检查
extension VideoPlayerManager {
    static func isSupportedVideoFormat(_ url: String) -> Bool {
        let supportedExtensions = ["mp4", "mov", "avi", "mkv", "wmv", "flv", "m3u8"]
        let urlLower = url.lowercased()
        
        // 检查文件扩展名
        for ext in supportedExtensions {
            if urlLower.contains(".\(ext)") {
                return true
            }
        }
        
        // 检查是否为流媒体URL
        if urlLower.hasPrefix("http://") || urlLower.hasPrefix("https://") {
            return true
        }
        
        return false
    }
}
