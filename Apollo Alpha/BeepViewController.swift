//
//  BeepViewController.swift
//  BLEDemo
//
//  Created by Brian Neil on 2/16/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//

import UIKit

class BeepViewController: UIViewController {

    var freq: Double = 0.0 {
        didSet {
            Frequency.text = "Frequency (Hz): \(freq)"    //Displays the frequency any time it's updated
        }
    }
    
    var vol: Double = 0.0 {
        didSet {
            Volume.text = "Volume (dB): \(vol)"
        }
    }
    
    var BLEStatusFlag: Bool = false {
        didSet {
            if BLEStatusFlag {
                BLEStatus.text = "BLE Status: Connected"
            } else {
                BLEStatus.text = "BLE Status: Disconnected"
            }
        }
    }
    
    var TimerTXDelay: NSTimer?
    var allowTX = true
    
    struct constants {
        static let beepTest: UInt8 = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        freq = 0.0
        vol = 0.0
        BLEStatus.text = "BLE Status: Disconnected"
        
        //Set up BLE connection notification watching, call connectionChanged if it changes
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("connectionChanged:"), name: BLEServiceChangedStatusNotification, object: nil)
        
        //start searching for BLE
        btDiscoverySharedInstance
    }
    
    deinit {
        //kill the notificaton observer and timer on the way out
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BLEServiceChangedStatusNotification, object: nil)
        stopTimerTXDelay()
    }

    
    
    //MARK: UI Stuff
    
    @IBAction func Start(sender: UIButton) {
    }
    
    @IBAction func WasHeard(sender: UIButton) {
    }

    @IBAction func BeepTest(sender: UIButton) {
        sendMessage(constants.beepTest)
    }
    
    @IBOutlet weak var Frequency: UILabel!
    
    
    @IBOutlet weak var Volume: UILabel!
    
    
    @IBOutlet weak var BLEStatus: UILabel!
    
    
    //MARK: BLE Stuff
    func connectionChanged(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: Bool] //Grabs the notification data and casts it
        dispatch_async(dispatch_get_main_queue(), {
            if let isConnected = userInfo["isConnected"] {
                self.BLEStatusFlag = isConnected
            }
        })
    }
    
    func sendMessage(message: UInt8) {
        //1st, check that allowTX is armed again
        if !allowTX {
            return
        }
        
        //Then send the message to the BLE shield if the service exists and we are connected
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writeMessage(message)
            
            //And start the delay timer so we don't overload the TX channel
            allowTX = false
            if TimerTXDelay == nil {
                TimerTXDelay = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("timerTXDelayElapsed"), userInfo: nil, repeats: false)
            }
        }
    }
    
    func timerTXDelayElapsed() {    //Timer's done, rearm the message sender, kill the timer
        allowTX = true
        stopTimerTXDelay()
    }
    
    func stopTimerTXDelay() {   //If the timer exists, invalidate it
        if TimerTXDelay == nil {
            return
        }
        
        TimerTXDelay?.invalidate()
        TimerTXDelay = nil
    }
    
    
    
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
