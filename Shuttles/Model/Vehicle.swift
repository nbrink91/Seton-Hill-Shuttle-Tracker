//
//  Vehicle.swift
//  Shuttles
//
//  Created by Nicholas Brink on 1/14/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

import UIKit

class Vehicle {
    init(vehicle: Dictionary<String, AnyObject>) {
        if let accountId = vehicle["AccountId"] as? Int64 {
            self._accountId = accountId
        }
        
        if let deviceId = vehicle["DeviceId"] as? Int64 {
            self._deviceId = deviceId
        }
        
        if let deviceName = vehicle["DeviceName"] as? String {
            self._deviceName = deviceName
        }
        
        if let latitude = vehicle["Latitude"] as? Double {
            self._latitude = latitude
        }
        
        if let longitude = vehicle["Longitude"] as? Double {
            self._longitude = longitude
        }
        
        if let heading = vehicle["Heading"] as? Int32 {
            self._heading = heading
        }
        
        if let velocity = vehicle["Velocity"] as? Int32 {
            self._velocity = velocity
        }
        
        if let satellites = vehicle["Satellites"] as? Int32 {
            self._satellites = satellites
        }
        
        if let ignition = vehicle["Ignition"] as? Int32 {
            self._ignition = ignition
        }
        
        if let lastMoved = vehicle["LastMoved"] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            let date = dateFormatter.date(from: lastMoved)
            self._lastMoved = date
        }
        
        if let lastUpdated = vehicle["LastUpdated"] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            let date = dateFormatter.date(from: lastUpdated)
            self._lastUpdated = date
        }
        
        if let outputFlags = vehicle["OutputFlags"] as? UInt32 {
            self._outputFlags = outputFlags
        }
        
        if let power = vehicle["Power"] as? Int32 {
            self._power = power
        }
    }
    
    private var _accountId: Int64?
    var accountId: Int64? {
        return _accountId
    }
    
    private var _deviceId: Int64!
    var deviceId: Int64! {
        return _deviceId
    }
    
    private var _deviceName: String?
    var deviceName: String? {
        return _deviceName
    }
    
    private var _latitude: Double?
    var latitude: Double? {
        return _latitude
    }
    
    private var _longitude: Double?
    var longitude: Double? {
        return _longitude
    }
    
    private var _heading: Int32?
    var heading: Int32? {
        return _heading
    }
    
    private var _velocity: Int32?
    var velocity: Int32? {
        return _velocity
    }
    
    private var _satellites: Int32?
    var satellites: Int32? {
        return _velocity
    }
    
    private var _ignition: Int32?
    var ignition: Int32? {
        return _ignition
    }
    
    private var _lastMoved: Date?
    var lastMoved: Date? {
        return _lastMoved
    }
    
    private var _lastUpdated: Date?
    var lastUpdated: Date? {
        return _lastUpdated
    }
    
    private var _outputFlags: UInt32?
    var outputFlags: UInt32? {
        return _outputFlags
    }
    
    private var _power: Int32?
    var power: Int32? {
        return _power
    }
    
    // Check if the vehicle was moved within the last x amount of time.
    var movedRecently: Bool {
        return MapService().lastMovedCheck(vehicle: self)
    }
    
    var color: UIColor?
}
