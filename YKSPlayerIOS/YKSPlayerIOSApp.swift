//
//  YKSPlayerIOSApp.swift
//  YKSPlayerIOS
//
//  Created by 水月空 on 2025/8/13.
//

import SwiftUI
import SwiftData

@main
struct YKS_Player_IOSApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            VideoItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
