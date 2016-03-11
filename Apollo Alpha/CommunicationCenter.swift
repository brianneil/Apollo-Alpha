//
//  CommunicationCenter.swift
//  Apollo Alpha
//
//  Created by Brian Neil on 2/22/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//

import Foundation

let PeripheralBeepedNotification = "kBLEMessageReceived"

class CommunicationCenter: NSObject {
    
    private struct constants {
        static let dataKey = "MessageFromPeripheral"
        static let StartListening: UInt8 = 1
    }
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivedMessage:", name: messageFromPeripheralNotification, object: nil)
    }

    deinit {
        //kill the notificaton observer
        NSNotificationCenter.defaultCenter().removeObserver(self, name: messageFromPeripheralNotification, object: nil)
    }

    func receivedMessage(notification: NSNotification) {
        if let message = notification.userInfo as? [String: Bool] {
            if let didFire = message[constants.dataKey] {
                if didFire {
                    sendPeripheralBeepedNotification()
                }
            }
        }
    }
    
    func SendMessageToPeripheral(tone: HTBarsViewController.Tone) {
        if let bleService = btDiscoverySharedInstance.bleService {  //We have somewhere to send the message, so build it.
            var messages: [UInt8] = []
            messages.append(constants.StartListening)    //1st tell the peripheral a message is about to hit
            messages.append(UInt8(tone.frequency.hashValue))
            messages.append(UInt8(tone.volume))
            messages.append(UInt8(tone.ear.hashValue))
            
            bleService.createOutgoingMessage(messages)
        }
    }
    
    private func sendPeripheralBeepedNotification(){
        NSNotificationCenter.defaultCenter().postNotificationName(PeripheralBeepedNotification, object: self) //Posts the notification
    }
}