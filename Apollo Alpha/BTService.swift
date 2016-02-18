//
//  BTService.swift
//  BLEDemo
//
//  Created by Brian Neil on 2/17/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//

import Foundation
import CoreBluetooth

let BLEServiceUUID = CBUUID(string: "025A7775-49AA-42BD-BBDB-E2AE77782966")
let BeepUUID = CBUUID(string: "F38A2C23-BC54-40FC-BED0-60EDDA139F47")
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

class BTService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var beepCharacteristic: CBCharacteristic?
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()
        self.peripheral = peripheral
        self.peripheral?.delegate = self //establishes us as the delegate
    }
    
    deinit {
        reset()
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
        let uuidsForBTService: [CBUUID] = [BeepUUID]
        
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
                if characteristic.UUID == BeepUUID {        //If we have the right characteristic, grab it
                    self.beepCharacteristic = characteristic
                    peripheral.setNotifyValue(true, forCharacteristic: characteristic) //Establishes listening on this characteristic
                    
                    //Send the notification that we've connected
                    sendBTServiceNotificationWithIsBTEConnected(true)
                }
            }
        }
    }
    
    func writeMessage(message: UInt8) {
        //First check that we discovered a characteristic before we write to it
        if let beepCharacteristic = self.beepCharacteristic {
            //create a mutable var to pass to the writeValue fxn
            var messageValue = message
            let data = NSData(bytes: &messageValue, length: sizeof(UInt8))  //Create a bag of bits
            self.peripheral?.writeValue(data, forCharacteristic: beepCharacteristic, type: CBCharacteristicWriteType.WithResponse)  //Send the bag of bits
        }
    }
    
    
    
    
    func sendBTServiceNotificationWithIsBTEConnected(isBTEConnected: Bool){
        let connectionDetails = ["isConnected": isBTEConnected] //Creates a key:vale for BTE connection
        NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification,object: self, userInfo: connectionDetails) //Posts the notification
    }
    
    
    
}
