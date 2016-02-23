//
//  HTViewController.swift
//  Apollo Alpha
//
//  Created by Brian Neil on 2/19/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//

import UIKit

class HTViewController: UIViewController {
    
    var freq: Int = 0
    
    var vol: Int = 0
    
    var ear: String = ""
    
    let comms = CommunicationCenter()
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Hearing Test"
        
        //Set up message received notification watcher, call messageReceived if we get something
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "newMessageIncoming:", name: messageParsedNotification, object: nil)
    }
    
    deinit {
        //kill the notificaton observer and timer on the way out
        NSNotificationCenter.defaultCenter().removeObserver(self, name: messageParsedNotification, object: nil)
    }

    //MARK: UI
    
    @IBOutlet weak var Volume: UILabel!
    
    @IBOutlet weak var Frequency: UILabel!

    @IBOutlet weak var EarPlayed: UILabel!
    
//    @IBAction func wasHeard(sender: UIButton) {
//        comms.SendMessageToPeripheral()
//    }
    
    func updateUI() {
        dispatch_async(dispatch_get_main_queue(), { [unowned self] in
            self.Frequency.text = "Frequency (Hz): \(self.freq)"
            self.Volume.text = "Volume (dB): \(self.vol)"
            self.EarPlayed.text = "Ear(s): \(self.ear)"
        })
    }
    
    
    //MARK: Messaging
//    func newMessageIncoming(notification: NSNotification) {
//        freq = comms.freq
//        vol = comms.vol
//        ear = comms.ear
//        updateUI()
//    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    
}
