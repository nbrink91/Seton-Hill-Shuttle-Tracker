//
//  ShuttleUIImageView.swift
//  Shuttles
//
//  Created by Nicholas Brink on 1/27/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

import UIKit

class ShuttleUIImageView: UIImageView {
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(color: UIColor) {
        super.init(frame: CGRect())
        
        let insideImage = UIImage(named: "markerInside")?.withRenderingMode(.alwaysTemplate)
        let insideView = UIImageView(image: insideImage)
        insideView.tintColor = color
        
        if let width = insideImage?.size.width,
            let height = insideImage?.size.height {
            insideView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }
        
        let backgroundImage = UIImage(named: "markerBackground")
        self.image = backgroundImage
        
        if let width = backgroundImage?.size.width,
            let height = backgroundImage?.size.height {
            self.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }
        
        insideView.center = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2)
        self.addSubview(insideView)
    }
}
