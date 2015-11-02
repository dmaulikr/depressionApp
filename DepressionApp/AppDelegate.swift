//
//  AppDelegate.swift
//  DepressionApp
//
//  Created by Tim Delisle on 10/27/15.
//  Copyright © 2015 Cornell Tech. All rights reserved.
//

import UIKit
import HealthKit
import Parse
import Bolts
import Foundation
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    
    var window: UIWindow?

    let healthManager:HealthManager = HealthManager()
    let locationManager = CLLocationManager()
    
    let defaults = NSUserDefaults.standardUserDefaults()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        if NSUserDefaults.standardUserDefaults().objectForKey("UserName") == nil {
            print("User not signed in")
            
            //Authorize Health Kit
            authorizeHealthKit()
            
            //Location Manager
            locationManager.requestAlwaysAuthorization()
            locationManager.delegate = self
            locationManager.distanceFilter = 5
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let signInVC = storyboard.instantiateViewControllerWithIdentifier("SignIn")
            
            window?.rootViewController = signInVC

        } else {
            print("User exists")
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let questionVC = storyboard.instantiateViewControllerWithIdentifier("Questions")
            
            //Location manager
            locationManager.delegate = self
            locationManager.distanceFilter = 5
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
            
            window?.rootViewController = questionVC
         
        }
        
        locationManager.allowsBackgroundLocationUpdates = true
        
        Parse.enableLocalDatastore()
        
        // Initialize Parse.
        Parse.setApplicationId("fo5YzeQkIART63UkUCSmVTgcF2s1CIfv7uT7kdOz",
            clientKey: "P4T7jPg8Je3X6SrF72dhW4eAlkzUubZSTHfxJR8E")
        
       // [Optional] Track statistics around application opens.
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        //Defaults setting
        if !defaults.boolForKey("GotLast2Weeks") {
            defaults.setBool(false, forKey: "GotLast2Weeks")
        }
        if (defaults.valueForKey("LastUpdatedHealthDay") == nil) {
            defaults.setObject(NSDate(), forKey: "LastUpdatedHealthDay")
        }
        if (defaults.valueForKey("LastUpdatedLocationHour") == nil){
            defaults.setObject(NSDate(), forKey: "LastUpdatedLocationHour")
        }
        
        return true
    }
    
    func authorizeHealthKit()
    {
        //First Authorize Health Kit
        healthManager.authorizeHealthKit { (authorized,  error) -> Void in
            if authorized {
                print("HealthKit authorization received.")
            }
            else
            {
                print("HealthKit authorization denied!")
                if error != nil {
                    print("\(error)")
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("location manager has updated locations!")
        
//        let test = PFObject(className: "TestObject")
//        test["foo"] = String(Double((locationManager.location?.coordinate.latitude)!))
//        
//        test.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
//            print("Saved test object.")
//        }
        //test.saveEventually()
            
        let lastLocation = locations.last!
        
        //Submit Last 2 Weeks of Health Update if first time opening app
        if (!defaults.boolForKey("GotLast2Weeks") && defaults.objectForKey("UserName") != nil){
            //Submit First Location Update
            print("submit the location for the first time")
            let location = PFObject(className: "Location")
            location["User"] = String(defaults.objectForKey("UserName")!)
            location["Latitude"] = Double(lastLocation.coordinate.latitude)
            location["Longitude"] = Double(lastLocation.coordinate.longitude)
            location.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
                print ("Saved updated hourly location")
            }
            
            //Go through loop of last 2 weeks for health update, stopping at yesterday
            let dayComponent = NSDateComponents()
            dayComponent.day = -14;
            let  calendar = NSCalendar.currentCalendar()
            var currDate = calendar.dateByAddingComponents(dayComponent, toDate: NSDate(), options: NSCalendarOptions())
            
            var i = 1
            while (i <= 13) {
                self.healthManager.updateSteps(currDate!)
                self.healthManager.updateStandingHours(currDate!)
                dayComponent.day = dayComponent.day + 1
                currDate = calendar.dateByAddingComponents(dayComponent, toDate: NSDate(), options: NSCalendarOptions())
                sleep(2)
                print("in while loop: ", healthManager.returnArray)
                
                let healthInfo = PFObject(className: "HealthInfo")
                healthInfo["User"] = String(defaults.objectForKey("UserName")!)
                healthInfo["TotalSteps"] = healthManager.returnArray[0]
                healthInfo["WatchSteps"] = healthManager.returnArray[1]
                healthInfo["PhoneSteps"] = healthManager.returnArray[2]
                healthInfo["StandingHours"] = healthManager.returnArray[3]
                healthInfo.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
                    print ("Saved updated daily health info")
                }
                i = i + 1
            }
            defaults.setBool(true, forKey: "GotLast2Weeks")
        }
        //Not first time opening app, just regular updates
        else{
            //Submit Hourly Location Update
            let lastLocationHour = defaults.objectForKey("LastUpdatedLocationHour") as! NSDate
            let locationInterval = Double((locations.last?.timestamp.timeIntervalSinceDate(lastLocationHour))!) / 3600
            
            if (locationInterval >= 1){
                print("it has been an hour, so we are updating the location")
                
                let location = PFObject(className: "Location")
                location["User"] = String(defaults.objectForKey("UserName")!)
                location["Latitude"] = Double(lastLocation.coordinate.latitude)
                location["Longitude"] = Double(lastLocation.coordinate.longitude)
                location.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
                    print ("Saved updated hourly location")
                }
                
                defaults.setObject(NSDate(), forKey: "LastUpdatedLocationHour")
            }
            
            //Submit Daily Health Update
            let lastHealthDay = defaults.objectForKey("LastUpdatedHealthDay") as! NSDate
            let healthInterval = Double((locations.last?.timestamp.timeIntervalSinceDate(lastHealthDay))!)/86400
                
            if (healthInterval >= 1){
                print("it has been a day, so we are updating the health steps & standing hours data")
                
                let dayComponent = NSDateComponents()
                dayComponent.day = -1;
                let  calendar = NSCalendar.currentCalendar()
                let currDate = calendar.dateByAddingComponents(dayComponent, toDate: NSDate(), options: NSCalendarOptions())
                
                self.healthManager.updateSteps(currDate!)
                self.healthManager.updateStandingHours(currDate!)
                sleep(2)
                print("in while loop: ", healthManager.returnArray)
                
                let healthInfo = PFObject(className: "HealthInfo")
                healthInfo["User"] = String(defaults.objectForKey("UserName")!)
                healthInfo["TotalSteps"] = healthManager.returnArray[0]
                healthInfo["WatchSteps"] = healthManager.returnArray[1]
                healthInfo["PhoneSteps"] = healthManager.returnArray[2]
                healthInfo["StandingHours"] = healthManager.returnArray[3]
                healthInfo.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
                    print ("Saved updated daily health info")
                }
                
                defaults.setObject(NSDate(), forKey: "LastUpdatedHealthDay")
            }

        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error)
    }

    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("entering background")
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("terminating")
    }


}

