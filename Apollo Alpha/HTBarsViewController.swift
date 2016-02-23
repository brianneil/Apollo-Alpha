//
//  HTBarsViewController.swift
//  Apollo Alpha
//
//  Created by Brian Neil on 2/22/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//

import UIKit
import Foundation

class HTBarsViewController: UIViewController {
    
    //MARK: Constants/Setup
    
    let numberOfColumns: CGFloat = 8
    
    let columnWidthPercentage: CGFloat = 0.8  //The percent width of the screen the columns take up
    
    let columnHeightPercentage: CGFloat = 0.9 //The percent height of the screen the columns take up
    
    let yOffset: CGFloat = 10
    
    let columnRadius: CGFloat = 5
    let columnBorderWidth: CGFloat = 1
    
    let apolloBlue = UIColor(red: 0, green: 173/255, blue: 238/255, alpha: 100)
    
    var columnSize: CGSize {
        let width = HTBarsView.bounds.width/numberOfColumns * columnWidthPercentage
        let height = HTBarsView.bounds.height * columnHeightPercentage
        return CGSize(width: width, height: height)
    }
    
    var columnGap: CGFloat {
        return HTBarsView.bounds.width/numberOfColumns * (CGFloat(1) - columnWidthPercentage)
    }
    
    var columnViews: [UIView] = []      // a place to store the columns
    
    //Instances
    let comms = CommunicationCenter()
    
    //Other variables
    private var beepReactionTimer: NSTimer? = nil
    private var beepDelayTimer: NSTimer? = nil
    
    //Timer constants
    private struct timeConstants {
        static let reactionTimeAllowed = 3.0
        static let delayBetweenBeeps = 3.0
    }
    

    
    //MARK: UI outlets
    
    @IBOutlet weak var HTBarsView: UIImageView!
    
    @IBAction func TappedHere(sender: UIButton) {
        //start a timer that delays the next beep
        stopBeepReactionTimer() //They hit it before the reaction timer elapsed, so kill that timer until the next beep
        dispatch_async(dispatch_get_main_queue(), { [unowned self] in
            if self.beepDelayTimer == nil {
                self.beepDelayTimer = NSTimer.scheduledTimerWithTimeInterval(timeConstants.delayBetweenBeeps, target: self, selector: Selector("beepDelayTimerElapsed"), userInfo: nil, repeats: false)
            }
        })
    }
    
    
    //MARK: Drawing
    
    func drawColumns() {
        for xIndex in 0..<Int(numberOfColumns) {
            let xPos = columnGap/2 + (columnGap + columnSize.width) * CGFloat(xIndex)   //Creates a columngap/2 space at each end
            
            let columnOrigin = CGPoint(x: xPos, y: yOffset)
            let frame = CGRect(origin: columnOrigin, size: columnSize)
            
            let columnView = UIView(frame: frame)
            columnView.layer.borderColor = apolloBlue.CGColor
            columnView.layer.borderWidth = columnBorderWidth
            columnView.layer.cornerRadius = columnRadius
            
            columnViews.append(columnView)
            
            HTBarsView.addSubview(columnViews[xIndex])
        }
    }
    
    
    //MARK: Lifecycle
    deinit {
        //kill the notificaton observer and timers on the way out
        NSNotificationCenter.defaultCenter().removeObserver(self, name: messageParsedNotification, object: nil)
        stopBeepReactionTimer()
        stopBeepDelayTimer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Hearing Test"
        //beepReactionTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("beepReactionTimerElapsed"), userInfo: nil, repeats: false)
        
        //Set up message received notification watcher, call messageReceived if we get something
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "newMessageIncoming:", name: messageParsedNotification, object: nil)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        drawColumns()
    }
    
    //MARK: Brains
    func missedATone() {
        if comms.dataFromPeripheral.freq == CommunicationCenter.Freqs.Hz8000 {      //Meaning we're at the last frequency
            if comms.dataFromPeripheral.ear == CommunicationCenter.Ears.leftEar {   //Meaning we're at the last ear
                //Display final results
            } else {
                comms.SendMessageToPeripheral(CommunicationCenter.OutgoingMessageType.nextEar)
                for columnView in columnViews {
                    columnView.backgroundColor = UIColor.whiteColor()
                }
            }
        } else {
            comms.SendMessageToPeripheral(CommunicationCenter.OutgoingMessageType.nextFrequency)
            columnViews[comms.dataFromPeripheral.freq.hashValue].backgroundColor = apolloBlue
        }
    }
    
    func readyForNextTone() {
        comms.SendMessageToPeripheral(CommunicationCenter.OutgoingMessageType.lowerVolume)
    }
    
    func newMessageIncoming(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), { [unowned self] in
            if self.beepReactionTimer == nil {
                self.beepReactionTimer = NSTimer.scheduledTimerWithTimeInterval(timeConstants.reactionTimeAllowed, target: self, selector: Selector("beepReactionTimerElapsed"), userInfo: nil, repeats: false)
            }
        })
    }
    
    func beepReactionTimerElapsed() {
        stopBeepReactionTimer()
        missedATone()
    }
    
    func stopBeepReactionTimer() {
        if beepReactionTimer == nil {
            return
        }
        beepReactionTimer?.invalidate()
        beepReactionTimer = nil
    }
    
    func beepDelayTimerElapsed() {
        stopBeepDelayTimer()
        readyForNextTone()
    }
    
    func stopBeepDelayTimer() {
        if beepDelayTimer == nil {
            return
        }
        beepDelayTimer?.invalidate()
        beepDelayTimer = nil
    }

}
