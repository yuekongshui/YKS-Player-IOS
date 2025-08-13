//
//  VideoItem.swift
//  YKS-Player-IOS
//
//  Created by 水月空 on 2025/8/13.
//

import Foundation
import SwiftData

@Model
final class VideoItem {
    var id: UUID
    var title: String
    var url: String
    var duration: TimeInterval
    var currentTime: TimeInterval
    var isCompleted: Bool
    var addedDate: Date
    var sortOrder: Int
    var thumbnailData: Data?
    
    init(title: String, url: String, duration: TimeInterval = 0, currentTime: TimeInterval = 0, isCompleted: Bool = false, sortOrder: Int = 0, thumbnailData: Data? = nil) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.duration = duration
        self.currentTime = currentTime
        self.isCompleted = isCompleted
        self.addedDate = Date()
        self.sortOrder = sortOrder
        self.thumbnailData = thumbnailData
    }
}

// MARK: - 播放模式枚举
enum PlaybackMode: String, CaseIterable {
    case sequential = "sequential"  // 顺序播放
    case random = "random"         // 随机播放
    case single = "single"         // 单曲播放
    
    var displayName: String {
        switch self {
        case .sequential:
            return "顺序播放"
        case .random:
            return "随机播放"
        case .single:
            return "单曲播放"
        }
    }
    
    var iconName: String {
        switch self {
        case .sequential:
            return "repeat"
        case .random:
            return "shuffle"
        case .single:
            return "repeat.1"
        }
    }
}