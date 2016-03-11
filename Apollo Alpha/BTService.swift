//
//  BTService.swift
//  BLEDemo
//
//  Created by Brian Neil on 2/17/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//

import Foundation
import CoreBluetooth

//let BLEServiceUUID = CBUUID(string: "025A7775-49AA-42BD-BBDB-E2AE77782966") //This is for the Black Widow
//let talkCharacteristicUUID = CBUUID(string: "F38A2C23-BC54-40FC-BED0-60EDDA139F47") //For Black Widow
//let listenCharacteristicUUID = CBUUID(string: "A9CD2F86-8661-4EB1-B132-367A3434BC90")   //For Black Widow

let BLEServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") //This is for the Nordic
let talkCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") //For Nordic
let listenCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")   //For Nordic

let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"
let messageFromPeripheralNotification = "kBLEMessageFromController"

class BTService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var beepCharacteristic: CBCharacteristic?
    var listenCharacteristic: CBCharacteristic?
    
    private struct constants {
        static let isConnectedKey = "isConnected"
        static let dataKey = "MessageFromPeripheral"
    }
    
    private var TimerTXDelay: NSTimer?
    private var allowTX = true
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()
        self.peripheral = peripheral
        self.peripheral?.delegate = self //establishes us as the delegate
    }
    
    deinit {
        reset()
        stopTimerTXDelay()
    }
    
    func startDiscoveringServices() {
        peripheral?.discoverServices([BLEServiceUUID])
    }
    
    func reset() {
        if peripheral != nil {
            peripheral = nil
        }
        //Since we're deallocating, we should send a notification
        sendBTServiceNotificationWithIsBTEConnected(false)
        
    }
    
    //MARK: CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        let uuidsForBTService: [CBUUID] = [talkCharacteristicUUID, listenCharacteristicUUID] //Look for both characteristics
        
        if peripheral != self.peripheral {
            //we grabbed the wrong one
            return
        }
        
        if error != nil {
            return
        }
        
        if peripheral.services == nil || peripheral.services!.count == 0 {
            //there are no services, bail
            return
        }
        
        for service in peripheral.services! {   //Safe unwrap, we checked nil and 0 above
            if service.UUID == BLEServiceUUID { //If it's the service we've got as a constant above
                peripheral.discoverCharacteristics(uuidsForBTService, forService: service)  //Try to grab the service that we're looking for
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        if peripheral != self.peripheral {
            //wrong peripheral
            return
        }
        
        if error != nil {
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.UUID == talkCharacteristicUUID {        //If we have the talk characteristic, grab it
                    self.beepCharacteristic = characteristic
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic) //Establishes notifications on this characteristic if the value changes
                    
                    //Send the notification that we've connected
                    sendBTServiceNotificationWithIsBTEConnected(true)
                }
                if characteristic.UUID == listenCharacteristicUUID {    //If we have the listen characteristic, grab it
                    self.listenCharacteristic = characteristic
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if peripheral != self.peripheral {
            //got the wrong peripheral somehow
            return
        }
        
        if error != nil {
            print("Error in the peripheral update value func")
        }
        
        if let data = characteristic.value {
            var dataAsInt: Int = 0
            var didFire: Bool = false
            
            data.getBytes(&dataAsInt, length: sizeof(NSInteger))    //This might be hackery, got it off StackOverflow
            if dataAsInt == 1 {
                didFire = true
            }
            
            let inputDetail = [constants.dataKey: didFire]        //Create a dictionary to send back the view controller.
            NSNotificationCenter.defaultCenter().postNotificationName(messageFromPeripheralNotification, object: self, userInfo: inputDetail)   //Posts the notification
        }
    }
    
    func createOutgoingMessage(messages: [UInt8]) {
        //1st, check that allowTX is armed again
        if !allowTX {
            return
        }
        
        //Then grab one line of the message and send it out
        for message in messages {
            writeMessage(message)
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

    
    func writeMessage(message: UInt8) {
        //First check that we discovered a characteristic before we write to it
        if let beepCharacteristic = self.beepCharacteristic {
            //create a mutable var to pass to the writeValue fxn
            var messageValue = message
            let data = NSData(bytes: &messageValue, length: sizeof(UInt8))  //Create a bag of bits
            print("\(message)")
            print("\(data)")
            self.peripheral?.writeValue(data, forCharacteristic: beepCharacteristic, type: CBCharacteristicWriteType.WithResponse)  //Send the bag of bits
        }
    }
    
    
    
    
    func sendBTServiceNotificationWithIsBTEConnected(isBTEConnected: Bool){
        let connectionDetails = [constants.isConnectedKey: isBTEConnected] //Creates a key:value for BTE connection
        NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification,object: self, userInfo: connectionDetails) //Posts the notification
    }
    
    
    
}
