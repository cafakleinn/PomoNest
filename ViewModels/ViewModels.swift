//
//  ViewModels.swift
//  PomoNest
//
//  Created by Trae AI on 2025-03-27.
//

import Foundation
import SwiftUI
import SwiftData
import Combine
import EventKit

@Observable
class SemesterViewModel {
    private var modelContext: ModelContext
    var semesters: [Semester] = []
    var currentSemester: Semester?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchSemesters()
    }
    
    func fetchSemesters() {
        let descriptor = FetchDescriptor<Semester>(sortBy: [SortDescriptor(\Semester.startDate, order: .reverse)])
        do {
            semesters = try modelContext.fetch(descriptor)
            if let first = semesters.first, currentSemester == nil {
                currentSemester = first
            }
        } catch {
            print("Error fetching semesters: \(error)")
        }
    }
    
    func addSemester(name: String, startDate: Date, endDate: Date) {
        let semester = Semester(name: name, startDate: startDate, endDate: endDate)
        modelContext.insert(semester)
        saveContext()
        fetchSemesters()
        currentSemester = semester
    }
    
    func deleteSemester(_ semester: Semester) {
        modelContext.delete(semester)
        saveContext()
        fetchSemesters()
        if currentSemester == semester {
            currentSemester = semesters.first
        }
    }
    
    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

@Observable
class CourseViewModel {
    private var modelContext: ModelContext
    var courses: [Course] = []
    var semester: Semester?
    
    init(modelContext: ModelContext, semester: Semester? = nil) {
        self.modelContext = modelContext
        self.semester = semester
        if let semester = semester {
            fetchCourses(for: semester)
        }
    }
    
    func fetchCourses(for semester: Semester) {
        self.semester = semester
        courses = semester.courses
    }
    
    func addCourse(code: String, name: String, creditHours: Int = 3) {
        guard let semester = semester else { return }
        
        let course = Course(code: code, name: name, creditHours: creditHours)
        course.semester = semester
        semester.courses.append(course)
        modelContext.insert(course)
        saveContext()
        fetchCourses(for: semester)
    }
    
    func deleteCourse(_ course: Course) {
        guard let semester = semester else { return }
        
        if let index = semester.courses.firstIndex(where: { $0.id == course.id }) {
            semester.courses.remove(at: index)
        }
        modelContext.delete(course)
        saveContext()
        fetchCourses(for: semester)
    }
    
    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

@Observable
class GradeCalculatorViewModel {
    private var modelContext: ModelContext
    var course: Course?
    
    init(modelContext: ModelContext, course: Course? = nil) {
        self.modelContext = modelContext
        self.course = course
    }
    
    func addGradingComponent(name: String, weight: Double, earnedPoints: Double? = nil, totalPoints: Double = 100.0) {
        guard let course = course else { return }
        
        let component = GradingComponent(name: name, weight: weight, earnedPoints: earnedPoints, totalPoints: totalPoints)
        component.course = course
        course.gradingComponents.append(component)
        modelContext.insert(component)
        saveContext()
    }
    
    func updateGradingComponent(_ component: GradingComponent, earnedPoints: Double?) {
        component.earnedPoints = earnedPoints
        saveContext()
    }
    
    func deleteGradingComponent(_ component: GradingComponent) {
        guard let course = course, let index = course.gradingComponents.firstIndex(where: { $0.id == component.id }) else { return }
        
        course.gradingComponents.remove(at: index)
        modelContext.delete(component)
        saveContext()
    }
    
    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

@Observable
class AssignmentViewModel {
    private var modelContext: ModelContext
    var assignments: [Assignment] = []
    var course: Course?
    var semester: Semester?
    
    init(modelContext: ModelContext, course: Course? = nil, semester: Semester? = nil) {
        self.modelContext = modelContext
        self.course = course
        self.semester = semester
        
        if let course = course {
            fetchAssignments(for: course)
        } else if let semester = semester {
            fetchAllAssignments(for: semester)
        }
    }
    
    func fetchAssignments(for course: Course) {
        self.course = course
        self.semester = nil
        assignments = course.assignments
    }
    
    func fetchAllAssignments(for semester: Semester) {
        self.semester = semester
        self.course = nil
        assignments = semester.courses.flatMap { $0.assignments }
    }
    
    func addAssignment(name: String, dueDate: Date, weight: Double? = nil, notes: String = "") {
        guard let course = course else { return }
        
        let assignment = Assignment(name: name, dueDate: dueDate, weight: weight, notes: notes)
        assignment.course = course
        course.assignments.append(assignment)
        modelContext.insert(assignment)
        saveContext()
        fetchAssignments(for: course)
    }
    
    func toggleAssignmentCompletion(_ assignment: Assignment) {
        assignment.isCompleted.toggle()
        saveContext()
    }
    
    func updateAssignment(_ assignment: Assignment, name: String, dueDate: Date, weight: Double?, notes: String) {
        assignment.name = name
        assignment.dueDate = dueDate
        assignment.weight = weight
        assignment.notes = notes
        saveContext()
    }
    
    func deleteAssignment(_ assignment: Assignment) {
        guard let course = assignment.course, let index = course.assignments.firstIndex(where: { $0.id == assignment.id }) else { return }
        
        course.assignments.remove(at: index)
        modelContext.delete(assignment)
        saveContext()
        
        if let viewCourse = self.course {
            fetchAssignments(for: viewCourse)
        } else if let semester = self.semester {
            fetchAllAssignments(for: semester)
        }
    }
    
    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

@Observable
class TodoViewModel {
    private var modelContext: ModelContext
    var todoItems: [TodoItem] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchTodoItems()
    }
    
    func fetchTodoItems() {
        let descriptor = FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\TodoItem.dueDate, order: .forward), SortDescriptor(\TodoItem.createdAt, order: .forward)])
        do {
            todoItems = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching todo items: \(error)")
        }
    }
    
    func addTodoItem(title: String, dueDate: Date? = nil, notes: String = "") {
        let todoItem = TodoItem(title: title, dueDate: dueDate, notes: notes)
        modelContext.insert(todoItem)
        saveContext()
        fetchTodoItems()
    }
    
    func toggleTodoCompletion(_ todoItem: TodoItem) {
        todoItem.isCompleted.toggle()
        saveContext()
    }
    
    func updateTodoItem(_ todoItem: TodoItem, title: String, dueDate: Date?, notes: String) {
        todoItem.title = title
        todoItem.dueDate = dueDate
        todoItem.notes = notes
        saveContext()
    }
    
    func deleteTodoItem(_ todoItem: TodoItem) {
        modelContext.delete(todoItem)
        saveContext()
        fetchTodoItems()
    }
    
    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

@Observable
class CalendarViewModel {
    private let eventStore = EKEventStore()
    var events: [EKEvent] = []
    var assignments: [Assignment] = []
    var todoItems: [TodoItem] = []
    var hasCalendarAccess = false
    
    init() {
        requestCalendarAccess()
    }
    
    func requestCalendarAccess() {
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                self.hasCalendarAccess = granted
                if granted {
                    self.fetchEvents()
                } else if let error = error {
                    print("Calendar access denied: \(error)")
                }
            }
        }
    }
    
    func fetchEvents(startDate: Date = Date().startOfDay, endDate: Date = Date().addingTimeInterval(60*60*24*30)) {
        guard hasCalendarAccess else { return }
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        events = eventStore.events(matching: predicate)
    }
    
    func addAssignmentToCalendar(_ assignment: Assignment) {
        guard hasCalendarAccess, let course = assignment.course else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = "\(course.code): \(assignment.name)"
        event.notes = assignment.notes
        event.startDate = assignment.dueDate
        event.endDate = assignment.dueDate.addingTimeInterval(3600) // 1 hour duration
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            fetchEvents()
        } catch {
            print("Error saving event: \(error)")
        }
    }
    
    func addTodoToCalendar(_ todoItem: TodoItem) {
        guard hasCalendarAccess, let dueDate = todoItem.dueDate else { return }
        
        let event = EKEvent(eventStore: eventStore)
        event.title = "Todo: \(todoItem.title)"
        event.notes = todoItem.notes
        event.startDate = dueDate
        event.endDate = dueDate.addingTimeInterval(3600) // 1 hour duration
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            fetchEvents()
        } catch {
            print("Error saving event: \(error)")
        }
    }
}

@Observable
class PomodoroViewModel {
    enum TimerState {
        case stopped
        case running
        case paused
    }
    
    enum TimerMode {
        case work
        case shortBreak
        case longBreak
    }
    
    var timerState: TimerState = .stopped
    var timerMode: TimerMode = .work
    var remainingSeconds: Int = 25 * 60 // 25 minutes
    var workDuration: Int = 25 * 60 // 25 minutes
    var shortBreakDuration: Int = 5 * 60 // 5 minutes
    var longBreakDuration: Int = 15 * 60 // 15 minutes
    var completedWorkSessions: Int = 0
    var sessionsUntilLongBreak: Int = 4
    
    private var cancellable: AnyCancellable?
    
    func startTimer() {
        guard timerState != .running else { return }
        
        timerState = .running
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.remainingSeconds > 0 else {
                    self?.timerCompleted()
                    return
                }
                self.remainingSeconds -= 1
            }
    }
    
    func pauseTimer() {
        timerState = .paused
        cancellable?.cancel()
    }
    
    func resetTimer() {
        timerState = .stopped
        cancellable?.cancel()
        setTimerDuration()
    }
    
    func skipToNextSession() {
        timerCompleted()
    }
    
    private func timerCompleted() {
        cancellable?.cancel()
        
        switch timerMode {
        case .work:
            completedWorkSessions += 1
            if completedWorkSessions % sessionsUntilLongBreak == 0 {
                timerMode = .longBreak
            } else {
                timerMode = .shortBreak
            }
        case .shortBreak, .longBreak:
            timerMode = .work
        }
        
        setTimerDuration()
        startTimer()
    }
    
    private func setTimerDuration() {
        switch timerMode {
        case .work:
            remainingSeconds = workDuration
        case .shortBreak:
            remainingSeconds = shortBreakDuration
        case .longBreak:
            remainingSeconds = longBreakDuration
        }
    }
    
    func formattedTime() -> String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
}