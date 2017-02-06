//
//  FirebaseService.swift
//  Shuttles
//
//  Created by Nicholas Brink on 1/13/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

import Foundation
import Firebase

class FirebaseService {
    func loadRemoteConfigs() -> FIRRemoteConfig {
        let remoteConfig = FIRRemoteConfig.remoteConfig()
        //let remoteConfigSettings = FIRRemoteConfigSettings(developerModeEnabled: true)
        remoteConfig.setDefaultsFromPlistFileName("RemoteConfigDefaults")
        //remoteConfig.configSettings = remoteConfigSettings!
        remoteConfig.fetch(withExpirationDuration: TimeInterval(60)) { (status, error) -> Void in
            if status == .success {
                remoteConfig.activateFetched()
            } else {
                print("Config not fetched")
                print("Error \(error)")
            }
        }
        return remoteConfig
    }
}
