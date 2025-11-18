//
//  MainTabView.swift
//  QueHacer
//
//  Created by Jberg on 2025-11-15.
//

import SwiftUI
import CoreData

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var dayManager = DayTransitionManager.shared
    
    var body: some View {
        TabView {
            TodayView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Today", systemImage: "calendar.badge.plus")
                }
            
            HistoryView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
        }
        .onAppear {
            // Initialize day manager when app starts
            print("App started on: \(dayManager.currentDayString)")
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}