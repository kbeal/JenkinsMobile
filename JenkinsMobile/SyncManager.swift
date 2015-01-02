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
    private var currentJenkinsInstance: JenkinsInstance?
    var currentJenkinsInstanceURL: NSURL? {
        didSet {
            switchJenkinsInstance()
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
        initTimer()
        initObservers()
    }
    
    func initTimer() {
        let runningTests = NSClassFromString("XCTestCase") != nil
        if !runningTests {
            // only start the timer if we aren't running unit tests
            jobSyncTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("jobSyncTimerTick"), userInfo: nil, repeats: true)
        }
    }
    
    // set up any NSNotificationCenter observers
    func initObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jobDetailResponseReceived:"), name: JobDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jobDetailRequestFailed:"), name: JobDetailRequestFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jenkinsInstanceDetailResponseReceived:"), name: JenkinsInstanceDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jenkinsInstanceDetailRequestFailed:"), name: JenkinsInstanceDetailRequestFailedNotification, object: nil)
    }
    
    // called after setting a new currentJenkinsInstanceURL
    // fetches the JenkinsInstance with this URL into the masterMOC
    func switchJenkinsInstance() {
        assert(self.masterMOC != nil, "master MOC is nil!!")
        if currentJenkinsInstanceURL != nil {
            self.masterMOC?.performBlockAndWait({
                self.currentJenkinsInstance = JenkinsInstance.fetchJenkinsInstanceWithURL(self.currentJenkinsInstanceURL!.absoluteString, fromManagedObjectContext: self.masterMOC)
                self.jobSyncQueue.removeAll()
                self.syncCurrentJenkinsInstance()
            })
        }
    }
    
    func jobSyncTimerTick() {
        if (jobSyncQueue.count() > 0) {
            // Build the job's URL from the currentJenkinsInstance and jobName
            // Kick off a sync for that job
            self.masterMOC?.performBlock({
                let jobname = self.jobSyncQueue.pop()!.stringByAddingPercentEncodingWithAllowedCharacters(.URLPathAllowedCharacterSet())
                let fullurl = self.currentJenkinsInstance!.url + "/job/" + jobname!
                self.syncJob(NSURL(string: fullurl)!)
            })
        } else {
            println("No more jobs to sync!!")
        }
    }
    
    public func jobSyncQueueSize() -> Int { return jobSyncQueue.count() }
    
    func syncAllJobs() {
        // queue all jobs for current Jenkins Instance to sync
        assert(self.currentJenkinsInstance != nil, "sync managers currentJenkinsInstance is nil!!")

        masterMOC?.performBlock({
            let allJobs = self.currentJenkinsInstance!.rel_Jobs
            for job in allJobs {
                self.jobSyncQueue.push(job.name)
            }
        })
    }
    
    func syncCurrentJenkinsInstance() {
        assert(self.requestHandler != nil, "sync manager's requestHandler is nil!!")
        if (currentJenkinsInstance != nil) {
            requestHandler!.importDetailsForJenkinsAtURL(currentJenkinsInstance!.url, withName: currentJenkinsInstance!.name)
        }
    }
    
    func syncView(url: NSURL) {
        // sync view details and queue all jobs in view for sync
        assert(self.requestHandler != nil, "sync manager's requestHandler is nil!!!")
        NSLog("%@%@", "Sending request for details for View at URL: ",url.absoluteString!)
        self.requestHandler!.importDetailsForViewWithURL(url)
    }
    
    func syncJob(url: NSURL) {
        assert(self.requestHandler != nil, "sync manager's requestHandler is nil!!")
        NSLog("%@%@", "Sending request for details for Job at URL: ",url.absoluteString!)
        self.requestHandler!.importDetailsForJobWithURL(url)
    }
    
    func viewDetailResponseReceived(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
        var values: Dictionary = notification.userInfo!
        let url = values[ViewURLKey] as String
        
        //TODO: re-think this. What if notification comes in after
        // current instance is swapped?
        values[ViewJenkinsInstanceKey] = currentJenkinsInstance
        
        self.masterMOC?.performBlockAndWait({
            // Fetch view based on url
            let view: View? = View.fetchViewWithURL(url, inContext: self.masterMOC)
            // create if it doesn't exist
            if (view==nil) {
                View.createViewWithValues(values, inManagedObjectContext: self.masterMOC)
            } else {
                // update it\s values
                view!.setValues(values)
            }
            self.saveMasterContext()
        })
    }
    
    func viewDetailRequestFailed(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
        // parse the error for the view url and status code
        let userInfo: Dictionary = notification.userInfo!
        let status: Int = userInfo[StatusCodeKey] as Int
        let url: NSURL = userInfo[NSErrorFailingURLKey] as NSURL
        
        // if the error is 404
        if (status==404) {
            // find the view
            var view: View?
            self.masterMOC?.performBlockAndWait({
                view = View.fetchViewWithURL(url.absoluteString, inContext: self.masterMOC)
            })
            // if it exists delete it
            if view != nil {
                self.masterMOC?.performBlockAndWait({
                    self.masterMOC!.deleteObject(view!)
                    self.saveMasterContext()
                })
            }
        }
    }
    
    func jobDetailResponseReceived(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
        var values: Dictionary = notification.userInfo!
        let name = values[JobNameKey] as String
//        let url = values[JobURLKey] as String
        
        //NSLog("%@%@", "Response received for Job at URL: ",url)
        
        //TODO: re-think this. What if notification comes in after
        // current instance is swapped?
        values[JobJenkinsInstanceKey] = currentJenkinsInstance
        
        self.masterMOC?.performBlockAndWait({
            // Fetch job based on name
            let job: Job? = Job.fetchJobWithName(name, inManagedObjectContext: self.masterMOC)
            // create if it doesn't exist
            if (job==nil) {
                Job.createJobWithValues(values, inManagedObjectContext: self.masterMOC)
            } else {
                // update it\s values
                job!.setValues(values)
            }
            self.saveMasterContext()
        })        
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
        assert(self.masterMOC != nil, "main managed object context not set")
        var values: Dictionary = notification.userInfo!
        let url = values[JenkinsInstanceURLKey] as String
        
        NSLog("%@%@","Response received for Jenkins at URL: ",url)

        values[JenkinsInstanceCurrentKey] = false
        
        self.masterMOC?.performBlock({
            JenkinsInstance.findOrCreateJenkinsInstanceWithValues(values, inManagedObjectContext: self.masterMOC)
            self.saveMasterContext()
            NSLog("%@%@","Saved details for Jenkins at URL: ",url)
        })
        
        syncAllJobs()
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
                jenkins = JenkinsInstance.fetchJenkinsInstanceWithURL(JenkinsInstance.removeApiFromURL(url), fromManagedObjectContext: self.masterMOC)
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
        let saveResult: Bool = moc!.save(&error)
        
        if (!saveResult) {
            println("Error saving context: \(error?.localizedDescription)\n\(error?.userInfo)")
            abort()
        } else {
            println("Successfully saved master managed object context")
        }
    }
}