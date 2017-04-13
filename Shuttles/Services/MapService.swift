//
//  MapService.swift
//  Shuttles
//
//  Created by Nicholas Brink on 2/6/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

import GoogleMaps

class MapService {
    // Check if a coodinate is within the bounds of a map viewport.
    func checkIfWithinBounds(mapView: GMSMapView, coordinate: CLLocationCoordinate2D) -> Bool {
        let region = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: region)
        
        if bounds.contains(coordinate) {
            return true
        }
        
        return false
    }
    
    // Verify that the shuttle has moved within the last 'maxMinutes'
    func lastMovedCheck(vehicle: Vehicle, maxMinutes: Int = 10) -> Bool {
        if let lastMoved = vehicle.lastMoved {
            let secondsDiff = Int(Date().timeIntervalSince(lastMoved))
            
            if secondsDiff <= maxMinutes * 60 {
                return true
            }
        }
        
        return false
    }
}
