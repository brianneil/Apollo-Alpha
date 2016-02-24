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
    
    let apolloBlue = UIColor(red: 0, green: 173/255, blue: 238/255, alpha: 1)
    let apolloLightBlue = UIColor(red: 0, green: 173/255, blue: 238/255, alpha: 0.35)
    
    let numberOfSmallRects: CGFloat = 20
    let smallRectWidthPercentage: CGFloat = 1.0
    let smallRectHeightPercentage: CGFloat = 0.85
    
    
    var smallRectSize: CGSize {
        let width = columnSize.width * smallRectWidthPercentage
        let height = (columnSize.height / numberOfSmallRects) * smallRectHeightPercentage
        return CGSize(width: width, height: height)
    }
    
    var smallRectGap: CGFloat {
        return columnSize.height / numberOfSmallRects * (CGFloat(1) - smallRectHeightPercentage)
    }
    
    var columnSize: CGSize {
        let width = HTBarsView.bounds.width/numberOfColumns * columnWidthPercentage
        let height = HTBarsView.bounds.height * columnHeightPercentage
        return CGSize(width: width, height: height)
    }
    var columnGap: CGFloat {
        return HTBarsView.bounds.width/numberOfColumns * (CGFloat(1) - columnWidthPercentage)
    }
    
    var columnViews: [UIView] = []      // a place to store the columns
    var smallRects: [[UIView]] = [[]]   //A place to store all of the small rects
    
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
    
    //String constants
    private struct StringConstants {
        static let rightEar = "Right Ear Testing"
        static let leftEar = "Left Ear Testing"
    }
    
    //Test constants
    private struct TestConstants {
        static let StartingVolume = 75
        static let VolumeDecrement = 10
        static let VolumeIncrease = 5
        static let StartingFrequency: Freqs = Freqs.Hz125
        static let StartingEar: Ears = Ears.rightEar
    }
    
    //Enums and Structs
    
    enum PresentationModes {
        case ascending
        case descending
    }
    
    enum Ears {     //NOTE: This order and position has to match exactly on the peripheral
        case rightEar
        case leftEar
        case bothEars
    }
    
    enum Freqs {    //NOTE: This order and position has to match exactly on the peripheral
        case dummy
        case Hz125
        case Hz250
        case Hz500
        case Hz1000
        case Hz2000
        case Hz3000
        case Hz4000
        case Hz8000
    }
    
    struct Tone {
        var frequency: Freqs
        var ear: Ears
        var volume: Int
    }
    
    struct FrequencyTest {
        var tone: Tone
        var currentMode: PresentationModes
        var thresholds: [Int]                   //For holding the frequencies that the user thresholds on.
        var finalThreshold: Int?                     //This will store the final volume threshold
    }
    
    var finalResults: [FrequencyTest] = []
    private var currentTest: FrequencyTest? = nil

    
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
    
    @IBOutlet weak var EarLabel: UILabel!
    
    //MARK: Drawing
    
    func drawColumns() {
        for xIndex in 0..<Int(numberOfColumns) {
            let xPos = columnGap/2 + (columnGap + columnSize.width) * CGFloat(xIndex)   //Creates a columngap/2 space at each end
            
            let columnOrigin = CGPoint(x: xPos, y: yOffset)
            let frame = CGRect(origin: columnOrigin, size: columnSize)
            
            let columnView = UIView(frame: frame)
            columnView.layer.borderColor = apolloBlue.CGColor
            columnView.layer.borderWidth = columnBorderWidth
//            columnView.layer.cornerRadius = columnRadius
            
            columnViews.append(columnView)
            
            HTBarsView.addSubview(columnViews[xIndex])
        }
    }
    
    func drawSmallRects(column column: Int) {
        smallRects.append([])   //Create a blank new column in the array
        let frame = columnViews[column].frame
        let xPos = frame.origin.x
        let yOffset = frame.origin.y
        for yIndex in 0..<Int(numberOfSmallRects) {
            let yPos = smallRectGap/2 + (smallRectGap + smallRectSize.height) * CGFloat(yIndex) + yOffset
            
            let smallRectOrigin = CGPoint(x: xPos, y: yPos)
            let frame = CGRect(origin: smallRectOrigin, size: smallRectSize)
            
            let smallRectView = UIView(frame: frame)
            smallRectView.backgroundColor = apolloLightBlue
            
            smallRects[column].append(smallRectView)
            
            HTBarsView.addSubview(smallRects[column][yIndex])
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
        //Start the test up
        if currentTest == nil {
            let tone = Tone(frequency: TestConstants.StartingFrequency, ear: TestConstants.StartingEar, volume: TestConstants.StartingVolume)
            currentTest = FrequencyTest(tone: tone, currentMode: .descending, thresholds: [], finalThreshold: nil)
            comms.SendMessageToPeripheral(tone)
        }
        
        
        //Set up message received notification watcher, call messageReceived if we get something
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "newMessageIncoming:", name: messageParsedNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        drawColumns()
        drawSmallRects(column: 0)
        EarLabel.text = StringConstants.rightEar
        
    }
    
    //MARK: Brains
    func missedATone() {
//        if comms.dataFromPeripheral.freq == CommunicationCenter.Freqs.Hz8000 {      //Meaning we're at the last frequency
//            if comms.dataFromPeripheral.ear == CommunicationCenter.Ears.leftEar {   //Meaning we're at the last ear
//                //Display final results
//            } else {
//                print("\(columnViews.count)")
//                for columnIndex in 0..<columnViews.count {      //Get rid of all the small rects then add the first column back
//                    for smallRect in smallRects[columnIndex] {
//                        smallRect.removeFromSuperview()
//                    }
//                }
//                smallRects.removeAll()
//                drawSmallRects(column: 0)
//                EarLabel.text = StringConstants.leftEar
//                comms.SendMessageToPeripheral(CommunicationCenter.OutgoingMessageType.nextEar)
//            }
//        } else {
//            for smallRect in smallRects[comms.dataFromPeripheral.freq.hashValue] {  //Darken the current small rects
//                smallRect.backgroundColor = apolloBlue
//            }
//            drawSmallRects(column: comms.dataFromPeripheral.freq.hashValue + 1) //Draw the next column of small rects
//            comms.SendMessageToPeripheral(CommunicationCenter.OutgoingMessageType.nextFrequency)
//            
//        }
    }
    
    func readyForNextTone() {
//        comms.SendMessageToPeripheral(CommunicationCenter.OutgoingMessageType.lowerVolume)
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
