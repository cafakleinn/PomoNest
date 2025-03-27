//
//  CoursesView.swift
//  PomoNest
//
//  Created by Trae AI on 2025-03-27.
//

import SwiftUI
import SwiftData

struct CoursesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var semesterViewModel: SemesterViewModel
    @State private var courseViewModel: CourseViewModel
    @State private var showingAddCourseSheet = false
    @State private var showingAddSemesterSheet = false
    
    init() {
        let context = ModelContext(try! ModelContainer(for: Semester.self, Course.self, Assignment.self, TodoItem.self).mainContext)
        _semesterViewModel = State(initialValue: SemesterViewModel(modelContext: context))
        _courseViewModel = State(initialValue: CourseViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if semesterViewModel.semesters.isEmpty {
                    ContentUnavailableView {
                        Label("No Semesters", systemImage: "calendar.badge.exclamationmark")
                    } description: {
                        Text("Add your first semester to get started")
                    } actions: {
                        Button("Add Semester") {
                            showingAddSemesterSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    SemesterPickerView(semesterViewModel: semesterViewModel, courseViewModel: courseViewModel)
                    
                    if let selectedSemester = semesterViewModel.currentSemester {
                        CourseListView(courseViewModel: courseViewModel, semester: selectedSemester)
                    }
                }
            }
            .navigationTitle("Courses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingAddCourseSheet = true
                        }) {
                            Label("Add Course", systemImage: "book.fill")
                        }
                        .disabled(semesterViewModel.currentSemester == nil)
                        
                        Button(action: {
                            showingAddSemesterSheet = true
                        }) {
                            Label("Add Semester", systemImage: "calendar.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCourseSheet) {
                AddCourseView(courseViewModel: courseViewModel, isPresented: $showingAddCourseSheet)
            }
            .sheet(isPresented: $showingAddSemesterSheet) {
                AddSemesterView(isPresented: $showingAddSemesterSheet)
            }
        }
    }
}

struct SemesterPickerView: View {
    @ObservedObject var semesterViewModel: SemesterViewModel
    @ObservedObject var courseViewModel: CourseViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(semesterViewModel.semesters) { semester in
                    SemesterCard(semester: semester, isSelected: semester.id == semesterViewModel.currentSemester?.id)
                        .onTapGesture {
                            semesterViewModel.currentSemester = semester
                            courseViewModel.fetchCourses(for: semester)
                        }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
    }
}

struct SemesterCard: View {
    let semester: Semester
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(semester.name)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .primary)
            
            Text("\(formatDate(semester.startDate)) - \(formatDate(semester.endDate))")
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            
            Text("GPA: \(String(format: "%.2f", semester.gpa))")
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
        }
        .padding()
        .frame(width: 180)
        .background(isSelected ? Color.accentColor : Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: isSelected ? 3 : 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

struct CourseListView: View {
    @ObservedObject var courseViewModel: CourseViewModel
    let semester: Semester
    
    var body: some View {
        List {
            if courseViewModel.courses.isEmpty {
                Text("No courses added yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(courseViewModel.courses) { course in
                    NavigationLink(destination: CourseDetailView(course: course)) {
                        CourseRow(course: course)
                    }
                }
                .onDelete(perform: deleteCourses)
            }
        }
    }
    
    private func deleteCourses(at offsets: IndexSet) {
        for index in offsets {
            courseViewModel.deleteCourse(courseViewModel.courses[index])
        }
    }
}

struct CourseRow: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(course.code)
                .font(.headline)
            
            Text(course.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("GPA: \(String(format: "%.2f", course.gpa))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(course.assignments.count) Assignments")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CourseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let course: Course
    @State private var gradeCalculatorViewModel: GradeCalculatorViewModel
    @State private var assignmentViewModel: AssignmentViewModel
    @State private var showingAddGradingComponentSheet = false
    @State private var showingAddAssignmentSheet = false
    @State private var selectedTab = 0
    
    init(course: Course) {
        self.course = course
        let context = ModelContext(try! ModelContainer(for: Semester.self, Course.self, Assignment.self, TodoItem.self).mainContext)
        _gradeCalculatorViewModel = State(initialValue: GradeCalculatorViewModel(modelContext: context, course: course))
        _assignmentViewModel = State(initialValue: AssignmentViewModel(modelContext: context, course: course))
    }
    
    var body: some View {
        VStack {
            Picker("View", selection: $selectedTab) {
                Text("Grade Calculator").tag(0)
                Text("Assignments").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            TabView(selection: $selectedTab) {
                GradeCalculatorView(viewModel: gradeCalculatorViewModel)
                    .tag(0)
                
                AssignmentsView(viewModel: assignmentViewModel)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("\(course.code): \(course.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingAddGradingComponentSheet = true
                    }) {
                        Label("Add Grading Component", systemImage: "percent")
                    }
                    
                    Button(action: {
                        showingAddAssignmentSheet = true
                    }) {
                        Label("Add Assignment", systemImage: "list.clipboard")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddGradingComponentSheet) {
            AddGradingComponentView(viewModel: gradeCalculatorViewModel, isPresented: $showingAddGradingComponentSheet)
        }
        .sheet(isPresented: $showingAddAssignmentSheet) {
            AddAssignmentView(viewModel: assignmentViewModel, isPresented: $showingAddAssignmentSheet)
        }
    }
}

struct GradeCalculatorView: View {
    @ObservedObject var viewModel: GradeCalculatorViewModel
    
    var body: some View {
        List {
            if let course = viewModel.course {
                Section(header: Text("Course GPA")) {
                    Text(String(format: "%.2f", course.gpa))
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                
                Section(header: Text("Grading Components")) {
                    if course.gradingComponents.isEmpty {
                        Text("No grading components added yet")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(course.gradingComponents) { component in
                            GradingComponentRow(component: component, viewModel: viewModel)
                        }
                    }
                }
            }
        }
    }
}

struct GradingComponentRow: View {
    let component: GradingComponent
    @ObservedObject var viewModel: GradeCalculatorViewModel
    @State private var earnedPoints: String = ""
    
    init(component: GradingComponent, viewModel: GradeCalculatorViewModel) {
        self.component = component
        self.viewModel = viewModel
        if let points = component.earnedPoints {
            _earnedPoints = State(initialValue: String(format: "%.1f", points))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(component.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(component.weight))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Earned Points:")
                    .font(.subheadline)
                
                TextField("Points", text: $earnedPoints)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: earnedPoints) { _, newValue in
                        if let points = Double(newValue) {
                            viewModel.updateGradingComponent(component, earnedPoints: points)
                        }
                    }
                
                Text("/ \(Int(component.totalPoints))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let earnedPoints = component.earnedPoints {
                    Text("\(Int(component.percentage))%")
                        .font(.headline)
                        .foregroundColor(component.percentage >= 60 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AssignmentsView: View {
    @ObservedObject var viewModel: AssignmentViewModel
    
    var body: some View {
        List {
            if viewModel.assignments.isEmpty {
                Text("No assignments added yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(viewModel.assignments) { assignment in
                    AssignmentRow(assignment: assignment, viewModel: viewModel)
                }
                .onDelete(perform: deleteAssignments)
            }
        }
    }
    
    private func deleteAssignments(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteAssignment(viewModel.assignments[index])
        }
    }
}

struct AssignmentRow: View {
    let assignment: Assignment
    @ObservedObject var viewModel: AssignmentViewModel
    
    var body: some View {
        HStack {
            Button(action: {
                viewModel.toggleAssignmentCompletion(assignment)
            }) {
                Image(systemName: assignment.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(assignment.isCompleted ? .green : .primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.name)
                    .strikethrough(assignment.isCompleted)
                    .foregroundColor(assignment.isCompleted ? .secondary : .primary)
                
                HStack {
                    Text(formatDate(assignment.dueDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let weight = assignment.weight {
                        Text("Weight: \(Int(weight))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !assignment.notes.isEmpty {
                    Text(assignment.notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct AddCourseView: View {
    @ObservedObject var courseViewModel: CourseViewModel
    @Binding var isPresented: Bool
    @State private var code = ""
    @State private var name = ""
    @State private var creditHours = 3
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Course Details")) {
                    TextField("Course Code", text: $code)
                    TextField("Course Name", text: $name)
                    
                    Stepper("Credit Hours: \(creditHours)", value: $creditHours, in: 1...6)
                }
            }
            .navigationTitle("Add Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        courseViewModel.addCourse(code: code, name: name, creditHours: creditHours)
                        isPresented = false
                    }
                    .disabled(code.isEmpty || name.isEmpty)
                }
            }
        }
    }
}

struct AddGradingComponentView: View {
    @ObservedObject var viewModel: GradeCalculatorViewModel
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var weight = 20.0
    @State private var totalPoints = 100.0
    @State private var earnedPoints = ""
    @State private var hasEarnedPoints = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Component Details")) {
                    TextField("Name", text: $name)
                    
                    HStack {
                        Text("Weight: \(Int(weight))%")
                        Spacer()
                        Slider(value: $weight, in: 1...100, step: 1)
                            .frame(width: 200)
                    }
                    
                    TextField("Total Points", value: $totalPoints, format: .number)
                        .keyboardType(.decimalPad)
                    
                    Toggle("Add Earned Points", isOn: $hasEarnedPoints)
                    
                    if hasEarnedPoints {
                        TextField("Earned Points", text: $earnedPoints)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Add Grading Component")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let earnedPointsValue = hasEarnedPoints ? Double(earnedPoints) : nil
                        viewModel.addGradingComponent(
                            name: name,
                            weight: weight,
                            earnedPoints: earnedPointsValue,
                            totalPoints: totalPoints
                        )
                        isPresented = false
                    }
                    .disabled(name.isEmpty || (hasEarnedPoints && earnedPoints.isEmpty))
                }
            }
        }
    }
}

struct AddAssignmentView: View {
    @ObservedObject var viewModel: AssignmentViewModel
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var dueDate = Date()
    @State private var notes = ""
    @State private var hasWeight = false
    @State private var weight = 10.0
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Assignment Details")) {
                    TextField("Name", text: $name)
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Toggle("Has Weight", isOn: $hasWeight)
                    
                    if hasWeight {
                        HStack {
                            Text("Weight: \(Int(weight))%")
                            Spacer()
                            Slider(value: $weight, in: 1...100, step: 1)
                                .frame(width: 200)
                        }
                    }
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("Add Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addAssignment(
                            name: name,
                            dueDate: dueDate,
                            weight: hasWeight ? weight : nil,
                            notes: notes
                        )
                        isPresented = false
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    CoursesView()
        .modelContainer(for: [Semester.self, Course.self, Assignment.self, TodoItem.self], inMemory: true)
}