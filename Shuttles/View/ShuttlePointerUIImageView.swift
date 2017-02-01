//
//  ShuttleHeadingUIImageView.swift
//  Shuttles
//
//  Created by Nicholas Brink on 1/27/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

import UIKit

class ShuttlePointerUIImageView: UIImageView {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(color: UIColor) {
        super.init(frame: CGRect())
        
        let headingPointer = UIImage(named: "markerPointer")?.withRenderingMode(.alwaysTemplate)
        self.image = headingPointer
        self.contentMode = UIViewContentMode.scaleAspectFit
        self.tintColor = color
        
        if let width = headingPointer?.size.width,
            let height = headingPointer?.size.height {
            self.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }
    }
}
