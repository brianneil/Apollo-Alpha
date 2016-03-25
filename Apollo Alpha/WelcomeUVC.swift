//
//  WelcomeUVC.swift
//  Apollo Alpha
//
//  Created by Brian Neil on 3/24/16.
//  Copyright © 2016 Apollo Hearing. All rights reserved.
//

import Foundation
import UIKit

class WelcomeUVC: UIViewController, UITextFieldDelegate {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NameField.delegate = self       //set us as the delgate
        
        
    }
    
    @IBOutlet weak var NameField: UITextField!
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        NameField.resignFirstResponder()
        //Save the name somwehere and fire up the data holding
        performSegueWithIdentifier("ToPairing", sender: nil)
        return true
    }
    
    
    // MARK: - Navigation
    
    //    // In a storyboard-based application, you will often want to do a little preparation before navigation
    //    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    //
    //
    //
    //
    //
    //
    //
    //        // Get the new view controller using segue.destinationViewController.
    //        // Pass the selected object to the new view controller.
    //    }


}
