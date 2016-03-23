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
    
    struct DrawingConstantStruct {
        let numberOfColumns: CGFloat = 6
        let columnWidthPercentage: CGFloat = 0.85  //The percent width of the screen the columns take up
        let columnHeightPercentage: CGFloat = 0.9 //The percent height of the view the columns take up
        let yOffset: CGFloat = 10
        let columnRadius: CGFloat = 5
        let columnBorderWidth: CGFloat = 1
        
        let apolloBlue = UIColor(red: 0, green: 173/255, blue: 238/255, alpha: 1)
        let apolloLightBlue = UIColor(red: 0, green: 173/255, blue: 238/255, alpha: 0.35)
        
        let numberOfSmallRects: CGFloat = 30
        let smallRectWidthPercentage: CGFloat = 1.0
        let smallRectHeightPercentage: CGFloat = 0.85
        
        var columnSize: CGSize
        var columnGap: CGFloat
        var smallRectSize: CGSize
        var smallRectGap: CGFloat
        
        init(barView: UIView) {
            
            let width = barView.bounds.width/numberOfColumns * columnWidthPercentage
            let height = barView.bounds.height * columnHeightPercentage
            columnSize = CGSize(width: width, height: height)
            
            columnGap = barView.bounds.width/numberOfColumns * (CGFloat(1) - columnWidthPercentage)

            let rectWidth = columnSize.width * smallRectWidthPercentage
            let rectHeight = (columnSize.height / numberOfSmallRects) * smallRectHeightPercentage
            smallRectSize = CGSize(width: rectWidth, height: rectHeight)
            
            smallRectGap = columnSize.height / numberOfSmallRects * (CGFloat(1) - smallRectHeightPercentage)
        }
    }
    
    var columnViews: [UIView] = []      // a place to store the columns
    var smallRects: [[UIView]] = [[]]   //A place to store all of the small rects
    
    //Instances
    let comms = CommunicationCenter()
    var drawingConstants: DrawingConstantStruct?
    
    //Other variables
    private var beepReactionTimer: NSTimer? = nil
    private var beepDelayTimer: NSTimer? = nil
    var isBeeping: Bool = false
    
    //Timer constants
    private struct timeConstants {
        static let reactionTimeAllowed = 2.0        //This is the length of the beep. They must press during the beep.
    }
    
    var delayAfterTap: Double {
        return Double(arc4random_uniform(4)) + 2.0    //Returns a random int between 2 and 4.
    }
    
    //String constants
    private struct StringConstants {
        static let rightEar = "Right Ear Testing"
        static let leftEar = "Left Ear Testing"
    }
    
    //Test constants
    private struct TestConstants {
        static let StartingVolume = [50, 50, 60, 60, 65, 65]
        static let VolumeDecrement = 10
        static let VolumeIncrease = 5
        static let LowestAllowedVolume = 235
        static let HighestAllowedVolume = 6
        static let StartingFrequency: Freqs = Freqs.Hz250
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
    
    enum Freqs: Int {    //NOTE: This order and position has to match exactly on the peripheral
        case dummy = 0
        case Hz250
        case Hz500
        case Hz1000
        case Hz2000
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
    
    var finalResults: [Int] = []
    private var currentTest: FrequencyTest? = nil
    private var messagePrepped = false

    
    //MARK: UI outlets
    
    @IBOutlet weak var HTBarsView: UIImageView!
    
    @IBAction func TappedHere(sender: UIButton) {
        //start a timer that delays the next beep
        if(isBeeping) {  //Need this if statement to so we ignore false taps (i.e. taps when the tone isn't playing).
            CaughtATone()   //Tell the brain we caught a tone.
            dispatch_async(dispatch_get_main_queue(), { [unowned self] in
                if self.beepDelayTimer == nil {
                    self.beepDelayTimer = NSTimer.scheduledTimerWithTimeInterval(self.delayAfterTap, target: self, selector: Selector("DelayAfterTapTimerElapsed"), userInfo: nil, repeats: false)
                }
                })
        }
        StopBeepReactionTimer() //They hit it before the reaction timer elapsed, so kill that timer until the next beep
    }
    
    @IBOutlet weak var EarLabel: UILabel!
    
    //MARK: Drawing
    
    func drawColumns() {
        for xIndex in 0..<Int(drawingConstants!.numberOfColumns) {
            let xPos = drawingConstants!.columnGap/2 + (drawingConstants!.columnGap + drawingConstants!.columnSize.width) * CGFloat(xIndex)   //Creates a columngap/2 space at each end
            
            let columnOrigin = CGPoint(x: xPos, y: drawingConstants!.yOffset)
            let frame = CGRect(origin: columnOrigin, size: drawingConstants!.columnSize)
            
            let columnView = UIView(frame: frame)
            columnView.layer.borderColor = drawingConstants!.apolloBlue.CGColor
            columnView.layer.borderWidth = drawingConstants!.columnBorderWidth
            
            columnViews.append(columnView)
            
            HTBarsView.addSubview(columnViews[xIndex])
        }
    }
    
    func DrawSmallRects(column column: Int) {
        smallRects.append([])   //Create a blank new column in the array
        let frame = columnViews[column].frame
        let xPos = frame.origin.x
        let yOffset = frame.origin.y
        for yIndex in 0..<Int(drawingConstants!.numberOfSmallRects) {
            let yPos = drawingConstants!.smallRectGap/2 + (drawingConstants!.smallRectGap + drawingConstants!.smallRectSize.height) * CGFloat(yIndex) + yOffset
            
            let smallRectOrigin = CGPoint(x: xPos, y: yPos)
            let frame = CGRect(origin: smallRectOrigin, size: drawingConstants!.smallRectSize)
            
            let smallRectView = UIView(frame: frame)
            smallRectView.backgroundColor = drawingConstants!.apolloLightBlue
            
            smallRects[column].append(smallRectView)
            
            HTBarsView.addSubview(smallRects[column][yIndex])
        }
    }
    
    func RemoveSmallRects() {
        for columnIndex in 0..<columnViews.count {      //Get rid of all the small rects then add the first column back
            for smallRect in smallRects[columnIndex] {
                smallRect.removeFromSuperview()
            }
        }
        smallRects.removeAll()
        DrawSmallRects(column: 0)
    }
    
    func DarkenSmallRects(column column: Int) {
        for smallRect in smallRects[column] {
            smallRect.backgroundColor = drawingConstants!.apolloBlue
        }
    }
    
    func updateEarLabel() {
        if let currentEar = currentTest?.tone.ear {
            switch currentEar {
            case .bothEars: break
            case .leftEar: EarLabel.text = StringConstants.leftEar
            case .rightEar: EarLabel.text = StringConstants.rightEar
            }
        }
    }
    
    
    //MARK: Lifecycle
    deinit {
        //kill the notificaton observer and timers on the way out
        NSNotificationCenter.defaultCenter().removeObserver(self, name: PeripheralBeepedNotification, object: nil)
        StopBeepReactionTimer()
        StopBeepDelayTimer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Hearing Test"
        
        //Set up the test
        if currentTest == nil {
            let tone = Tone(frequency: TestConstants.StartingFrequency, ear: TestConstants.StartingEar, volume: TestConstants.StartingVolume[0])
            currentTest = FrequencyTest(tone: tone, currentMode: .descending, thresholds: [], finalThreshold: nil)
            SendMessage(currentTest!.tone)
        }
        
        
        //Set up message received notification watcher, call messageReceived if we get something
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "ToneWasPlayed", name: PeripheralBeepedNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        drawingConstants = DrawingConstantStruct.init(barView: HTBarsView)      //Initialize the constants after the view is laid down
        drawColumns()
        DrawSmallRects(column: 0)
        updateEarLabel()
        
    }
    
    //MARK: Messages
    func SendMessage(tone: Tone) {
        comms.SendMessageToPeripheral(tone)
    }
    
    //MARK: Brains
    func MissedATone() {
       //Set mode to ascending, increase the volume. Bounds checking added so that we don't crash by sending UInt a value lower than 0.
        if currentTest != nil {
            if currentTest!.tone.volume <= TestConstants.HighestAllowedVolume { //This is less than because low values are louder. If we are louder than allowed, grab the value for the final threshold and move to next tone.
                currentTest!.finalThreshold = currentTest!.tone.volume
                finalResults.append(currentTest!.tone.volume)
                PlayNextFrequency() //Sets up the next tone
                SendMessage(currentTest!.tone)  //We have to actively send this, the timers based on button presses won't be armed because this is a missed tone.
            } else {
                currentTest!.currentMode = .ascending
                currentTest!.tone.volume = currentTest!.tone.volume - TestConstants.VolumeIncrease  //This needs to be subtracted because a lower value here is louder
                SendMessage(currentTest!.tone)
            }
        }
    }
    
    func CaughtATone() {
        //If descending, just go down more volume. If ascending, grab the tone for the thresholds array, check to see if there's a real threshold value and then descend if not at threshold
        if currentTest != nil {
            switch currentTest!.currentMode {
            case .ascending:
                currentTest!.thresholds.append(currentTest!.tone.volume)  //Add the current volume to the thresholds
                if let threshold = FindFinalThresholdValue(arrayToParse: currentTest!.thresholds) {     //If there's a real final threshold, capture it, add it to the final results, move to the next frequency
                    currentTest!.finalThreshold = threshold
                    finalResults.append(threshold)
                    PlayNextFrequency()
                } else {
                    currentTest!.currentMode = .descending
                    PlayLowerVolume()
                }
            case .descending:       //Need to keep the volume from going out of bounds for UInt here, so it can't be greater than 255. If it gets close, hearing is good at that frequency, so grab it as a final threshold and move on
                if currentTest!.tone.volume >= TestConstants.LowestAllowedVolume {  //This is greater than because higher numbers are lower volumes
                    currentTest!.finalThreshold = currentTest!.tone.volume
                    finalResults.append(currentTest!.tone.volume)
                    PlayNextFrequency()
                } else {
                    PlayLowerVolume()
                }
            }
        }
    }
    
    func PlayNextFrequency() {
        //Grab the frequency and ear we are now done playing, increment frequencies by one, go back to the starting volume, and deal with rectangles
        //If we're at the last frequency, go to the next ear, erase the rectangles then draw the first column
        //If we're at the last frequency and last ear, go to results
        if currentTest != nil {
            let oldFrequency = currentTest!.tone.frequency
            let oldEar = currentTest!.tone.ear
            
            //Destroy and then recreate currentTest
            currentTest = nil
            let tone = Tone(frequency: TestConstants.StartingFrequency, ear: TestConstants.StartingEar, volume: TestConstants.StartingVolume[0])
            currentTest = FrequencyTest(tone: tone, currentMode: .descending, thresholds: [], finalThreshold: nil)

            switch oldFrequency {
            case .Hz8000:
                if oldEar == .leftEar {     //This is the final ear, we're done.
                    ShowResults()
                    return              //This kicks us out so we don't flag message prepped and keep running the test in the background while results are shown
                } else if oldEar == .rightEar { //Go to the next ear, start over the frequencies, remove the rects, update the ear
                    currentTest!.tone.ear = .leftEar
                    currentTest!.tone.frequency = TestConstants.StartingFrequency
                    currentTest!.tone.volume = TestConstants.StartingVolume[0]
                    RemoveSmallRects()
                    updateEarLabel()
                }
            default:
                //Keep the ear the same, increment the frequency, darken the current column, draw the next column of rects
                currentTest!.tone.ear = oldEar
                if let nextFreq = Freqs(rawValue: oldFrequency.hashValue + 1) {
                    currentTest!.tone.frequency = nextFreq
                    currentTest!.tone.volume = TestConstants.StartingVolume[nextFreq.hashValue - 1] //Have to subtract one because of the dummy value
                    DarkenSmallRects(column: oldFrequency.hashValue - 1)    //Have to subtract one because of the dummy value
                    DrawSmallRects(column: nextFreq.hashValue - 1)          //Have to subtract one because of the dummy value
                }
            }

            messagePrepped = true
        }
    }
    
    func PlayLowerVolume() {
        //Keep the current test around, just turn down the volume
        if currentTest != nil {
            currentTest!.tone.volume = currentTest!.tone.volume + TestConstants.VolumeDecrement //Needs to be added, because higher numbers represent lower volumes
            messagePrepped = true
        }
    }

    func FindFinalThresholdValue(arrayToParse arrayToParse: [Int]) -> (Int?) {
        let numberOfThresholdElements: Double = Double(arrayToParse.count)
        var potentialThresholdValue: Int?
        switch numberOfThresholdElements {
        case 0: potentialThresholdValue = nil
        case 1: potentialThresholdValue = nil       //Nothing to compare to
        case 2:
            if arrayToParse[0] == arrayToParse[1] { //If there are two values and they're the same, return them
                potentialThresholdValue = arrayToParse[0]
            }
        default:
            //create a dictionary of thresholds and number of appearances
            var frequencyDictionary: [Int: Double] = [:]   //Start with an empty dictionary
            
            for value in arrayToParse {
                frequencyDictionary[value] = (frequencyDictionary[value] ?? 0) + 1  //If the dictionary already has a value, grab it then add one, if not, start at 0 then add 1
            }
            for (threshold, appearances) in frequencyDictionary {
                if (appearances / numberOfThresholdElements) >= 0.5 {                   //If it's appeared at least half the times we grabbed a value
                    if threshold > potentialThresholdValue || potentialThresholdValue == nil {      //If this threshold value is quieter than any previous one we grabbed or if the value has never been set
                        potentialThresholdValue = threshold
                    }
                }
            }
        }
        return potentialThresholdValue
    }
    
    func ShowResults() {
        performSegueWithIdentifier("Show Results", sender: nil)
    }
    
    func ToneWasPlayed() {
        isBeeping = true    //Beep is happening
        //Start a timer. If this timer elapses, it means the user missed the tone. If they tap before this timer elapses, the tap handler will kill this timer.
        dispatch_async(dispatch_get_main_queue(), { [unowned self] in
            if self.beepReactionTimer == nil {
                self.beepReactionTimer = NSTimer.scheduledTimerWithTimeInterval(timeConstants.reactionTimeAllowed, target: self, selector: Selector("BeepReactionTimerElapsed"), userInfo: nil, repeats: false)
            }
        })
    }
    
    func BeepReactionTimerElapsed() {
        StopBeepReactionTimer()
        MissedATone()
    }
    
    func StopBeepReactionTimer() {
        if beepReactionTimer == nil {
            return
        }
        isBeeping = false
        beepReactionTimer?.invalidate()
        beepReactionTimer = nil
    }
    
    func DelayAfterTapTimerElapsed() {
        StopBeepDelayTimer()
        if messagePrepped {
            if currentTest != nil {
                SendMessage(currentTest!.tone)   //This tells the peripheral to play the tone
                messagePrepped = false
            }
        }
    }
    
    func StopBeepDelayTimer() {
        if beepDelayTimer == nil {
            return
        }
        beepDelayTimer?.invalidate()
        beepDelayTimer = nil
    }
    
    //MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let resultsViewController = segue.destinationViewController as? HTResultsViewController {
            resultsViewController.results = self.finalResults
        }
    }

}
