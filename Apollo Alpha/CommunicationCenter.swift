//
//  CommunicationCenter.swift
//  Apollo Alpha
//
//  Created by Brian Neil on 2/22/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//

import Foundation

let messageParsedNotification = "kBLEMessageReceived"

class CommunicationCenter: NSObject {
    
    private let earDictionary = [incomingMessages.bothEars: Ears.bothEars, incomingMessages.leftEar: Ears.leftEar, incomingMessages.rightEar: Ears.rightEar]
    private let freqDictionary = [incomingMessages.f125HZ: Freqs.Hz125, incomingMessages.f250HZ: Freqs.Hz250, incomingMessages.f500HZ: Freqs.Hz500, incomingMessages.f1KHZ: Freqs.Hz1000, incomingMessages.f2KHZ: Freqs.Hz2000, incomingMessages.f3KHZ: Freqs.Hz3000, incomingMessages.f4KHZ: Freqs.Hz4000, incomingMessages.f8KHZ: Freqs.Hz8000]
    
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
        static let f125HZ = 1    //Make sure this matches the peripheral code
        static let f250HZ = 2
        static let f500HZ = 3
        static let f1KHZ = 4
        static let f2KHZ = 5
        static let f3KHZ = 6
        static let f4KHZ = 7
        static let f8KHZ = 8
    }
    
    private struct OutgoingMessages {   //This needs to match the enumerated list on the peripheral
        static let startListening: UInt8 = 0
        static let sameFreq: UInt8  = 1
        static let nextFreq: UInt8  = 2
        static let lastFreq: UInt8  = 3
        static let resetFreq: UInt8 = 4
        static let sameVol: UInt8  = 5
        static let resetVol: UInt8 = 6
        static let higherVol: UInt8  = 7
        static let lowerVol: UInt8  = 8
        static let bothEars: UInt8  = 9
        static let sameEar: UInt8  = 10
        static let newEar: UInt8  = 11
        static let testBeep: UInt8  = 12
    }
    
    struct BeepData {
        var freq: Freqs = Freqs.Hz250
        var vol: Int = 0
        var ear: Ears = Ears.bothEars
    }
    
    enum Ears {
        case rightEar
        case leftEar
        case bothEars
    }
    
    enum Freqs {
        case Hz125
        case Hz250
        case Hz500
        case Hz1000
        case Hz2000
        case Hz3000
        case Hz4000
        case Hz8000
    }
    
    enum OutgoingMessageType {
        case playFirstBeep
        case nextFrequency
        case lowerVolume
        case nextEar
    }
    
    var dataFromPeripheral = BeepData()
    
    
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "receivedMessage:", name: messageFromPeripheralNotification, object: nil)
    }

    deinit {
        //kill the notificaton observer
        NSNotificationCenter.defaultCenter().removeObserver(self, name: messageFromPeripheralNotification, object: nil)
    }

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
                    dataFromPeripheral.freq = freqValue           //Grab the frequency and then change the state
                }
                self.state = .listeningForVolume
            case .listeningForVolume:
                dataFromPeripheral.vol = message       //Grab the volume then change state
                self.state = .listeningForEar
            case .listeningForEar:
                if let earValue = earDictionary[message] {
                    dataFromPeripheral.ear = earValue
                }
                //Now that we have the information, send it out
                sendMessageParsedNotification()
                self.state = .notListening  //We've got everything stop listening
            }
        }
    }
    
    func SendMessageToPeripheral(messageType: OutgoingMessageType) {
        if let bleService = btDiscoverySharedInstance.bleService {  //We have somewhere to send the message, so build it.
            var messages: [UInt8] = []
            messages.append(OutgoingMessages.startListening)    //1st tell the peripheral a message is about to hit
            switch messageType {
            case .playFirstBeep:
                messages.append(OutgoingMessages.sameFreq)
                messages.append(OutgoingMessages.sameVol)
                messages.append(OutgoingMessages.sameEar)
            case .lowerVolume:
                messages.append(OutgoingMessages.sameFreq)
                messages.append(OutgoingMessages.lowerVol)
                messages.append(OutgoingMessages.sameEar)
            case .nextFrequency:
                messages.append(OutgoingMessages.nextFreq)
                messages.append(OutgoingMessages.resetVol)
                messages.append(OutgoingMessages.sameEar)
            case .nextEar:
                messages.append(OutgoingMessages.resetFreq)
                messages.append(OutgoingMessages.resetVol)
                messages.append(OutgoingMessages.newEar)
            }
            bleService.createOutgoingMessage(messages)
        }
    }
    
    private func sendMessageParsedNotification(){
        NSNotificationCenter.defaultCenter().postNotificationName(messageParsedNotification, object: self) //Posts the notification
    }
    
    
    
    
    
    
    
}