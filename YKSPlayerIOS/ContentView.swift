//
//  ContentView.swift
//  YKSPlayerIOS
//
//  Created by 水月空 on 2025/8/13.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 播放列表标签页
            PlaylistView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("播放列表")
                }
                .tag(0)
            
            // URL播放标签页
            URLPlayerView()
                .tabItem {
                    Image(systemName: "link")
                    Text("URL播放")
                }
                .tag(1)
            
            // 设置标签页
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: VideoItem.self, inMemory: true)
}
