//
//  HealthManager.swift
//  DepressionApp
//
//  Created by Sonia Sen on 10/31/15.
//  Copyright © 2015 Cornell Tech. All rights reserved.
//

import UIKit
import Foundation
import HealthKit
import Parse

class HealthManager: NSObject {
    
    let healthKitStore:HKHealthStore = HKHealthStore()
    //  returnArray for steps  [totalSteps, watchSteps, phoneSteps, standingHours]
    var returnArray = [0.0, 0.0, 0.0, 0.0]
    
    func authorizeHealthKit(completion: ((success:Bool, error:NSError!) -> Void)!)
    {
        if !HKHealthStore.isHealthDataAvailable(){
            print("health kit not available on this device")
            return
        }
        
        let healthKitTypesToRead = Set( arrayLiteral:
            HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!,
            HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!,
            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!,
            HKObjectType.categoryTypeForIdentifier(HKCategoryTypeIdentifierAppleStandHour)!
        )
        
        let newCompletion: ((Bool, NSError?) -> Void) = {
            (success, error) -> Void in
            
            if !success {
                print("You didn't allow HealthKit to access these read data types.\nThe error was:\n \(error!.description).")
                
                return
            }
        }
        
        healthKitStore.requestAuthorizationToShareTypes(nil, readTypes: healthKitTypesToRead, completion: newCompletion)
        
    }
    
    func readBirthDate () ->NSDate{
        var dob = NSDate()
        do{
            dob = try healthKitStore.dateOfBirth()
            
        }
        catch{
            print("error regarding dob")
        }
        
        
        return dob
    }
    
    func readSex() -> HKBiologicalSexObject {
        var sex = HKBiologicalSexObject()
        do{
            sex = try healthKitStore.biologicalSex()
        } catch {
            print("error regarding sex")
        }
        return sex
    }
    
    func updateSteps(date: NSDate){
        print("gettings steps for ", date)
        
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Year, .Month, .Day], fromDate: date)
        let startDate = calendar.dateFromComponents(components)
        let endDate = calendar.dateByAddingUnit(.Day, value: 1, toDate: startDate!, options: NSCalendarOptions(rawValue: 0))
        
        let hkSampleType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)
        let hkPredicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .None)

        let query = HKSampleQuery(sampleType: hkSampleType!, predicate: hkPredicate, limit: 0, sortDescriptors: nil, resultsHandler:
            { (query:HKSampleQuery, results:[HKSample]?, error:NSError?) -> Void in
            
                if (error != nil){
                    print(error)
                }
                else{
                    var total = 0.0
                    var watch = 0.0
                    var phone = 0.0
                    
                    for r in results!{
                        let curr = r as! HKQuantitySample
                        let currVal = curr.quantity.doubleValueForUnit(HKUnit.countUnit())
                        if "iPhone" == curr.device?.name {
                            phone += currVal
                        } else{
                            watch += currVal
                        }
                        total += currVal
                    }
                    self.returnArray[0] = total
                    self.returnArray[1] = watch
                    self.returnArray[2] = phone
                }
        })
        
            self.healthKitStore.executeQuery(query)
            //print("return array from update steps: ", self.returnArray)
        
    }
    
    
    func updateStandingHours(date: NSDate){
        print("getting standing hours for, ", date)
        
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Year, .Month, .Day], fromDate: date)
        
        let startDate = calendar.dateFromComponents(components)
        let endDate = calendar.dateByAddingUnit(.Day, value: 1, toDate: startDate!, options: NSCalendarOptions(rawValue: 0))
        
        let hkSampleType = HKSampleType.categoryTypeForIdentifier(HKCategoryTypeIdentifierAppleStandHour)
        let hkPredicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: endDate, options: .None)
        let query = HKSampleQuery(sampleType: hkSampleType!, predicate: hkPredicate, limit: 25, sortDescriptors: nil, resultsHandler:
            {(query:HKSampleQuery, results:[HKSample]?, error:NSError?) -> Void in
                //print("executing standing hours query")
                if (error != nil){
                    print(error)
                }
                else{
                    print("results from standing hours: ", results?.count)
                    self.returnArray[3] = Double((results?.count)!)
                }
                
        })
        healthKitStore.executeQuery(query)
    }
    
}

