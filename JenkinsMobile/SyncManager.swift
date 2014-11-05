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
    private var jobSyncTimer: NSTimer?
    var currentJenkinsInstance: JenkinsInstance? {
        willSet {
            jobSyncQueue.removeAll()
            self.syncCurrentJenkinsInstance()
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
        jobSyncTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("jobSyncTimerTick"), userInfo: nil, repeats: true)
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
    
    func jobSyncTimerTick() {
        if (jobSyncQueue.count() > 0) {
            syncJob(NSURL(string: jobSyncQueue.pop()!)!)
        }
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
    
    func syncCurrentJenkinsInstance() {
        assert(self.requestHandler != nil, "sync manager's requestHandler is nil!!")
        requestHandler!.importDetailsForJenkinsAtURL(currentJenkinsInstance?.url)
    }
    
    func syncView(viewName: String) {
        // sync view details and queue all jobs in view for sync
    }
    
    func syncJob(url: NSURL) {
        assert(self.requestHandler != nil, "sync manager's requestHandler is nil!!")
        self.requestHandler!.importDetailsForJobWithURL(url)
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
        assert(self.masterMOC != nil, "master managed object context not set!!")
        // parse the error for the jenkins url and status code
        let userInfo: Dictionary = notification.userInfo!
        let status: Int = userInfo[StatusCodeKey] as Int
        let url: NSURL = userInfo[NSErrorFailingURLKey] as NSURL
        let jobName = Job.jobNameFromURL(url)
        
        // if the error is 404
        if (status==404) {
            // find the job instance
            var job: Job?
            self.masterMOC?.performBlockAndWait({
                job = Job.fetchJobWithName(jobName, inManagedObjectContext: self.masterMOC!)
            })
            // if it exists delete it
            if job != nil {
                self.masterMOC?.performBlockAndWait({
                    self.masterMOC!.deleteObject(job!)
                    self.saveMasterContext()
                })
            }
        }
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
        assert(self.masterMOC != nil, "master managed object context not set")
        // parse the error for the jenkins url and status code
        let userInfo: Dictionary = notification.userInfo!
        let status: Int = userInfo[StatusCodeKey] as Int
        let url: NSURL = userInfo[NSErrorFailingURLKey] as NSURL
        
        // if the error is 404
        if (status==404) {
            // find the jenkins instance
            var jenkins: JenkinsInstance?
            self.masterMOC?.performBlockAndWait({
                jenkins = JenkinsInstance.fetchJenkinsInstanceWithURL(url.absoluteString, fromManagedObjectContext: self.masterMOC)
            })
            // if it exists delete it
            if jenkins != nil {
                self.masterMOC?.performBlockAndWait({
                    self.masterMOC!.deleteObject(jenkins!)
                    self.saveMasterContext()
                })
            } 
        }
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