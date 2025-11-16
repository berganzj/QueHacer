//
//  HistoryView.swift
//  QueHacer
//
//  Created by Jberg on 2025-11-15.
//

import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.createdDate, ascending: false)],
        predicate: nil,
        animation: .default
    )
    private var allActivities: FetchedResults<Item>
    
    // Group activities by date
    private var activitiesByDate: [(Date, [Item])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allActivities) { activity in
            calendar.startOfDay(for: activity.createdDate!)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(activitiesByDate, id: \.0) { date, activities in
                    NavigationLink(destination: DayDetailView(date: date, activities: activities)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatDate(date))
                                    .font(.headline)
                                
                                Text("\(activities.count) activities")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 8) {
                                    // Completed count
                                    HStack(spacing: 2) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        Text("\(activities.filter { $0.isCompleted }.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // Archived count
                                    if activities.contains(where: { $0.isArchived }) {
                                        HStack(spacing: 2) {
                                            Image(systemName: "archivebox.fill")
                                                .foregroundColor(.orange)
                                                .font(.caption)
                                            Text("\(activities.filter { $0.isArchived }.count)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("History")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE" // Day of week
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

struct DayDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let date: Date
    let activities: [Item]
    
    private var incompleteActivities: [Item] {
        activities.filter { !$0.isCompleted && !$0.isArchived }
    }
    
    private var completedActivities: [Item] {
        activities.filter { $0.isCompleted && !$0.isArchived }
    }
    
    private var archivedActivities: [Item] {
        activities.filter { $0.isArchived }
    }
    
    var body: some View {
        List {
            if !incompleteActivities.isEmpty {
                Section("Incomplete") {
                    ForEach(incompleteActivities, id: \.self) { activity in
                        ActivityRowView(activity: activity, showCheckbox: false)
                    }
                }
            }
            
            if !completedActivities.isEmpty {
                Section("Completed") {
                    ForEach(completedActivities, id: \.self) { activity in
                        ActivityRowView(activity: activity, showCheckbox: false)
                    }
                }
            }
            
            if !archivedActivities.isEmpty {
                Section("Cleared") {
                    ForEach(archivedActivities, id: \.self) { activity in
                        ActivityRowView(activity: activity, showCheckbox: false)
                    }
                }
            }
        }
        .navigationTitle(formatDateTitle(date))
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func formatDateTitle(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .full
            return formatter.string(from: date)
        }
    }
}

struct ActivityRowView: View {
    let activity: Item
    let showCheckbox: Bool
    
    var body: some View {
        HStack {
            if showCheckbox {
                Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(activity.isCompleted ? .green : .gray)
                    .font(.title2)
            } else {
                Image(systemName: getStatusIcon())
                    .foregroundColor(getStatusColor())
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.activityDescription ?? "Unknown Activity")
                    .strikethrough(activity.isCompleted || activity.isArchived)
                    .foregroundColor(getTextColor())
                
                if let completedDate = activity.completedDate {
                    Text("Completed at \(formatTime(completedDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func getStatusIcon() -> String {
        if activity.isArchived {
            return "archivebox.fill"
        } else if activity.isCompleted {
            return "checkmark.circle.fill"
        } else {
            return "circle"
        }
    }
    
    private func getStatusColor() -> Color {
        if activity.isArchived {
            return .orange
        } else if activity.isCompleted {
            return .green
        } else {
            return .gray
        }
    }
    
    private func getTextColor() -> Color {
        if activity.isArchived {
            return .secondary
        } else if activity.isCompleted {
            return .secondary
        } else {
            return .primary
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}