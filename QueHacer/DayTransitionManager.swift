//
//  DayTransitionManager.swift
//  QueHacer
//
//  Created by Jberg on 2025-11-17.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DayTransitionManager: ObservableObject {
    @Published var currentDay: Date = Calendar.current.startOfDay(for: Date())
    @Published var shouldRefreshToday: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var dayChangeTimer: Timer?
    
    static let shared = DayTransitionManager()
    
    private init() {
        setupDayChangeDetection()
    }
    
    private func setupDayChangeDetection() {
        // Listen for significant time changes (like day change, timezone change, etc.)
        NotificationCenter.default
            .publisher(for: .NSCalendarDayChanged)
            .sink { [weak self] _ in
                self?.handleDayChange()
            }
            .store(in: &cancellables)
        
        // Also listen for app becoming active (in case user switches days while app is backgrounded)
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkForDayChange()
            }
            .store(in: &cancellables)
        
        // Set up a timer to check periodically (backup method)
        startPeriodicDayCheck()
    }
    
    private func startPeriodicDayCheck() {
        // Check every 5 minutes for day changes (as a backup)
        dayChangeTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [self] in
                self.checkForDayChange()
            }
        }
    }
    
    private func handleDayChange() {
        Task { @MainActor in
            let newDay = Calendar.current.startOfDay(for: Date())
            if !Calendar.current.isDate(currentDay, inSameDayAs: newDay) {
                print("Day change detected: \(currentDay) -> \(newDay)")
                currentDay = newDay
                shouldRefreshToday = true
                
                // Reset the refresh flag after a brief moment to allow views to update
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.shouldRefreshToday = false
                }
            }
        }
    }
    
    private func checkForDayChange() {
        let newDay = Calendar.current.startOfDay(for: Date())
        if !Calendar.current.isDate(currentDay, inSameDayAs: newDay) {
            handleDayChange()
        }
    }
    
    /// Force a refresh (useful for testing or manual triggers)
    func forceRefresh() {
        currentDay = Calendar.current.startOfDay(for: Date())
        shouldRefreshToday = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldRefreshToday = false
        }
    }
    
    /// Check if the given date is today
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// Get the current day as a formatted string
    var currentDayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: currentDay)
    }
    
    deinit {
        dayChangeTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - View Extension for easy integration
extension View {
    func onDayChange(perform action: @escaping () -> Void) -> some View {
        self.onReceive(DayTransitionManager.shared.$currentDay) { _ in
            action()
        }
    }
    
    func refreshOnDayTransition() -> some View {
        self.onReceive(DayTransitionManager.shared.$shouldRefreshToday) { shouldRefresh in
            if shouldRefresh {
                // Force a view refresh by triggering a state change
                // This will cause any @FetchRequest to re-evaluate
                print("Refreshing view due to day transition")
            }
        }
    }
}