//
//  HomeView.swift
//  PomoNest
//
//  Created by Trae AI on 2025-03-27.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var semesterViewModel: SemesterViewModel
    @State private var todoViewModel: TodoViewModel
    @State private var showingAddTodoSheet = false
    @State private var newTodoTitle = ""
    @State private var newTodoDueDate: Date? = nil
    @State private var newTodoNotes = ""
    
    init() {
        let context = ModelContext(try! ModelContainer(for: Semester.self, Course.self, Assignment.self, TodoItem.self).mainContext)
        _semesterViewModel = State(initialValue: SemesterViewModel(modelContext: context))
        _todoViewModel = State(initialValue: TodoViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let currentSemester = semesterViewModel.currentSemester {
                        SemesterSummaryView(semester: currentSemester)
                    } else {
                        WelcomeView()
                    }
                    
                    TodoListView(todoViewModel: todoViewModel)
                }
                .padding()
            }
            .navigationTitle("PomoNest")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTodoSheet = true
                    }) {
                        Label("Add Todo", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTodoSheet) {
                AddTodoView(todoViewModel: todoViewModel, isPresented: $showingAddTodoSheet)
            }
        }
    }
}

struct SemesterSummaryView: View {
    let semester: Semester
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(semester.name)
                .font(.title)
                .fontWeight(.bold)
            
            HStack {
                Text("GPA: \(String(format: "%.2f", semester.gpa))")
                    .font(.headline)
                
                Spacer()
                
                Text("\(semester.courses.count) Courses")
                    .font(.subheadline)
            }
            
            Text("\(formatDate(semester.startDate)) - \(formatDate(semester.endDate))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct WelcomeView: View {
    @State private var showingAddSemesterSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to PomoNest!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Get started by adding your first semester")
                .multilineTextAlignment(.center)
            
            Button("Add Semester") {
                showingAddSemesterSheet = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .sheet(isPresented: $showingAddSemesterSheet) {
            AddSemesterView(isPresented: $showingAddSemesterSheet)
        }
    }
}

struct TodoListView: View {
    @ObservedObject var todoViewModel: TodoViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("To-Do List")
                .font(.title2)
                .fontWeight(.bold)
            
            if todoViewModel.todoItems.isEmpty {
                Text("No tasks yet. Add your first task!")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(todoViewModel.todoItems) { todoItem in
                    TodoItemRow(todoItem: todoItem, todoViewModel: todoViewModel)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct TodoItemRow: View {
    let todoItem: TodoItem
    @ObservedObject var todoViewModel: TodoViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                todoViewModel.toggleTodoCompletion(todoItem)
            }) {
                Image(systemName: todoItem.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(todoItem.isCompleted ? .green : .primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(todoItem.title)
                    .strikethrough(todoItem.isCompleted)
                    .foregroundColor(todoItem.isCompleted ? .secondary : .primary)
                
                if let dueDate = todoItem.dueDate {
                    Text(formatDate(dueDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                todoViewModel.deleteTodoItem(todoItem)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct AddTodoView: View {
    @ObservedObject var todoViewModel: TodoViewModel
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var notes = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    
                    Toggle("Has Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        todoViewModel.addTodoItem(
                            title: title,
                            dueDate: hasDueDate ? dueDate : nil,
                            notes: notes
                        )
                        isPresented = false
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct AddSemesterView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Semester Details")) {
                    TextField("Semester Name", text: $name)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }
            .navigationTitle("Add Semester")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let viewModel = SemesterViewModel(modelContext: modelContext)
                        viewModel.addSemester(name: name, startDate: startDate, endDate: endDate)
                        isPresented = false
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Semester.self, Course.self, Assignment.self, TodoItem.self], inMemory: true)
}