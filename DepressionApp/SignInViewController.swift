//
//  signInViewController.swift
//  DepressionApp
//
//  Created by Tim Delisle on 10/27/15.
//  Copyright © 2015 Cornell Tech. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController {
    @IBOutlet weak var userNameField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        

        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goPressed(sender: AnyObject) {
        if userNameField.text != "" {
            let name = userNameField.text!
            print("name submitted")
            
            NSUserDefaults.standardUserDefaults().setValue(name, forKey: "UserName")
            
            print(NSUserDefaults.standardUserDefaults().objectForKey("UserName"))
            
        } else  {
            let alert = UIAlertController(title: "Username required", message: "You must submit a user name", preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
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
