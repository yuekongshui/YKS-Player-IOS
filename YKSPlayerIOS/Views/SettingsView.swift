//
//  SettingsView.swift
//  YKS-Player-IOS
//
//  Created by 水月空 on 2025/8/13.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var videoItems: [VideoItem]
    
    @AppStorage("autoPlayNext") private var autoPlayNext = true
    @AppStorage("rememberPlaybackPosition") private var rememberPlaybackPosition = true
    @AppStorage("defaultPlaybackSpeed") private var defaultPlaybackSpeed = 1.0
    @AppStorage("enablePictureInPicture") private var enablePictureInPicture = true
    @AppStorage("showControlsTimeout") private var showControlsTimeout = 3.0
    
    @State private var showingClearDataAlert = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                // 播放设置
                Section(header: Text("播放设置")) {
                    Toggle("自动播放下一个", isOn: $autoPlayNext)
                    
                    Toggle("记住播放位置", isOn: $rememberPlaybackPosition)
                    
                    Toggle("启用画中画", isOn: $enablePictureInPicture)
                    
                    VStack(alignment: .leading) {
                        Text("默认播放速度: \(defaultPlaybackSpeed, specifier: "%.1f")x")
                        Slider(value: $defaultPlaybackSpeed, in: 0.5...2.0, step: 0.25)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("控制栏隐藏时间: \(Int(showControlsTimeout))秒")
                        Slider(value: $showControlsTimeout, in: 1...10, step: 1)
                    }
                }
                
                // 数据管理
                Section(header: Text("数据管理")) {
                    HStack {
                        Text("播放列表视频数量")
                        Spacer()
                        Text("\(videoItems.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("清除播放历史") {
                        clearRecentURLs()
                    }
                    .foregroundColor(.orange)
                    
                    Button("清除所有数据") {
                        showingClearDataAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                // 支持的格式
                Section(header: Text("支持的格式")) {
                    VStack(alignment: .leading, spacing: 8) {
                        FormatInfoRow(title: "视频格式", formats: "MP4, MOV, AVI, MKV, WMV, FLV")
                        FormatInfoRow(title: "流媒体", formats: "HLS (m3u8), HTTP/HTTPS 视频流")
                        FormatInfoRow(title: "音频", formats: "AAC, MP3, WAV (视频中的音轨)")
                    }
                }
                
                // 应用信息
                Section(header: Text("应用信息")) {
                    Button("关于应用") {
                        showingAbout = true
                    }
                    
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Bundle ID")
                        Spacer()
                        Text("com.syk.study.YKS-Player-IOS")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                // 帮助和反馈
                Section(header: Text("帮助和反馈")) {
                    NavigationLink("使用说明", destination: HelpView())
                    
                    Button("重置所有设置") {
                        resetAllSettings()
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("清除所有数据", isPresented: $showingClearDataAlert) {
            Button("取消", role: .cancel) { }
            Button("确认清除", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("这将删除所有播放列表中的视频和播放历史，此操作不可撤销。")
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private func clearRecentURLs() {
        UserDefaults.standard.removeObject(forKey: "RecentURLs")
    }
    
    private func clearAllData() {
        // 清除播放列表
        for video in videoItems {
            modelContext.delete(video)
        }
        
        // 清除播放历史
        clearRecentURLs()
        
        // 保存更改
        do {
            try modelContext.save()
        } catch {
            print("清除数据失败: \(error)")
        }
    }
    
    private func resetAllSettings() {
        autoPlayNext = true
        rememberPlaybackPosition = true
        defaultPlaybackSpeed = 1.0
        enablePictureInPicture = true
        showControlsTimeout = 3.0
    }
}

// MARK: - 格式信息行
struct FormatInfoRow: View {
    let title: String
    let formats: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(formats)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 关于视图
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 应用图标和名称
                VStack(spacing: 16) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("YKS Player iOS")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("专业的iOS视频播放器")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 功能特性
                VStack(alignment: .leading, spacing: 12) {
                    Text("主要功能")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    FeatureRow(icon: "play.circle", title: "多格式支持", description: "支持MP4, MOV, AVI, MKV等多种视频格式")
                    FeatureRow(icon: "wifi", title: "网络流媒体", description: "支持HLS (m3u8)和HTTP/HTTPS视频流")
                    FeatureRow(icon: "list.bullet", title: "播放列表", description: "管理视频播放列表，支持拖拽排序")
                    FeatureRow(icon: "pip", title: "画中画", description: "支持画中画播放模式")
                    FeatureRow(icon: "speedometer", title: "倍速播放", description: "0.5x到2x倍速播放")
                }
                
                Spacer()
                
                // 版权信息
                VStack(spacing: 8) {
                    Text("版本 1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("© 2025 水月空. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 功能特性行
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - 帮助视图
struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HelpSection(
                    title: "添加视频",
                    content: "在播放列表页面点击右上角的 + 按钮，输入视频标题和URL地址即可添加视频到播放列表。"
                )
                
                HelpSection(
                    title: "URL播放",
                    content: "在URL播放页面直接输入视频链接即可播放，支持多种视频格式和流媒体协议。"
                )
                
                HelpSection(
                    title: "播放控制",
                    content: "点击视频画面显示/隐藏控制栏。支持播放/暂停、快进/快退、倍速播放、全屏和画中画等功能。"
                )
                
                HelpSection(
                    title: "播放列表管理",
                    content: "在播放列表页面点击编辑按钮可以对视频进行排序、删除等操作。支持拖拽排序和上移下移功能。"
                )
                
                HelpSection(
                    title: "播放模式",
                    content: "支持顺序播放、随机播放和单曲播放三种模式。点击播放模式按钮可以切换不同的播放方式。"
                )
                
                HelpSection(
                    title: "支持的格式",
                    content: "视频格式：MP4, MOV, AVI, MKV, WMV, FLV\n流媒体：HLS (m3u8), HTTP/HTTPS 视频流"
                )
            }
            .padding()
        }
        .navigationTitle("使用说明")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 帮助章节
struct HelpSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: VideoItem.self, inMemory: true)
}