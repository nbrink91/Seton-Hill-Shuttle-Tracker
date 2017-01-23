//
//  ScheduleViewController.swift
//  Shuttles
//
//  Created by Nicholas Brink on 1/22/17.
//  Copyright © 2017 Seton Hill University. All rights reserved.
//

import UIKit

class ScheduleViewController: UIViewController {
    weak var vehicle: Vehicle!
    var url: String!
    var scheduleType: String?
    
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var scheduleView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = URL(string: self.url) {
            let request = URLRequest(url: url)
            scheduleView.loadRequest(request)
            self.view.addSubview(scheduleView)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navItem.title = "\(vehicle.deviceName) Schedule"
        self.navItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(back))
    }
    
    func back() {
        self.dismiss(animated: true, completion: nil)
    }
}
