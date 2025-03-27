//
//  CalendarView.swift
//  PomoNest
//
//  Created by Trae AI on 2025-03-27.
//

import SwiftUI
import SwiftData
import EventKit

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var calendarViewModel = CalendarViewModel()
    @State private var semesterViewModel: SemesterViewModel
    @State private var todoViewModel: TodoViewModel
    @State private var selectedDate = Date()
    @State private var calendarMode: CalendarMode = .month
    
    enum CalendarMode {
        case month, week
    }
    
    init() {
        let context = ModelContext(try! ModelContainer(for: Semester.self, Course.self, Assignment.self, TodoItem.self).mainContext)
        _semesterViewModel = State(initialValue: SemesterViewModel(modelContext: context))
        _todoViewModel = State(initialValue: TodoViewModel(modelContext: context))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Calendar Mode Picker
                Picker("Calendar Mode", selection: $calendarMode) {
                    Text("Month").tag(CalendarMode.month)
                    Text("Week").tag(CalendarMode.week)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Calendar Header
                HStack {
                    Button(action: {
                        if calendarMode == .month {
                            selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                        } else {
                            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate) ?? selectedDate
                        }
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    
                    Spacer()
                    
                    Text(formatDateHeader(selectedDate, mode: calendarMode))
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        if calendarMode == .month {
                            selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                        } else {
                            selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate) ?? selectedDate
                        }
                    }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)
                
                // Calendar Grid
                if calendarMode == .month {
                    MonthCalendarView(selectedDate: $selectedDate, calendarViewModel: calendarViewModel, semesterViewModel: semesterViewModel, todoViewModel: todoViewModel)
                } else {
                    WeekCalendarView(selectedDate: $selectedDate, calendarViewModel: calendarViewModel, semesterViewModel: semesterViewModel, todoViewModel: todoViewModel)
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        selectedDate = Date()
                    }) {
                        Text("Today")
                    }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        semesterViewModel.fetchSemesters()
        todoViewModel.fetchTodoItems()
        
        if let currentSemester = semesterViewModel.currentSemester {
            // Load assignments from current semester
            calendarViewModel.assignments = currentSemester.courses.flatMap { $0.assignments }
        }
        
        // Load todo items
        calendarViewModel.todoItems = todoViewModel.todoItems
        
        // Fetch calendar events
        calendarViewModel.fetchEvents()
    }
    
    private func formatDateHeader(_ date: Date, mode: CalendarMode) -> String {
        let formatter = DateFormatter()
        
        if mode == .month {
            formatter.dateFormat = "MMMM yyyy"
        } else {
            let calendar = Calendar.current
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? date
            
            formatter.dateFormat = "MMM d"
            let startString = formatter.string(from: startOfWeek)
            let endString = formatter.string(from: endOfWeek)
            
            return "\(startString) - \(endString), \(Calendar.current.component(.year, from: date))"
        }
        
        return formatter.string(from: date)
    }
}

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    @ObservedObject var calendarViewModel: CalendarViewModel
    @ObservedObject var semesterViewModel: SemesterViewModel
    @ObservedObject var todoViewModel: TodoViewModel
    @State private var selectedDayEvents: [CalendarEventItem] = []
    @State private var showingEventSheet = false
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 10) {
            // Days of week header
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        let events = eventsForDate(date)
                        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                        let isToday = calendar.isDateInToday(date)
                        
                        Button(action: {
                            selectedDate = date
                            selectedDayEvents = events
                            showingEventSheet = !events.isEmpty
                        }) {
                            VStack {
                                Text("\(calendar.component(.day, from: date))")
                                    .font(isToday ? .headline : .body)
                                    .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
                                
                                if !events.isEmpty {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? Color.blue : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 8)
            
            // Events for selected date
            VStack(alignment: .leading, spacing: 10) {
                Text("Events for \(formatDate(selectedDate))")
                    .font(.headline)
                    .padding(.top)
                
                if eventsForDate(selectedDate).isEmpty {
                    Text("No events for this day")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(eventsForDate(selectedDate)) { event in
                                CalendarEventRow(event: event)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingEventSheet) {
            EventListView(events: selectedDayEvents, date: selectedDate)
        }
    }
    
    private func daysInMonth() -> [Date?] {
        var days = [Date?]()
        
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        
        // Add empty days for the start of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days in the month
        for day in 1...calendar.component(.day, from: monthEnd) {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        
        // Add empty days to complete the last week if needed
        let remainingDays = 7 - (days.count % 7)
        if remainingDays < 7 {
            for _ in 0..<remainingDays {
                days.append(nil)
            }
        }
        
        return days
    }
    
    private func eventsForDate(_ date: Date) -> [CalendarEventItem] {
        var events = [CalendarEventItem]()
        
        // Add assignments due on this date
        for assignment in calendarViewModel.assignments {
            if calendar.isDate(assignment.dueDate, inSameDayAs: date) {
                let courseCode = assignment.course?.code ?? ""
                events.append(CalendarEventItem(
                    id: UUID(),
                    title: "\(courseCode): \(assignment.name)",
                    date: assignment.dueDate,
                    type: .assignment,
                    notes: assignment.notes,
                    isCompleted: assignment.isCompleted
                ))
            }
        }
        
        // Add todo items due on this date
        for todoItem in calendarViewModel.todoItems {
            if let dueDate = todoItem.dueDate, calendar.isDate(dueDate, inSameDayAs: date) {
                events.append(CalendarEventItem(
                    id: UUID(),
                    title: todoItem.title,
                    date: dueDate,
                    type: .todo,
                    notes: todoItem.notes,
                    isCompleted: todoItem.isCompleted
                ))
            }
        }
        
        // Add calendar events on this date
        for event in calendarViewModel.events {
            if calendar.isDate(event.startDate, inSameDayAs: date) {
                events.append(CalendarEventItem(
                    id: UUID(),
                    title: event.title,
                    date: event.startDate,
                    type: .calendarEvent,
                    notes: event.notes ?? "",
                    isCompleted: false
                ))
            }
        }
        
        return events.sorted { $0.date < $1.date }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    @ObservedObject var calendarViewModel: CalendarViewModel
    @ObservedObject var semesterViewModel: SemesterViewModel
    @ObservedObject var todoViewModel: TodoViewModel
    @State private var selectedDayEvents: [CalendarEventItem] = []
    @State private var showingEventSheet = false
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 10) {
            // Week view
            HStack(spacing: 0) {
                ForEach(daysInWeek(), id: \.self) { date in
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let isToday = calendar.isDateInToday(date)
                    let events = eventsForDate(date)
                    
                    Button(action: {
                        selectedDate = date
                        selectedDayEvents = events
                        showingEventSheet = !events.isEmpty
                    }) {
                        VStack(spacing: 4) {
                            Text(daysOfWeek[calendar.component(.weekday, from: date) - 1])
                                .font(.caption)
                                .foregroundColor(isSelected ? .white : .secondary)
                            
                            Text("\(calendar.component(.day, from: date))")
                                .font(isToday ? .headline : .body)
                                .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))
                            
                            if !events.isEmpty {
                                Circle()
                                    .fill(isSelected ? Color.white : Color.blue)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.blue : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            
            // Daily schedule
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text(formatDate(selectedDate))
                        .font(.headline)
                        .padding(.top)
                    
                    if eventsForDate(selectedDate).isEmpty {
                        Text("No events scheduled")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(eventsForDate(selectedDate)) { event in
                            CalendarEventRow(event: event)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingEventSheet) {
            EventListView(events: selectedDayEvents, date: selectedDate)
        }
    }
    
    private func daysInWeek() -> [Date] {
        var days = [Date]()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysToSubtract = weekday - 1
        
        if let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: selectedDate) {
            for day in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: day, to: startOfWeek) {
                    days.append(date)
                }
            }
        }
        
        return days
    }
    
    private func eventsForDate(_ date: Date) -> [CalendarEventItem] {
        var events = [CalendarEventItem]()
        
        // Add assignments due on this date
        for assignment in calendarViewModel.assignments {
            if calendar.isDate(assignment.dueDate, inSameDayAs: date) {
                let courseCode = assignment.course?.code ?? ""
                events.append(CalendarEventItem(
                    id: UUID(),
                    title: "\(courseCode): \(assignment.name)",
                    date: assignment.dueDate,
                    type: .assignment,
                    notes: assignment.notes,
                    isCompleted: assignment.isCompleted
                ))
            }
        }
        
        // Add todo items due on this date
        for todoItem in calendarViewModel.todoItems {
            if let dueDate = todoItem.dueDate, calendar.isDate(dueDate, inSameDayAs: date) {
                events.append(CalendarEventItem(
                    id: UUID(),
                    title: todoItem.title,
                    date: dueDate,
                    type: .todo,
                    notes: todoItem.notes,
                    isCompleted: todoItem.isCompleted
                ))
            }
        }
        
        // Add calendar events on this date
        for event in calendarViewModel.events {
            if calendar.isDate(event.startDate, inSameDayAs: date) {
                events.append(CalendarEventItem(
                    id: UUID(),
                    title: event.title,
                    date: event.startDate,
                    type: .calendarEvent,
                    notes: event.notes ?? "",
                    isCompleted: false
                ))
            }
        }
        
        return events.sorted { $0.date < $1.date }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

struct CalendarEventRow: View {
    let event: CalendarEventItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time
            Text(formatTime(event.date))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            // Event indicator
            Circle()
                .fill(colorForEventType(event.type))
                .frame(width: 10, height: 10)
                .padding(.top, 5)
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .strikethrough(event.isCompleted)
                    .foregroundColor(event.isCompleted ? .secondary : .primary)
                
                if !event.notes.isEmpty {
                    Text(event.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(eventTypeLabel(event.type))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(colorForEventType(event.type).opacity(0.2))
                    .cornerRadius(4)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func colorForEventType(_ type: CalendarEventItem.EventType) -> Color {
        switch type {
        case .assignment:
            return .blue
        case .todo:
            return .green
        case .calendarEvent:
            return .orange
        }
    }
    
    private func eventTypeLabel(_ type: CalendarEventItem.EventType) -> String {
        switch type {
        case .assignment:
            return "Assignment"
        case .todo:
            return "To-Do"
        case .calendarEvent:
            return "Event"
        }
    }
}

struct EventListView: View {
    let events: [CalendarEventItem]
    let date: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(events) { event in
                    CalendarEventRow(event: event)
                }
            }
            .navigationTitle(formatDate(date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct CalendarEventItem: Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let type: EventType
    let notes: String
    let isCompleted: Bool
    
    enum EventType {
        case assignment, todo, calendarEvent
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [Semester.self, Course.self, Assignment.self, TodoItem.self], inMemory: true)
}