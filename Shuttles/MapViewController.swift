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
    enum myLocationButtonStates {
        case zoomed, selected, notSelected
    }
    var myLocationButtonState = myLocationButtonStates.notSelected
    var myLocationCanBeUnselected = false
    
    // Variables
    var markers: [Int64:GMSMarker] = [:]
    var vehicles: [Int64:Vehicle] = [:]
    var FIR_REF: FIRDatabaseReference!
    var FIR_REF_VEHICLES: FIRDatabaseReference!
    var darkMode = false // Set to dark mode if true.
    
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
    
    // Actions
    @IBAction func myLocationButtonTapped(_ sender: Any) {
        if let coordinates = mapView.myLocation?.coordinate {
            switch myLocationButtonState {
            case myLocationButtonStates.notSelected:
                print("Not Selected -> Selected")
                myLocationButtonState = myLocationButtonStates.selected
                myLocationButton.image = UIImage(named: "myLocationButton-selected")
                let camera = GMSCameraPosition(target: coordinates, zoom: 14, bearing: 0, viewingAngle: 0)
                mapView.animate(to: camera)
                break
            case myLocationButtonStates.zoomed:
                print("Zoomed -> Selected")
                myLocationButtonState = myLocationButtonStates.selected
                myLocationButton.image = UIImage(named: "myLocationButton-selected")
                let camera = GMSCameraPosition(target: coordinates, zoom: 14, bearing: 0, viewingAngle: 0)
                mapView.animate(to: camera)
                break
            case myLocationButtonStates.selected:
                print("Selected -> Zoomed")
                myLocationButtonState = myLocationButtonStates.notSelected
                myLocationButton.image = UIImage(named: "myLocationButton-zoomed")
                let camera = GMSCameraPosition(target: coordinates, zoom: 20, bearing: myHeading, viewingAngle: 180)
                mapView.animate(to: camera)
                break
            }
        }
    }
    
    // Save heading direction so it can be used for zoom view.
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        myHeading = newHeading.trueHeading
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        if myLocationButtonState == .selected || myLocationButtonState == .zoomed {
            myLocationCanBeUnselected = true
        }
    }

    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        if myLocationCanBeUnselected == true {
            print("Move to unselected!")
            myLocationCanBeUnselected = false
            myLocationButton.image = UIImage(named: "myLocationButton-notSelected")
            myLocationButtonState = myLocationButtonStates.notSelected
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FIR_REF = FIRDatabase.database().reference()
        FIR_REF_VEHICLES = FIR_REF.child("vehicles")
        
        initMapView()
        watchForVehicleCreation()
        watchForVehicleChange()
        watchForVehicleDelete()
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingHeading();
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            myLocationButton.isHidden = false
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
        }
        
        // Initialize things that use location.
        if  let latitude = firebaseConfigs.configValue(forKey: "default_latitude").numberValue as? Double,
            let longitude = firebaseConfigs.configValue(forKey: "default_longitude").numberValue as? Double,
            let zoom = firebaseConfigs.configValue(forKey: "default_zoom").numberValue {
                mapView.animate(to: GMSCameraPosition.camera(withTarget: CLLocationCoordinate2D.init(latitude: latitude, longitude: longitude), zoom: Float(zoom)))
            
            // Check to see if it is night time, if so, use night mode.
            let solar = Solar(latitude: latitude, longitude: longitude)
            if let isNighttime = solar?.isNighttime {
                darkMode = isNighttime
            }
            if darkMode == true {
                do {
                    if let styleURL = Bundle.main.url(forResource: "Night", withExtension: "json") {
                        mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                        setNeedsStatusBarAppearanceUpdate()
                    } else {
                        print("Unable to find style.json")
                    }
                } catch {
                    print("One or more of the map styles failed to load. \(error)")
                }
            }
        }
    }
    
    // Set the color of the Status Bar based on if it is in dark mode or not.
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if darkMode == true{
            return .lightContent
        } else {
            return .default
        }
    }
    
    // Get vehicles when they are created. This loads all vehicles initially.
    func watchForVehicleCreation() {
        FIR_REF_VEHICLES.observe(FIRDataEventType.childAdded, with: { (snapshot) in
            if let vehicleDictionary = snapshot.value as? Dictionary<String, AnyObject> {
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
            marker.position = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
            marker.map = mapView
            marker.isFlat = true
            //marker.userData = vehicle
            marker.title = vehicle.deviceName
            
            if let heading = vehicle.heading {
                // Show direction arrow and rotate marker.
                marker.rotation = CLLocationDegrees(heading)
                marker.iconView = getMarkerIcon(backgroundColor: UIColor.white, iconColor: vehicle.color!, directionEnabled: true)
            } else {
                // Don't show direction if there is no vehicle heading.
                marker.iconView = getMarkerIcon(backgroundColor: UIColor.white, iconColor: vehicle.color!, directionEnabled: false)
            }
            
            markers[vehicle.deviceId] = marker
            vehicles[vehicle.deviceId] = vehicle
        }
    }
    
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
    
    // Get a marker of a given color.
    func getMarkerIcon(backgroundColor: UIColor, iconColor: UIColor, directionEnabled: Bool) -> UIImageView {
        let markerBackground = UIImage(named: "markerBackground")?.withRenderingMode(.alwaysTemplate)
        let markerBackgroundView = UIImageView(image: markerBackground)
        markerBackgroundView.tintColor = backgroundColor
        markerBackgroundView.contentMode = UIViewContentMode.scaleAspectFit
        
        let markerInside = UIImage(named: "markerInside")?.withRenderingMode(.alwaysTemplate)
        let markerInsideView = UIImageView(image: markerInside)
        markerInsideView.tintColor = iconColor
        markerInsideView.center = CGPoint(x: markerBackgroundView.frame.size.width/2, y: markerBackgroundView.frame.size.height/2)
        
        if directionEnabled == true {
            let markerPointer = UIImage(named: "markerPointer")?.withRenderingMode(.alwaysTemplate)
            let markerPointerView = UIImageView(image: markerPointer)
            markerPointerView.tintColor = iconColor
            markerPointerView.contentMode = UIViewContentMode.scaleAspectFit
            markerBackgroundView.center = CGPoint(x: markerPointerView.frame.size.width/2, y: markerPointerView.frame.size.height)
            
            markerPointerView.addSubview(markerBackgroundView)
            markerBackgroundView.addSubview(markerInsideView)
            
            markerPointerView.bounds = CGRect(x: 0, y: -1 * markerBackgroundView.frame.size.height/2, width: markerBackgroundView.frame.width, height: markerBackgroundView.frame.height + markerPointerView.frame.height)
            
            return markerPointerView
        } else {
            markerBackgroundView.addSubview(markerInsideView)
            return markerBackgroundView
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
