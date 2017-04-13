//
//  ViewController.swift
//  Shuttles
//
//  Created by Nicholas Brink on 1/13/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase
import Solar

class MapViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    // Constants
    let firebaseConfigs = FirebaseService().loadRemoteConfigs()
    
    // Location
    let locationManager = CLLocationManager()
    var myHeading: Double = 0
    var myLocationSelected = false
    var currentlyAnimatingToMyLocation = false
    
    // Variables
    var markers: [Int64:GMSMarker] = [:]
    var vehicles: [Int64:Vehicle] = [:]
    var FIR_REF: FIRDatabaseReference!
    var FIR_REF_VEHICLES: FIRDatabaseReference!
    var statusBarStyle: UIStatusBarStyle  = .default
    var nightMode = false
    
    // Colors
    var markerColors: [UIColor] = [
        UIColor.init(red: 183/255, green: 28/255, blue: 28/255, alpha: 0.87),
        UIColor.init(red: 27/255, green: 94/255, blue: 32/255, alpha: 0.87),
        UIColor.init(red: 74/255, green: 20/255, blue: 140/255, alpha: 0.87),
        UIColor.init(red: 38/255, green: 50/255, blue: 56/255, alpha: 0.87),
        UIColor.init(red: 230/255, green: 81/255, blue: 0, alpha: 0.87)
    ]
    var currentMarkerColorIndex: Int = 0
    
    // Outlets
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var myLocationButton: UIImageView!
    @IBOutlet weak var menuButton: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FIR_REF = FIRDatabase.database().reference()
        FIR_REF_VEHICLES = FIR_REF.child("vehicles")
        
        initMapView()
        watchForVehicleCreation()
        watchForVehicleChange()
        watchForVehicleDelete()
        
        // Ask for location and enable tracking if that is true.
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() && CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            self.myLocationButton.isHidden = false
        }
    }
    
    // Initialize the map.
    func initMapView() {
        mapView.delegate = self
        mapView.isMyLocationEnabled = true
        mapView.settings.compassButton = true
        mapView.padding = UIEdgeInsetsMake(20, 0, 0, 0)
        
        // Set the map type if it is in the config.
        if let mapTypeIndex = UserDefaults.standard.string(forKey: "mapTypeIndex") {
            mapView.mapType = ConfigurationService().mapType(index: Int(mapTypeIndex)!)
            
            if mapView.mapType == GMSMapViewType.hybrid {
                self.statusBarStyle = .lightContent
                setNeedsStatusBarAppearanceUpdate()
            }
        }
        
        // Initialize traffic!
        mapView.isTrafficEnabled = UserDefaults.standard.bool(forKey: "trafficEnabled")
        
        // Initialize things that use location.
        if  let latitude = firebaseConfigs.configValue(forKey: "default_latitude").numberValue as? Double,
            let longitude = firebaseConfigs.configValue(forKey: "default_longitude").numberValue as? Double,
            let zoom = firebaseConfigs.configValue(forKey: "default_zoom").numberValue {
                mapView.animate(to: GMSCameraPosition.camera(withTarget: CLLocationCoordinate2D.init(latitude: latitude, longitude: longitude), zoom: Float(zoom)))
            
            // Check to see if it is night time, if so, use night mode.
            let solar = Solar(latitude: latitude, longitude: longitude)
            if let isNighttime = solar?.isNighttime, isNighttime == true {
                do {
                    if let styleURL = Bundle.main.url(forResource: "Night", withExtension: "json") {
                        mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                        self.statusBarStyle = .lightContent
                        self.nightMode = true
                        setNeedsStatusBarAppearanceUpdate()
                    } else {
                        print("Unable to find the night style.")
                    }
                } catch {
                    print("Unable to load the night style. \(error)")
                }
            }
        }
    }
    
    // Handle event that occur when the map stops at a position.
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        // Handle pressing myLocationButton
        if currentlyAnimatingToMyLocation == true {
            currentlyAnimatingToMyLocation = false
            myLocationSelected = true
        }
    }
    
    // Handle event that occur when the position changes.
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        if myLocationSelected == true {
            myLocationSelected = false
            myLocationButton.image = UIImage(named: "myLocationButton-notSelected")
            currentlyAnimatingToMyLocation = false
        }
    }
    
    // Set the color of the Status Bar based on if it is in dark mode or not.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.statusBarStyle
    }
    
    // Get vehicles when they are created. This loads all vehicles initially.
    func watchForVehicleCreation() {
        FIR_REF_VEHICLES.observe(FIRDataEventType.childAdded, with: { (snapshot) in
            if let vehicleDictionary = snapshot.value as? Dictionary<String, AnyObject> {
                UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                    self.menuButton.isHidden = false
                }, completion: nil)
                let vehicle = Vehicle(vehicle: vehicleDictionary)
                vehicle.color = self.getMarkerIconColor(vehicle: vehicle)
                self.updateMarker(vehicle: vehicle)
            }
        })
    }
    
    // Watch for changes to made to vehicles.
    func watchForVehicleChange() {
        FIR_REF_VEHICLES.observe(FIRDataEventType.childChanged, with: { (snapshot) in
            if let vehicleDictionary = snapshot.value as? Dictionary<String, AnyObject> {
                let vehicle = Vehicle(vehicle: vehicleDictionary)
                vehicle.color = self.getMarkerIconColor(vehicle: vehicle)
                self.updateMarker(vehicle: vehicle)
            }
        })
    }
    
    // Watch if any vehicles are deleted and remove them from the map.
    func watchForVehicleDelete() {
        FIR_REF_VEHICLES.observe(FIRDataEventType.childRemoved, with: { (snapshot) in
            let vehicleId = Int64(snapshot.key)
            if vehicleId != nil {
                self.deleteMarker(vehicleId: vehicleId!)
            }
        })
    }
    
    // Create or update an existing marker with new vehicle data.
    func updateMarker(vehicle: Vehicle) {
        if  let latitude = vehicle.latitude,
            let longitude = vehicle.longitude {
            
            let marker = getMarker(vehicle: vehicle)
            
            // Verify that the shuttle has been updated recently. If not, don't display it.
            if vehicle.movedRecently {
                marker.tracksInfoWindowChanges = true
                marker.position = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
                marker.map = mapView
                marker.isFlat = true
                marker.title = vehicle.deviceName
            
                if let heading = vehicle.heading {
                    // Show direction arrow and rotate marker.
                    marker.rotation = CLLocationDegrees(heading)
                    let shuttleView = ShuttleHeadingUIView(color: vehicle.color!)
                    marker.iconView = shuttleView
                    let point = CGPoint(x: 0.5, y: 0.67)
                    marker.groundAnchor = point
                    marker.infoWindowAnchor = point
                } else {
                    // Don't show direction if there is no vehicle heading.
                    marker.iconView = ShuttleUIImageView(color: vehicle.color!)
                    let point = CGPoint(x: 0.5, y: 0.5)
                    marker.groundAnchor = point
                    marker.infoWindowAnchor = point
                }
            }
            
            markers[vehicle.deviceId] = marker
            vehicles[vehicle.deviceId] = vehicle
        }
    }
    
    // Remove a marker from the map if it is removed from Firebase.
    func deleteMarker(vehicleId: Int64) {
        if let marker = markers[vehicleId] {
            marker.map = nil
            markers.removeValue(forKey: vehicleId)
            vehicles.removeValue(forKey: vehicleId)
        }
    }
    
    // Get marker if it already exists, otherwise initialize a new one.
    func getMarker(vehicle: Vehicle) -> GMSMarker {
        if let marker = markers[vehicle.deviceId] {
            return marker
        } else {
            return GMSMarker()
        }
    }
    
    // Get the next icons color.
    func getMarkerIconColor(vehicle: Vehicle) -> UIColor {
        if let color = vehicles[vehicle.deviceId]?.color {
            return color
        } else if currentMarkerColorIndex == markerColors.count - 1 {
            let color = markerColors[currentMarkerColorIndex]
            currentMarkerColorIndex = 0
            return color
        } else {
            let color = markerColors[currentMarkerColorIndex]
            currentMarkerColorIndex += 1
            return color
        }
    }
    
    // Expose the MapViewController to the menu when sequed.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MainToMenu" {
            if let target = segue.destination as? MenuViewController {
                target.mapViewController = self
            }
        }
    }
}
