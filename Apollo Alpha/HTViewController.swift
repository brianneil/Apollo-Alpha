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
    
    private let earDictionary = [incomingMessages.bothEars: "Both", incomingMessages.leftEar: "Left", incomingMessages.rightEar: "Right"]
    private let freqDictionary = [incomingMessages.fiveHundredHz: 500, incomingMessages.oneKHz: 1000, incomingMessages.twoKHz: 2000]
    
    
    private var state: listeningState = .notListening       //A variable to hold our current status. Started as not listening.
    
    private struct constants {
        static let dataKey = "MessageFromPeripheral"
    }
    
    private enum listeningState {
        case notListening
        case listeningForFrequency
        case listeningForVolume
        case listeningForEar
    }
    
    private struct incomingMessages {
        static let startListening = 1
        static let bothEars = 17
        static let leftEar = 27
        static let rightEar = 37
        static let fiveHundredHz = 1    //Make sure this matches the peripheral code
        static let oneKHz = 2
        static let twoKHz = 3
    }
    
    private struct OutgoingMessages {
        static let startListening: UInt8 = 0
        static let sameFreq: UInt8  = 1
        static let nextFreq: UInt8  = 2
        static let lastFreq: UInt8  = 3
        static let sameVol: UInt8  = 4
        static let higherVol: UInt8  = 5
        static let lowerVol: UInt8  = 6
        static let bothEars: UInt8  = 7
        static let leftEar: UInt8  = 8
        static let rightEar: UInt8  = 9
        static let testBeep: UInt8  = 10
    }
    
    //MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Hearing Test"
        
        //Set up message received notification watcher, call messageReceived if we get something
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivedMessage:", name: messageFromPeripheralNotification, object: nil)
        
    }
    
    deinit {
        //kill the notificaton observer and timer on the way out
        NSNotificationCenter.defaultCenter().removeObserver(self, name: messageFromPeripheralNotification, object: nil)
    }

    //MARK: UI
    
    @IBOutlet weak var Volume: UILabel!
    
    @IBOutlet weak var Frequency: UILabel!

    @IBOutlet weak var EarPlayed: UILabel!
    
    @IBAction func wasHeard(sender: UIButton) {
        wasHeardSendMessage();
    }
    
    func updateUI() {
        dispatch_async(dispatch_get_main_queue(), { [unowned self] in
            self.Frequency.text = "Frequency (Hz): \(self.freq)"
            self.Volume.text = "Volume (dB): \(self.vol)"
            self.EarPlayed.text = "Ear(s): \(self.ear)"
        })
    }
    
    
    
    //MARK: Messaging
    func receivedMessage(notification: NSNotification) {
        let messageDictionary = notification.userInfo as! [String: Int]
        if let message = messageDictionary[constants.dataKey] {
            switch state {
            case .notListening:
                if message == incomingMessages.startListening { //If we aren't listening, and we are told to listen, start listening
                    self.state = .listeningForFrequency
                }
            case .listeningForFrequency:
                if let freqValue = freqDictionary[message] {
                    self.freq = freqValue           //Grab the frequency and then change the state
                }
                self.state = .listeningForVolume
            case .listeningForVolume:
                self.vol = message       //Grab the volume then change state
                self.state = .listeningForEar
            case .listeningForEar:
                if let earValue = earDictionary[message] {
                    self.ear = earValue
                }
                updateUI()          //Go update all the values
                self.state = .notListening  //We've got everything stop listening
            }
        }
    }
    
    func wasHeardSendMessage() {
        if let bleService = btDiscoverySharedInstance.bleService {  //We have somewhere to send the message, so build it.
            var messages: [UInt8] = []
            messages.append(OutgoingMessages.startListening)    //1st tell the peripheral a message is about to hit
            messages.append(OutgoingMessages.sameFreq)          //Play the same sound at a lower volume
            messages.append(OutgoingMessages.lowerVol)
            messages.append(OutgoingMessages.bothEars)
            bleService.createOutgoingMessage(messages)
        }
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
