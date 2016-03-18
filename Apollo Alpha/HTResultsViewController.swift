//
//  HTResultsViewController.swift
//  Apollo Alpha
//
//  Created by Brian Neil on 2/24/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//

import Foundation
import UIKit

class HTResultsViewController: UIViewController {
    
    var results: [Int] = []
    
    @IBOutlet weak var RightEarResults: UIImageView!
    
    @IBOutlet weak var LeftEarResults: UIImageView!
    
    var columnViews: [UIView] = []  //A place to store columns
    
    let baselineVolume: [Double] = [85, 95, 120, 135, 140, 110, 85, 95, 120, 135, 140, 110]     //This is hacky, run it twice here to
    
    //MARK: Drawing
    func DrawColumns(viewToDrawIn: UIView, constants: HTBarsViewController.DrawingConstantStruct) {
        for xIndex in 0..<Int(constants.numberOfColumns) {
            let xPos = constants.columnGap/2 + (constants.columnGap + constants.columnSize.width) * CGFloat(xIndex)   //Creates a columngap/2 space at each end
            
            let columnOrigin = CGPoint(x: xPos, y: constants.yOffset)
            //let columnOrigin = CGPoint(x: xPos, y: 0)
            let frame = CGRect(origin: columnOrigin, size: constants.columnSize)
            
            let columnView = UIView(frame: frame)
            columnView.layer.borderColor = constants.apolloBlue.CGColor
            columnView.layer.borderWidth = constants.columnBorderWidth
            
            columnViews.append(columnView)
            
            viewToDrawIn.addSubview(columnView)
        }

    }
    
    func DrawSmallRects(columnView: UIView, result: Int, baseline: Double, constants: HTBarsViewController.DrawingConstantStruct) {
        let percentOfTotal: Double = (baseline - Double(result)) / baseline
        let rectsToShade: Int = Int(round(percentOfTotal * Double(constants.numberOfSmallRects)))
        
        let frame = columnView.bounds
        let xPos = frame.origin.x
        let yOffset = frame.origin.y
        for yIndex in 0..<Int(constants.numberOfSmallRects) {
            let yPos = constants.smallRectGap/2 + (constants.smallRectGap + constants.smallRectSize.height) * CGFloat(yIndex) + yOffset
            
            let smallRectOrigin = CGPoint(x: xPos, y: yPos)
            let frame = CGRect(origin: smallRectOrigin, size: constants.smallRectSize)
            
            let smallRectView = UIView(frame: frame)
            if yIndex < rectsToShade {
                smallRectView.backgroundColor = constants.apolloLightBlue
            } else {
                smallRectView.backgroundColor = constants.apolloBlue
            }
            
            
            columnView.addSubview(smallRectView)
        }

    }
    
    //MARK: Lifecycle
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let drawingConstants = HTBarsViewController.DrawingConstantStruct(barView: RightEarResults)
        DrawColumns(RightEarResults, constants: drawingConstants)
        DrawColumns(LeftEarResults, constants: drawingConstants)
        
        if results.count == columnViews.count { //Confirm that we have all the results
            for Index in 0..<columnViews.count {
                let result = results[Index]
                let baseline = baselineVolume[Index]
                DrawSmallRects(columnViews[Index], result: result, baseline: baseline, constants: drawingConstants)
            }
        }
        
    }
}
