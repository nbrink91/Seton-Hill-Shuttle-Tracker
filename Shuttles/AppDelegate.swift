//
//  AppDelegate.swift
//  Shuttles
//
//  Created by Nicholas Brink on 1/13/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Firebase.
        FIRApp.configure()
        
        let remoteConfigs = FirebaseService().loadRemoteConfigs()
        
        if let key = remoteConfigs.configValue(forKey: "google_maps_api_key").stringValue, key != "" {
            GMSServices.provideAPIKey(key)
        }
        
        return true
    }
}

