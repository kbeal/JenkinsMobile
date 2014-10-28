//
//  SyncManager.swift
//  JenkinsMobile
//
//  Created by Kyle on 9/15/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

import Foundation
import CoreData

@objc public class SyncManager {
    
    var masterMOC: NSManagedObjectContext?
    var mainMOC: NSManagedObjectContext?
    private var jobSyncQueue = UniqueQueue()
    var currentJenkinsInstance: JenkinsInstance? {
        willSet {
            jobSyncQueue.removeAll()
        }
    }
    //var currentBuilds: NSMutableArray
    //var currentBuildsTimer: NSTimer
    var requestHandler: KDBJenkinsRequestHandler?
    
    public class var sharedInstance : SyncManager {
        struct Static {
            static let instance : SyncManager = SyncManager()
        }
        return Static.instance
    }
    
    public init() {
        /*
        self.masterMOC = masterManagedObjectContext
        self.currentJenkinsInstance = currentJenkinsInstance
        self.requestHandler = KDBJenkinsRequestHandler(jenkinsInstance: self.currentJenkinsInstance)
        */
    }
    
    // set up any NSNotificationCenter observers
    func initObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "jobDetailResponseReceived", name: JobDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "jobDetailRequestFailed", name: JobDetailRequestFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "jenkinsInstanceDetailResponseReceived", name: JenkinsInstanceDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "jenkinsInstanceDetailRequestFailed", name: JenkinsInstanceDetailRequestFailedNotification, object: nil)
    }
    
    public func jobSyncQueueSize() -> Int { return jobSyncQueue.count() }
    
    func syncAllJobs() {
        // queue all jobs for current Jenkins Instance to sync
        assert(self.currentJenkinsInstance != nil, "sync managers currentJenkinsInstance is nil!!")

        let allJobs = currentJenkinsInstance!.rel_Jobs
        for job in allJobs {
            jobSyncQueue.push(job.name)
        }
    }
    
    func syncView(viewName: String) {
        // sync view details and queue all jobs in view for sync
    }
    
    func syncJob(name: String) {
        assert(self.requestHandler != nil, "sync manager's requestHandler is nil!!")
        self.requestHandler!.importDetailsForJobWithName(name)
    }
    
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
            // update it\s values
            job!.setValues(values)
        }
        
        self.saveMasterContext()
    }
    
    func jobDetailRequestFailed(notification: NSNotification) {
        // check the error
        println(notification)
        // get the jenkins instance and job name from the notification
        // fetch job via the jenkins instance
        // delete the job
    }
    
    func jenkinsInstanceDetailResponseReceived(notification: NSNotification) {
        assert(self.mainMOC != nil, "main managed object context not set")
        let values: NSDictionary = notification.userInfo!
        let url = values[JenkinsInstanceURLKey] as String
        
        // Fetch instance based on url
        let jenkinsInstance: JenkinsInstance? = JenkinsInstance.fetchJenkinsInstanceWithURL(url, fromManagedObjectContext: self.mainMOC)
        //create if it doesn't exist
        if (jenkinsInstance==nil) {
            assert(self.masterMOC != nil, "master managed object context not set")
            JenkinsInstance.createJenkinsInstanceWithValues(values, inManagedObjectContext: self.masterMOC)
        } else {
            // update its values
            jenkinsInstance!.setValues(values)
        }
        
        self.saveMasterContext()
    }
    
    func jenkinsInstanceDetailRequestFailed(notification: NSNotification) {
        
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