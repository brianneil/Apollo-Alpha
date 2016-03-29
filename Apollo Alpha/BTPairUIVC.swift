//
//  BTPairUIVC.swift
//  Apollo Alpha
//
//  Created by Brian Neil on 3/24/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//


import UIKit

class BTPairUIVC: UIViewController {
    
    private struct constants {
        static let isConnectedKey = "isConnected"
        static let OnOffKey = "OnOffKey"
    }
    
    private var BLEConnectedFlag: Bool = false
    {
        didSet {
            if BLEConnectedFlag {
                StatusMessage.text = "Paired! Press next to continue."
                NextButton.hidden = false //Reveals the button so the user can go to the next page
            }
            else {
                StatusMessage.text = "Pairing......."
                NextButton.hidden = true
            }
        }
    }
    private var BLEOnFlag: Bool = false {
        didSet {
            if BLEOnFlag {
                StatusMessage.text = "Pairing......."
                NextButton.hidden = true
            }
            else {
                StatusMessage.text = "Please turn on Bluetooth"
                NextButton.hidden = true
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NextButton.hidden = true    //Hides the button until we want to reveal it.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set up BLE connection notification watching, call BLEStatus if it changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BTPairUIVC.BLEConnectStatus(_:)), name: BLEServiceChangedStatusNotification, object: nil)
        
        //Set up BLE on/off notification watching, call BLEStatus if it changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BTPairUIVC.BLEOnOffStatus(_:)), name: BLEOnOffChangedStatusNotification, object: nil)
        
        //Start looking for BLE
        btDiscoverySharedInstance
        
        self.title = "Pairing"
    }
    
    deinit {
        //kill the notification observers on the way out
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BLEServiceChangedStatusNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BLEOnOffChangedStatusNotification, object: nil)
    }
    
    func BLEConnectStatus(notification: NSNotification) {
        //Deal with the notification of whether or not we're connected
        let userInfo = notification.userInfo as! [String: Bool] //Grabs the notification data and casts it
        dispatch_async(dispatch_get_main_queue(), { [unowned self] in
            if let isConnected = userInfo[constants.isConnectedKey] {
                self.BLEConnectedFlag = isConnected
            }
            })
    }
    
    func BLEOnOffStatus(notification: NSNotification) {
        //Deal with whether the user has bluetooth on or not
        let userInfo = notification.userInfo as! [String: Bool] //Grabs the notification data and casts it
        dispatch_async(dispatch_get_main_queue(), { [unowned self] in
            if let isOn = userInfo[constants.OnOffKey] {
                self.BLEOnFlag = isOn
            }
            })
    }
    
    
    
    @IBOutlet weak var NextButton: UIButton!
    
    @IBOutlet weak var StatusMessage: UILabel!

}
