//
//  TestUIVC.swift
//  Apollo Alpha
//
//  Created by Brian Neil on 3/29/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//

import UIKit

class TestUIVC: UIViewController {

    
    private var beepReactionTimer: NSTimer? = nil //We need to do timer handling as well
    
    let comms = CommunicationCenter()
    
    private struct timeConstants {
        static let reactionTimeAllowed = 2.0        //This is the length of the beep. They must press during the beep.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Test Beep"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HTBarsViewController.ToneWasPlayed), name: PeripheralBeepedNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        ReadyButton.hidden = false
        TapHereButton.hidden = true
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: PeripheralBeepedNotification, object: nil)
        
        //Kill the timer!
    }
    
    
    private struct constants {
        static let TestFreq = HTBarsViewController.Freqs.Hz1000
        static let TestEar = HTBarsViewController.Ears.bothEars
        static let TestVol = 60
    }
    
    @IBOutlet weak var ReadyButton: UIButton!
    
    
    @IBOutlet weak var TapHereButton: UIButton!
    
    
    @IBAction func ReadyForTone(sender: UIButton) {
        //Hide this button, make other one visible, delay a half second, send the beep info
        ReadyButton.hidden = true
        TapHereButton.hidden = false
        
    }
    
    
    @IBAction func HeardTone(sender: UIButton) {
        
    }
    
}
