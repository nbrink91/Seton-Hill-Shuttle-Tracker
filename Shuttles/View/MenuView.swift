//
//  MenuView.swift
//  Shuttles
//
//  Created by Nicholas Brink on 1/19/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

import UIKit

class MenuView: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.layoutIfNeeded()
        
        let rectShape = CAShapeLayer()
        rectShape.bounds = self.frame
        rectShape.position = self.center
        rectShape.path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 20, height: 20)).cgPath
        
        layer.masksToBounds = true
        layer.shadowRadius = 5
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 50
        layer.mask = rectShape
        self.contentMode = .redraw
    }
}
