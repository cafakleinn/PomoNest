//
//  Models.swift
//  PomoNest
//
//  Created by Trae AI on 2025-03-27.
//

import Foundation
import SwiftData

@Model
class Semester {
    var name: String
    var startDate: Date
    var endDate: Date
    @Relationship(deleteRule: .cascade) var courses: [Course] = []
    
    init(name: String, startDate: Date, endDate: Date) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
    }
    
    var gpa: Double {
        guard !courses.isEmpty else { return 0.0 }
        let totalPoints = courses.reduce(0.0) { $0 + $1.gpa * Double($1.creditHours) }
        let totalCredits = courses.reduce(0) { $0 + $1.creditHours }
        return totalPoints / Double(totalCredits)
    }
}

@Model
class Course {
    var code: String
    var name: String
    var creditHours: Int = 3
    @Relationship(inverse: \Semester.courses) var semester: Semester?
    @Relationship(deleteRule: .cascade) var assignments: [Assignment] = []
    @Relationship(deleteRule: .cascade) var gradingComponents: [GradingComponent] = []
    
    init(code: String, name: String, creditHours: Int = 3) {
        self.code = code
        self.name = name
        self.creditHours = creditHours
    }
    
    var gpa: Double {
        guard !gradingComponents.isEmpty else { return 0.0 }
        return gradingComponents.reduce(0.0) { $0 + $1.weightedGrade }
    }
}

@Model
class GradingComponent {
    var name: String
    var weight: Double // Percentage (0-100)
    var earnedPoints: Double?
    var totalPoints: Double
    @Relationship(inverse: \Course.gradingComponents) var course: Course?
    
    init(name: String, weight: Double, earnedPoints: Double? = nil, totalPoints: Double = 100.0) {
        self.name = name
        self.weight = weight
        self.earnedPoints = earnedPoints
        self.totalPoints = totalPoints
    }
    
    var percentage: Double {
        guard let earnedPoints = earnedPoints else { return 0.0 }
        return (earnedPoints / totalPoints) * 100.0
    }
    
    var weightedGrade: Double {
        return (percentage / 100.0) * (weight / 100.0)
    }
}

@Model
class Assignment {
    var name: String
    var dueDate: Date
    var weight: Double? // Optional percentage weight
    var isCompleted: Bool = false
    var notes: String = ""
    @Relationship(inverse: \Course.assignments) var course: Course?
    
    init(name: String, dueDate: Date, weight: Double? = nil, isCompleted: Bool = false, notes: String = "") {
        self.name = name
        self.dueDate = dueDate
        self.weight = weight
        self.isCompleted = isCompleted
        self.notes = notes
    }
}

@Model
class TodoItem {
    var title: String
    var dueDate: Date?
    var isCompleted: Bool = false
    var notes: String = ""
    var createdAt: Date = Date()
    
    init(title: String, dueDate: Date? = nil, isCompleted: Bool = false, notes: String = "") {
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.notes = notes
    }
}