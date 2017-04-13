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
        remoteConfig.setDefaultsFromPlistFileName("RemoteConfigDefaults")
        remoteConfig.fetch(withExpirationDuration: TimeInterval(60)) { (status, error) -> Void in
            if status == .success {
                remoteConfig.activateFetched()
            } else {
                print("Config not fetched")
                print("Error \(String(describing: error))")
            }
        }
        return remoteConfig
    }
}
