//
//  HeaderUIStackView.swift
//  Shuttles
//
//  Created by Nicholas Brink on 1/19/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

import UIKit

class HeaderUIStackView: UIStackView {
    override func draw(_ rect: CGRect) {
        let border = CALayer()
        
        border.frame = CGRect(x: 0, y: 0, width: self.layer.frame.width, height: 3)
        
        layer.addSublayer(border)
    }
}
