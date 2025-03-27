//
//  AssignmentTrackerView.swift
//  PomoNest
//
//  Created by Trae AI on 2025-03-27.
//

import SwiftUI
import SwiftData

struct AssignmentTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var semesterViewModel: SemesterViewModel
    @State private var assignmentViewModel: AssignmentViewModel
    @State private var showingAddAssignmentSheet = false
    @State private var selectedCourse: Course?
    
    init() {
        let context = ModelContext(try! ModelContainer(for: Semester.self, Course.self, Assignment.self, TodoItem.self).mainContext)
        _semesterViewModel = State(initialValue: SemesterViewModel(modelContext: context))
        _assignmentViewModel = State(initialValue: AssignmentViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if let currentSemester = semesterViewModel.currentSemester {
                    SemesterAssignmentView(semester: currentSemester, assignmentViewModel: assignmentViewModel, selectedCourse: $selectedCourse)
                } else if semesterViewModel.semesters.isEmpty {
                    ContentUnavailableView {
                        Label("No Semesters", systemImage: "calendar.badge.exclamationmark")
                    } description: {
                        Text("Add a semester in the Courses tab to get started")
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Semester Selected", systemImage: "calendar.badge.exclamationmark")
                    } description: {
                        Text("Select a semester in the Courses tab")
                    }
                }
            }
            .navigationTitle("Assignment Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddAssignmentSheet = true
                    }) {
                        Label("Add Assignment", systemImage: "plus")
                    }
                    .disabled(selectedCourse == nil)
                }
            }
            .sheet(isPresented: $showingAddAssignmentSheet) {
                if let course = selectedCourse {
                    AddAssignmentView(
                        viewModel: AssignmentViewModel(modelContext: modelContext, course: course),
                        isPresented: $showingAddAssignmentSheet
                    )
                }
            }
            .onAppear {
                semesterViewModel.fetchSemesters()
                if let semester = semesterViewModel.currentSemester {
                    assignmentViewModel.fetchAllAssignments(for: semester)
                }
            }
        }
    }
}

struct SemesterAssignmentView: View {
    let semester: Semester
    @ObservedObject var assignmentViewModel: AssignmentViewModel
    @Binding var selectedCourse: Course?
    @State private var showAllAssignments = true
    
    var body: some View {
        VStack {
            // Course Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button(action: {
                        showAllAssignments = true
                        selectedCourse = nil
                        assignmentViewModel.fetchAllAssignments(for: semester)
                    }) {
                        Text("All Courses")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(showAllAssignments ? Color.accentColor : Color(.systemGray5))
                            .foregroundColor(showAllAssignments ? .white : .primary)
                            .cornerRadius(8)
                    }
                    
                    ForEach(semester.courses) { course in
                        Button(action: {
                            showAllAssignments = false
                            selectedCourse = course
                            assignmentViewModel.fetchAssignments(for: course)
                        }) {
                            Text(course.code)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(!showAllAssignments && selectedCourse?.id == course.id ? Color.accentColor : Color(.systemGray5))
                                .foregroundColor(!showAllAssignments && selectedCourse?.id == course.id ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Assignment Table
            AssignmentTableView(assignments: assignmentViewModel.assignments, viewModel: assignmentViewModel)
        }
    }
}

struct AssignmentTableView: View {
    let assignments: [Assignment]
    @ObservedObject var viewModel: AssignmentViewModel
    @State private var sortOrder: SortOrder = .dueDate
    @State private var showCompleted = true
    
    enum SortOrder {
        case dueDate, course, name
    }
    
    var sortedAssignments: [Assignment] {
        let filteredAssignments = showCompleted ? assignments : assignments.filter { !$0.isCompleted }
        
        switch sortOrder {
        case .dueDate:
            return filteredAssignments.sorted { $0.dueDate < $1.dueDate }
        case .course:
            return filteredAssignments.sorted { ($0.course?.code ?? "") < ($1.course?.code ?? "") }
        case .name:
            return filteredAssignments.sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        VStack {
            // Controls
            HStack {
                Picker("Sort By", selection: $sortOrder) {
                    Text("Due Date").tag(SortOrder.dueDate)
                    Text("Course").tag(SortOrder.course)
                    Text("Name").tag(SortOrder.name)
                }
                .pickerStyle(.menu)
                
                Spacer()
                
                Toggle("Show Completed", isOn: $showCompleted)
            }
            .padding(.horizontal)
            
            // Table Header
            HStack {
                Text("Status")
                    .frame(width: 50, alignment: .leading)
                Text("Assignment")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Course")
                    .frame(width: 80, alignment: .leading)
                Text("Due Date")
                    .frame(width: 100, alignment: .trailing)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Table Content
            if sortedAssignments.isEmpty {
                ContentUnavailableView {
                    Label("No Assignments", systemImage: "list.clipboard")
                } description: {
                    Text("Add your first assignment to get started")
                }
                .padding(.top, 40)
            } else {
                List {
                    ForEach(sortedAssignments) { assignment in
                        AssignmentTableRow(assignment: assignment, viewModel: viewModel)
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct AssignmentTableRow: View {
    let assignment: Assignment
    @ObservedObject var viewModel: AssignmentViewModel
    @State private var showingDetailSheet = false
    
    var body: some View {
        Button(action: {
            showingDetailSheet = true
        }) {
            HStack {
                Button(action: {
                    viewModel.toggleAssignmentCompletion(assignment)
                }) {
                    Image(systemName: assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(assignment.isCompleted ? .green : .primary)
                }
                .frame(width: 50, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(assignment.name)
                        .fontWeight(.medium)
                        .strikethrough(assignment.isCompleted)
                        .foregroundColor(assignment.isCompleted ? .secondary : .primary)
                    
                    if !assignment.notes.isEmpty {
                        Text(assignment.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(assignment.course?.code ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
                
                Text(formatDate(assignment.dueDate))
                    .font(.subheadline)
                    .foregroundColor(isPastDue(assignment.dueDate) && !assignment.isCompleted ? .red : .secondary)
                    .frame(width: 100, alignment: .trailing)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .sheet(isPresented: $showingDetailSheet) {
            AssignmentDetailView(assignment: assignment, viewModel: viewModel, isPresented: $showingDetailSheet)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func isPastDue(_ date: Date) -> Bool {
        return date < Date()
    }
}

struct AssignmentDetailView: View {
    let assignment: Assignment
    @ObservedObject var viewModel: AssignmentViewModel
    @Binding var isPresented: Bool
    @State private var name: String
    @State private var dueDate: Date
    @State private var notes: String
    @State private var isCompleted: Bool
    @State private var weight: Double?
    @State private var hasWeight: Bool
    
    init(assignment: Assignment, viewModel: AssignmentViewModel, isPresented: Binding<Bool>) {
        self.assignment = assignment
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._name = State(initialValue: assignment.name)
        self._dueDate = State(initialValue: assignment.dueDate)
        self._notes = State(initialValue: assignment.notes)
        self._isCompleted = State(initialValue: assignment.isCompleted)
        self._weight = State(initialValue: assignment.weight)
        self._hasWeight = State(initialValue: assignment.weight != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Assignment Details")) {
                    TextField("Name", text: $name)
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Toggle("Completed", isOn: $isCompleted)
                    
                    Toggle("Has Weight", isOn: $hasWeight)
                    
                    if hasWeight {
                        HStack {
                            Text("Weight: \(Int(weight ?? 10))%")
                            Spacer()
                            Slider(value: Binding(
                                get: { weight ?? 10 },
                                set: { weight = $0 }
                            ), in: 1...100, step: 1)
                            .frame(width: 200)
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                if let course = assignment.course {
                    Section(header: Text("Course")) {
                        Text("\(course.code): \(course.name)")
                    }
                }
                
                Section {
                    Button("Delete Assignment", role: .destructive) {
                        viewModel.deleteAssignment(assignment)
                        isPresented = false
                    }
                }
            }
            .navigationTitle("Edit Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateAssignment(
                            assignment,
                            name: name,
                            dueDate: dueDate,
                            weight: hasWeight ? weight : nil,
                            notes: notes
                        )
                        assignment.isCompleted = isCompleted
                        isPresented = false
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AssignmentTrackerView()
        .modelContainer(for: [Semester.self, Course.self, Assignment.self, TodoItem.self], inMemory: true)
}