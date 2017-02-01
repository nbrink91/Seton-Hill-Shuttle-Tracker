//
//  ShuttleHeadingUIView.swift
//  Shuttles
//
//  Created by Nicholas Brink on 1/27/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

import UIKit

class ShuttleHeadingUIView: UIView {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(color: UIColor) {
        super.init(frame: CGRect())
        
        let shuttle = ShuttleUIImageView(color: color)
        let shuttlePointer = ShuttlePointerUIImageView(color: color)
        
        self.frame = CGRect(x: 0, y: 0, width: shuttle.frame.width, height: shuttle.frame.height + shuttlePointer.frame.height/2)
        shuttle.center = CGPoint(x: self.frame.width/2, y: self.frame.height - shuttle.frame.height/2)
        
        self.addSubview(shuttlePointer)
        self.addSubview(shuttle)
    }
}
