//
//  MenuViewController.swift
//  Shuttles
//
//  Created by Nicholas Brink on 1/19/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps

class MenuViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // Outlets
    @IBOutlet weak var menuView: MenuView!
    @IBOutlet weak var mapType: UISegmentedControl!
    @IBOutlet weak var shuttleCollectionView: UICollectionView!
    @IBOutlet weak var trafficSwitch: UISwitch!
    
    // Vars
    var shuttleSchedules: [Int64:Schedule] = [:]
    var scheduleUrl: String?
    var scheduleVehicle: Vehicle?
    var visibleShuttles: [Vehicle] = []
    
    // Seque
    weak var mapViewController: MapViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadShuttleSchedules()
        
        // Initialize View
        let blurEffect = UIBlurEffect(style: .extraLight)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = menuView.frame
        menuView.insertSubview(blurEffectView, at: 0)
        
        // Initialize Map Type.
        if let mapTypeIndex = UserDefaults.standard.string(forKey: "mapTypeIndex") {
            mapType.selectedSegmentIndex = Int(mapTypeIndex)!
        }
        
        trafficSwitch.setOn(UserDefaults.standard.bool(forKey: "trafficEnabled"), animated: false)
        
        // Initialize the shuttle collection view.
        shuttleCollectionView.delegate = self
        shuttleCollectionView.dataSource = self
        shuttleCollectionView.backgroundColor = UIColor.clear
        shuttleCollectionView.backgroundView?.backgroundColor = UIColor.clear
        
        for vehicle in self.mapViewController.vehicles {
            if let latitude = vehicle.value.latitude,
                let longitude = vehicle.value.longitude {
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                
                if MapService().checkIfWithinBounds(mapView: self.mapViewController.mapView, coordinate: coordinate) {
                    visibleShuttles += [vehicle.value]
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Tutorial on how to open the shuttle menus.
        let tutorialComplete = UserDefaults.standard.bool(forKey: "shuttleTutorialComplete")
        if tutorialComplete != true {
            let alert = UIAlertController(title: "Shuttle Tutorial", message: "To go to a shuttles location or view its schedules tap a shuttle below!", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Thanks!", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true) {
                UserDefaults.standard.set(true, forKey: "shuttleTutorialComplete")
            }
        }
    }
    
    // Load the Shuttle Schedules from Firebase and save it on the class as a dictionary to reuse.
    func loadShuttleSchedules() -> Void {
        FIRDatabase.database().reference().child("schedules").observeSingleEvent(of: FIRDataEventType.value, with: { (snapshot) in
            if let shuttleSchedulesDict = snapshot.value as? Dictionary<String, AnyObject> {
                for scheduleObject in shuttleSchedulesDict {
                    if let scheduleDict = scheduleObject.value as? Dictionary<String, String> {
                        let vehicleId = Int64(scheduleObject.key)
                        if vehicleId != nil {
                            self.shuttleSchedules[vehicleId!] = Schedule(schedule: scheduleDict)
                        }
                    }
                }
            }
        })
    }
    
    // Set the number of items to the number of vehicles.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleShuttles.count
    }
    
    // Render the cells.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "shuttleCell", for: indexPath) as! ShuttleCollectionViewCell
        
        let vehicle = visibleShuttles[indexPath.row]
        let image = UIImage(named: "shuttle")?.withRenderingMode(.alwaysTemplate)
        cell.shuttleName.text = vehicle.deviceName
        cell.shuttleImage.image = image
        cell.shuttleImage.tintColor = vehicle.color
        
        return cell
    }
    
    // When an item is selected show a menu to go to the shuttle or view the schedule.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Get the vehicle for the pressed button.
        let vehicle = visibleShuttles[indexPath.row]
            
        // Build an alert on tap.
        let alert = UIAlertController(title: vehicle.deviceName, message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        // Verify that the map is on the map.
        if vehicle.movedRecently {
            // If go to shuttle is pressed, close the modal and go to the coordinates.
            alert.addAction(UIAlertAction(title: "Go to Shuttle", style: UIAlertActionStyle.default, handler: { (data) in
                let firebaseConfigs = FirebaseService().loadRemoteConfigs()
                
                self.dismiss(animated: true, completion: {
                    if let latitude = vehicle.latitude,
                        let longitude = vehicle.longitude,
                        let zoom = firebaseConfigs[CAMERA_CLOSE_ZOOM_KEY].numberValue {
                        self.mapViewController?.mapView.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: Float(zoom))
                    }
                })
            }))
        } else {
            alert.message = "Shuttle location is not available."
        }
        
        let schedule = shuttleSchedules[vehicle.deviceId]
        
        // Show the all week schedule.
        if (schedule?.allWeek != nil) {
            alert.addAction(UIAlertAction(title: "View Schedule", style: UIAlertActionStyle.default, handler: { (data) in
                self.segueToSchedule(url: (schedule?.allWeek!)!, vehicle: vehicle)
            }))
        }

        // Show the weekday schedule.
        if (schedule?.weekday != nil) {
            alert.addAction(UIAlertAction(title: "View Weekday Schedule", style: UIAlertActionStyle.default, handler: { (data) in
                self.segueToSchedule(url: (schedule?.weekday!)!, vehicle: vehicle)
            }))
        }
        
        // Show the weekend schedule.
        if (schedule?.weekend != nil) {
            alert.addAction(UIAlertAction(title: "View Weekend Schedule", style: UIAlertActionStyle.default, handler: { (data) in
                self.segueToSchedule(url: (schedule?.weekend!)!, vehicle: vehicle)
            }))
        }
            
        // Close the alert.
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: { (data) in
            alert.dismiss(animated: true, completion: nil)
        }))
            
        // Configure for iPad support
        let popOver = alert.popoverPresentationController
        popOver?.sourceView = collectionView.cellForItem(at: indexPath)
        popOver?.sourceRect = (collectionView.cellForItem(at: indexPath)?.bounds)!
            
        // Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func segueToSchedule(url: String, vehicle: Vehicle) {
        self.scheduleUrl = url
        self.scheduleVehicle = vehicle
        self.performSegue(withIdentifier: "goToSchedule", sender: self)
    }
    
    // Dismiss the modal when the close button is tapped.
    @IBAction func closeTapped(_ sender: Any) {
        dismissMenu()
    }
    
    // Dismiss the modal when the background is tapped.
    @IBAction func backgroundTapped(_ sender: Any) {
        dismissMenu()
    }
    
    // Change the map type based on selection.
    @IBAction func mapTypeTapped(_ sender: UISegmentedControl) {
        let mapType = ConfigurationService().mapType(index: sender.selectedSegmentIndex)
        
        self.mapViewController.mapView.mapType = mapType
        UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: "mapTypeIndex")
        
        if mapType == GMSMapViewType.hybrid {
            self.mapViewController.statusBarStyle = .lightContent
        } else if mapType == GMSMapViewType.normal && self.mapViewController.nightMode == true {
            self.mapViewController.statusBarStyle = .lightContent
        } else if mapType == GMSMapViewType.normal && self.mapViewController.nightMode == false {
            self.mapViewController.statusBarStyle = .default
        }
        
        self.mapViewController.setNeedsStatusBarAppearanceUpdate()
    }
    
    // Dismiss the menu and return to map.
    func dismissMenu() -> Void {
        dismiss(animated: true) {}
    }
    
    // Pass data to the schedule.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToSchedule" {
            if let target = segue.destination as? ScheduleViewController {
                target.url = self.scheduleUrl
                target.vehicle = self.scheduleVehicle
            }
        }
    }
    
    // Toggle traffic.
    @IBAction func trafficSwitchTapped(_ sender: UISwitch) {
        self.mapViewController.mapView.isTrafficEnabled = sender.isOn
        UserDefaults.standard.set(sender.isOn, forKey: "trafficEnabled")
    }
}
