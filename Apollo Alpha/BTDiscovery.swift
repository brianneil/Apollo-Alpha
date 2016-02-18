//
//  BTDiscovery.swift
//  BLEDemo
//
//  Created by Brian Neil on 2/16/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//

import UIKit
import CoreBluetooth

let btDiscoverySharedInstance = BTDiscovery();

class BTDiscovery: NSObject, CBCentralManagerDelegate {
    
    private var centralManager: CBCentralManager?
    private var peripheral: CBPeripheral?
    
    override init() {
        super.init()
        
        let centralQueue = dispatch_queue_create("com.apollhearing", DISPATCH_QUEUE_SERIAL) //Creates a seperate thread we can use to handle BLE stuff?
        centralManager = CBCentralManager(delegate: self, queue: centralQueue) //Sets the delegate to us and tell the central manager to run on the new thread
    }

    func startScanning() {
        if let central = centralManager {
            central.scanForPeripheralsWithServices([BLEServiceUUID], options: nil)
        }
    }
    
    var bleService: BTService? {
        didSet {
            if let service = self.bleService {
                service.startDiscoveringServices()
            }
        }
    }
    
    //MARK: CBCentralManagerDelegate
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        //Validate peripheral info
        if ((peripheral.name == nil) || (peripheral.name == "")) {
            return
        }
        
        //If not connected to a peripheral, then connect to this one
        if (self.peripheral == nil || self.peripheral?.state == CBPeripheralState.Disconnected) {
            //retain the peripheral before trying to connect
            self.peripheral = peripheral
            
            //reset service
            self.bleService = nil
            
            //connect to peripheral
            central.connectPeripheral(peripheral, options: nil)
            
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        //Create new service class
        if peripheral == self.peripheral {
            self.bleService = BTService(initWithPeripheral: peripheral)
        }
        
        //Stop scanning
        central.stopScan()
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        //Confirm that it was our peripheral that disconnected and then clean house
        if peripheral == self.peripheral {
            clearDevices()
        }
        
        //start scanning for new devices
        self.startScanning()
    }
    
    
    func clearDevices() {
        self.bleService = nil
        self.peripheral = nil
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
        case .PoweredOff:
            clearDevices()
        case .Unauthorized: break   //Means that the device does not support BLE
        case .Unknown: break        //Wait for another event to occur
        case .PoweredOn:
            self.startScanning() //First time powered up, scan
        case .Resetting:
            clearDevices()
        case .Unsupported: break
        }
    }
}
