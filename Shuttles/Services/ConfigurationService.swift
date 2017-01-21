//
//  ConfigurationService.swift
//  Shuttles
//
//  Created by Nicholas Brink on 1/19/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

import GoogleMaps

class ConfigurationService {
    func mapType(index: Int) -> GMSMapViewType {
        switch index {
        case 0:
            return kGMSTypeNormal
        case 1:
            return kGMSTypeHybrid
        default:
            return kGMSTypeNormal
        }
    }
}
