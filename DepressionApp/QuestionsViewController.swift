//
//  QuestionsViewController.swift
//  DepressionApp
//
//  Created by Tim Delisle on 10/27/15.
//  Copyright © 2015 Cornell Tech. All rights reserved.
//

import UIKit
import Parse
import Bolts
import Foundation
import CoreLocation

class QuestionsViewController: UIViewController{

    @IBOutlet weak var mentalHealthSlider: UISlider!
    @IBOutlet weak var mentalHealthResponse: UILabel!
    
    @IBOutlet weak var depressedSlider: UISlider!
    @IBOutlet weak var depressedResponse: UILabel!
    
    let healthManager:HealthManager = HealthManager()
    let locationManager = CLLocationManager()
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mentalHealthSlider.addTarget(self, action: "sliderValueDidChange:", forControlEvents: .ValueChanged)
        
        depressedSlider.addTarget(self, action: "sliderValueDidChange:", forControlEvents: .ValueChanged)

        // Do any additional setup after loading the view.
    }

    @IBAction func submit(sender: UIButton) {
        print("Items submited")
        print("User: " + String(NSUserDefaults.standardUserDefaults().objectForKey("UserName")!))
        print("Mental Health: " + String(Int(mentalHealthSlider.value)))
        print("Depressed: " + String(Int(depressedSlider.value)))
        
        let assessment = PFObject(className: "Assessment")
        assessment["User"] = String(NSUserDefaults.standardUserDefaults().objectForKey("UserName")!)
        assessment["Mental_Health"] = String(Int(mentalHealthSlider.value))
        assessment["Depressed"] = String(Int(depressedSlider.value))
        
        assessment.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            print("Saved assessment.")
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func sliderValueDidChange(sender:UISlider!)
    {
        
        print((round(sender.value)))
        sender.setValue((round(sender.value)), animated: false)

        if sender.accessibilityIdentifier != nil {
            if sender.accessibilityIdentifier == "mentalHealth" {
                mentalHealthResponse.text = "Answer: " + String(Int(round(sender.value)))
            } else {
                depressedResponse.text = "Answer: " + String(Int(round(sender.value)))
            }
            
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
