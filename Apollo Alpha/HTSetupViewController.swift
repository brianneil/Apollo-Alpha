//
//  BeepViewController.swift
//  BLEDemo
//
//  Created by Brian Neil on 2/16/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//

import UIKit

class HTSetupViewController: UIViewController {
    
    private var BLEStatusFlag: Bool = false {
        didSet {
            if BLEStatusFlag {
                BLEStatus.text = "BLE Status: Connected"
            } else {
                BLEStatus.text = "BLE Status: Disconnected"
            }
        }
    }
    
    private struct constants {
        static let TestFreq = HTBarsViewController.Freqs.Hz1000
        static let TestEar = HTBarsViewController.Ears.bothEars
        static let TestVol = 75
        static let isConnectedKey = "isConnected"
        static let dataKey = "MessageFromPeripheral"
    }
    
    let comms = CommunicationCenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BLEStatus.text = "BLE Status: Disconnected"
        
        //Set up BLE connection notification watching, call connectionChanged if it changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HTSetupViewController.connectionChanged(_:)), name: BLEServiceChangedStatusNotification, object: nil)
        
        //start searching for BLE
        btDiscoverySharedInstance
    }
    
    deinit {
        //kill the notificaton observer and timer on the way out
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BLEServiceChangedStatusNotification, object: nil)
    }

    
    
    //MARK: UI Stuff
    
    @IBAction func Start(sender: UIButton) {
    }
    

    @IBAction func BeepTest(sender: UIButton) {
        if let _ = btDiscoverySharedInstance.bleService {
            let tone = HTBarsViewController.Tone(frequency: constants.TestFreq, ear: constants.TestEar, volume: constants.TestVol)
            comms.SendMessageToPeripheral(tone)
        }
    }
    
    
    @IBOutlet weak var BLEStatus: UILabel!
    
    
    //MARK: BLE Stuff
    func connectionChanged(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: Bool] //Grabs the notification data and casts it
        dispatch_async(dispatch_get_main_queue(), { [unowned self] in
            if let isConnected = userInfo[constants.isConnectedKey] {
                self.BLEStatusFlag = isConnected
            }
        })
    }

    
    
    // MARK: - Navigation

//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//
//        
//        
//        
//        
//        
//        
//        // Get the new view controller using segue.destinationViewController.
//        // Pass the selected object to the new view controller.
//    }
    

}
