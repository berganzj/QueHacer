//
//  QueHacerApp.swift
//  QueHacer
//
//  Created by Jberg on 2025-11-10.
//

import SwiftUI
import CoreData

@main
struct QueHacerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
