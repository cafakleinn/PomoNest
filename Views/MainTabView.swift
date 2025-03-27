//
//  MainTabView.swift
//  PomoNest
//
//  Created by Trae AI on 2025-03-27.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            CoursesView()
                .tabItem {
                    Label("Courses", systemImage: "book")
                }
                .tag(1)
            
            AssignmentTrackerView()
                .tabItem {
                    Label("Assignments", systemImage: "list.clipboard")
                }
                .tag(2)
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(3)
            
            PomodoroView()
                .tabItem {
                    Label("Pomodoro", systemImage: "timer")
                }
                .tag(4)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Semester.self, Course.self, Assignment.self, TodoItem.self], inMemory: true)
}