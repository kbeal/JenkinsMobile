//
//  SyncManager.swift
//  JenkinsMobile
//
//  Created by Kyle on 9/15/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

import Foundation
import CoreData

public class SyncManager {
    
    var masterMOC: NSManagedObjectContext?
    var mainMOC: NSManagedObjectContext?
    //var currentJenkinsInstance: JenkinsInstance
    //var currentBuilds: NSMutableArray
    //var currentBuildsTimer: NSTimer
    //var requestHandler: KDBJenkinsRequestHandler
    
    public class var sharedInstance : SyncManager {
        struct Static {
            static let instance : SyncManager = SyncManager()
        }
        return Static.instance
    }
    
    init() {
        /*
        self.masterMOC = masterManagedObjectContext
        self.currentJenkinsInstance = currentJenkinsInstance
        self.requestHandler = KDBJenkinsRequestHandler(jenkinsInstance: self.currentJenkinsInstance)
        */
    }
    
    // set up any NSNotificationCenter observers
    func initObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "jobDetailResponseReceived", name: JobDetailResponseReceivedNotification, object: nil)
    }
    
    /*
    func syncJob(name: NSString) {
        let url = self.currentJenkinsInstance.url + "/" + name
        self.requestHandler.importDetailsForJobAtURL(url)
    }*/
    
    func jobDetailResponseReceived(notification: NSNotification) {
        assert(self.mainMOC != nil, "main managed object context not set")
        let values: NSDictionary = notification.userInfo!
        let name = values[JobNameKey] as String
        
        // Fetch job based on name
        let job: Job? = Job.fetchJobWithName(name, inManagedObjectContext: self.mainMOC)
        // create if it doesn't exist
        if (job==nil) {
            assert(self.masterMOC != nil, "master managed object context not set");
            Job.createJobWithValues(values, inManagedObjectContext: self.masterMOC)
        } else {
            // update it's values
            job!.setValues(values)
        }
        
        self.saveMasterContext()
    }
    
    func saveMasterContext () {
        var error: NSError? = nil
        let moc = self.masterMOC
        if moc == nil {
            return
        }
        if !moc!.hasChanges {
            return
        }
        if (moc?.save(&error) != nil) {
            return
        }
        
        println("Error saving context: \(error?.localizedDescription)\n\(error?.userInfo)")
        abort()
    }
}