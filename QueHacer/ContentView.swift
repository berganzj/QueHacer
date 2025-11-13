//
//  ContentView.swift
//  QueHacer
//
//  Created by Jberg on 2025-11-10.
//  Updated by Jberg on 2025-11-12.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var newActivityText = ""
    @State private var showingAddActivity = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.createdDate, ascending: true)],
        predicate: NSPredicate(format: "createdDate >= %@ AND createdDate < %@", 
                              Calendar.current.startOfDay(for: Date()) as NSDate,
                              Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))! as NSDate),
        animation: .default)
    private var todaysActivities: FetchedResults<Item>

    var body: some View {
        NavigationView {
            VStack {
                if todaysActivities.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No activities for today")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Add your first activity to get started!")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Button("Add Activity") {
                            showingAddActivity = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(todaysActivities) { activity in
                            HStack {
                                Button(action: {
                                    toggleActivityCompletion(activity)
                                }) {
                                    Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(activity.isCompleted ? .green : .gray)
                                        .font(.title2)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(activity.activityDescription ?? "Unknown Activity")
                                    .strikethrough(activity.isCompleted)
                                    .foregroundColor(activity.isCompleted ? .secondary : .primary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteActivities)
                    }
                }
            }
            .navigationTitle("Today's Activities")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddActivity = true
                    }) {
                        Label("Add Activity", systemImage: "plus")
                    }
                }
                
                if !todaysActivities.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                AddActivityView(isPresented: $showingAddActivity)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func toggleActivityCompletion(_ activity: Item) {
        withAnimation {
            activity.isCompleted.toggle()
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteActivities(offsets: IndexSet) {
        withAnimation {
            offsets.map { todaysActivities[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct AddActivityView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    @State private var activityText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add New Activity")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextField("What do you want to do?", text: $activityText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .submitLabel(.done)
                    .onSubmit {
                        if !activityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            addActivity()
                        }
                    }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addActivity()
                    }
                    .disabled(activityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func addActivity() {
        let trimmedText = activityText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else { return }
        
        withAnimation {
            let newActivity = Item(context: viewContext)
            newActivity.activityDescription = trimmedText
            newActivity.isCompleted = false
            newActivity.createdDate = Date()

            do {
                try viewContext.save()
                isPresented = false
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
