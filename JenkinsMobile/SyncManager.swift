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
    /*
    var masterMOC: NSManagedObjectContext
    var mainMOC: NSManagedObjectContext
    var currentJenkinsInstance: JenkinsInstance
    var currentBuilds: NSMutableArray
    var currentBuildsTimer: NSTimer
    var requestHandler: KDBJenkinsRequestHandler
    */
    
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
        println("job detail response notification received")
    }
}