//
//  BTPairUIVC.swift
//  Apollo Alpha
//
//  Created by Brian Neil on 3/24/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//


import UIKit

class BTPairUIVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set up BLE connection notification watching, call BLEStatus if it changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BTPairUIVC.BLEStatus(_:)), name: BLEServiceChangedStatusNotification, object: nil)
    }
    
    func BLEStatus(notification: NSNotification) {
        //Change the writing of the Status Message here.
    }
    
    @IBOutlet weak var StatusMessage: UILabel!

}
