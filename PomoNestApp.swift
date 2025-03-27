//
//  PomoNestApp.swift
//  PomoNest
//
//  Created by klein cafa on 2025-03-27.
//

import SwiftUI
import SwiftData

@main
struct PomoNestApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(for: [Semester.self, Course.self, Assignment.self, TodoItem.self])
        }
    }
}
