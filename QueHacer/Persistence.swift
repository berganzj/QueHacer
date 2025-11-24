//
//  Persistence.swift
//  QueHacer
//
//  Created by Jberg on 2025-11-10.
//  Updated by Jberg on 2025-11-24.
//

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample activities for preview
        let sampleActivities = [
            "Review quarterly reports",
            "Call dentist for appointment", 
            "Grocery shopping",
            "Exercise for 30 minutes",
            "Read chapter 5"
        ]
        
        for (index, activity) in sampleActivities.enumerated() {
            let newItem = Item(context: viewContext)
            newItem.activityDescription = activity
            newItem.isCompleted = index % 2 == 0 // Make some completed for demo
            newItem.createdDate = Calendar.current.date(byAdding: .day, value: -index, to: Date()) ?? Date()
            newItem.isArchived = false
            
            // Set completion date for completed items
            if newItem.isCompleted {
                newItem.completedDate = newItem.createdDate
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "QueHacer")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure persistent store for app upgrades and data persistence
            setupPersistentStore()
        }
        
        // Configure container for better performance and reliability
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Load persistent stores with proper error handling
        loadPersistentStores()
    }
    
    /// Sets up the persistent store with proper configuration for data persistence across app updates
    private func setupPersistentStore() {
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to get persistent store description")
        }
        
        // Ensure data persists across app upgrades
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        
        // Set data protection level (allows access when device is unlocked)
        description.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        
        // Configure for better performance
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Set custom store location in Documents directory for better persistence
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let storeURL = documentsPath.appendingPathComponent("QueHacer.sqlite")
            description.url = storeURL
            
            print("Core Data store location: \(storeURL.path)")
        }
    }
    
    /// Loads persistent stores with comprehensive error handling
    private func loadPersistentStores() {
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
                
                // Handle specific migration errors
                if error.code == NSPersistentStoreIncompatibleVersionHashError ||
                   error.code == NSMigrationMissingSourceModelError {
                    
                    print("Migration error detected. Attempting store recreation...")
                    self.handleMigrationError(storeDescription: storeDescription, error: error)
                    
                } else {
                    // For other critical errors, this is a developer issue
                    fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
                }
            } else {
                print("Core Data store loaded successfully: \(storeDescription.url?.path ?? "unknown")")
            }
        }
    }
    
    /// Handles Core Data migration errors by attempting store recreation
    /// This is a last resort to prevent app crashes due to migration issues
    private func handleMigrationError(storeDescription: NSPersistentStoreDescription, error: NSError) {
        guard let storeURL = storeDescription.url else {
            fatalError("No store URL available for migration error recovery")
        }
        
        print("Attempting to delete and recreate Core Data store due to migration failure")
        
        do {
            // Remove the incompatible store files
            try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
            
            // Also remove associated files
            let fileManager = FileManager.default
            let storeDirectory = storeURL.deletingLastPathComponent()
            let storeName = storeURL.deletingPathExtension().lastPathComponent
            
            let associatedFiles = [
                "\(storeName)-wal",
                "\(storeName)-shm"
            ]
            
            for fileName in associatedFiles {
                let fileURL = storeDirectory.appendingPathComponent(fileName)
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
            }
            
            // Recreate the store
            try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: storeDescription.options)
            
            print("Core Data store successfully recreated")
            
        } catch {
            fatalError("Failed to recover from Core Data migration error: \(error)")
        }
    }
    
    /// Saves the Core Data context with error handling
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Core Data save error: \(nsError), \(nsError.userInfo)")
                
                // For save errors, we don't want to crash the app
                // Log the error and potentially show user notification
                #if DEBUG
                fatalError("Unresolved Core Data save error \(nsError), \(nsError.userInfo)")
                #endif
            }
        }
    }
    
    /// Performs a background save operation
    func saveInBackground() {
        let context = container.newBackgroundContext()
        context.perform {
            do {
                try context.save()
            } catch {
                print("Background save failed: \(error)")
            }
        }
    }
}
