//
//  Schedule.swift
//  Shuttles
//
//  Created by Nicholas Brink on 1/21/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

class Schedule {
    init(schedule: Dictionary<String, String>) {
        if let weekday = schedule["weekday"] {
            self._weekday = weekday
        }
        
        if let weekend = schedule["weekend"] {
            self._weekend = weekend
        }
        
        if let allWeek = schedule["allWeek"] {
            self._allWeek = allWeek
        }
    }
    
    private var _weekday: String?
    var weekday: String? {
        return _weekday
    }
    
    private var _weekend: String?
    var weekend: String? {
        return _weekend
    }
    
    private var _allWeek: String?
    var allWeek: String? {
        return _allWeek
    }
}
