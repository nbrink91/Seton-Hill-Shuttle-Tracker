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
    @IBOutlet weak var mapType: UISegmentedControl!
    @IBOutlet weak var shuttleCollectionView: UICollectionView!
    
    // Seque
    weak var mapViewController: MapViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Map Type.
        if let mapTypeIndex = UserDefaults.standard.string(forKey: "mapTypeIndex") {
            mapType.selectedSegmentIndex = Int(mapTypeIndex)!
        }
        
        // Initialize the shuttle collection view.
        shuttleCollectionView.delegate = self
        shuttleCollectionView.dataSource = self
        shuttleCollectionView.backgroundColor = UIColor.clear
        shuttleCollectionView.backgroundView?.backgroundColor = UIColor.clear
    }
    
    // Set the number of items to the number of vehicles.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mapViewController.vehicles.count
    }
    
    // Render the cells.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "shuttleCell", for: indexPath) as! ShuttleCollectionViewCell
        
        if let vehicle = self.vehicleFromIndex(index: indexPath.row) {
            let image = UIImage(named: "shuttle")?.withRenderingMode(.alwaysTemplate)
            cell.shuttleName.text = vehicle.deviceName
            cell.shuttleImage.image = image
            cell.shuttleImage.tintColor = vehicle.color
        }
        
        return cell
    }
    
    // When an item is selected zoom to the shuttle.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let firebaseConfigs = FirebaseService().loadRemoteConfigs()
        
        if let vehicle = self.vehicleFromIndex(index: indexPath.row) {
            dismiss(animated: true, completion: {
                if let latitude = vehicle.latitude,
                    let longitude = vehicle.longitude,
                    let zoom = firebaseConfigs[CAMERA_CLOSE_ZOOM_KEY].numberValue {
                    self.mapViewController?.mapView.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: Float(zoom))
                }
            })
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        dismissMenu()
    }
    
    // Dismiss the modal when the background is tapped.
    @IBAction func backgroundTapped(_ sender: Any) {
        dismissMenu()
    }
    
    // Change the map type based on selection.
    @IBAction func mapTypeTapped(_ sender: UISegmentedControl) {
        self.mapViewController.mapView.mapType = ConfigurationService().mapType(index: sender.selectedSegmentIndex)
        setNeedsStatusBarAppearanceUpdate()
        UserDefaults.standard.set(sender.selectedSegmentIndex, forKey: "mapTypeIndex")
    }
    
    // Dismiss the menu and return to map.
    func dismissMenu(){
        dismiss(animated: true) { 
            print("Dismissed")
        }
    }
    
    // Get a vehicle if it exists at a given index.
    func vehicleFromIndex(index: Int) -> Vehicle? {
        if  let values = self.mapViewController?.vehicles.values {
            let vehicle = Array(values)[index]
            return vehicle
        }
        
        return nil
    }
}
