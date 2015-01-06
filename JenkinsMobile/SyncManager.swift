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
                self.syncJob(NSURL(string: fullurl)!, jenkinsInstance: self.currentJenkinsInstance!)
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
    
    func syncAllViews() {
        // sync all the views for current Jenkins Instance
        assert(self.currentJenkinsInstance != nil, "sync managers currentJenkinsInstance is nil!!")
        masterMOC?.performBlock({
            let allViews = self.currentJenkinsInstance!.rel_Views
            for view in allViews {
                self.syncView(NSURL(string: view.url)!)
            }
        })
    }
    
    func syncAllJobsForView(view: View) {
        masterMOC?.performBlock({
            let viewjobs = view.rel_View_Jobs
            for job in viewjobs {
                self.jobSyncQueue.push(job.name)
            }
        })
    }
    
    func syncSubViewsForView(view: View) {
        masterMOC?.performBlock({
            let subviews = view.rel_View_Views.allObjects
            for subview in subviews {
                self.syncView(NSURL(string: subview.url)!)
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
    
    func syncJob(url: NSURL, jenkinsInstance: JenkinsInstance) {
        assert(self.requestHandler != nil, "sync manager's requestHandler is nil!!")
        NSLog("%@%@", "Sending request for details for Job at URL: ",url.absoluteString!)
        self.requestHandler!.importDetailsForJobWithURL(url, andJenkinsInstance: jenkinsInstance)
    }
    
    func viewDetailResponseReceived(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
        var values: Dictionary = notification.userInfo!
        let url = values[ViewURLKey] as String
        var view: View?
        
        //TODO: re-think this. What if notification comes in after
        // current instance is swapped?
        values[ViewJenkinsInstanceKey] = currentJenkinsInstance
        
        self.masterMOC?.performBlockAndWait({
            // Fetch view based on url
            view = View.fetchViewWithURL(url, inContext: self.masterMOC)
            // create if it doesn't exist
            if (view==nil) {
                View.createViewWithValues(values, inManagedObjectContext: self.masterMOC)
            } else {
                // update it\s values
                view!.setValues(values)
            }
            self.saveMasterContext()
        })
        
        // TODO: fix so that this works
        //self.syncAllJobsForView(view!)
    }
    
    func jobDetailResponseReceived(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
        var values: Dictionary = notification.userInfo!
        let name = values[JobNameKey] as String
        let jenkinsInstance: JenkinsInstance = values[JobJenkinsInstanceKey] as JenkinsInstance
        
        self.masterMOC?.performBlockAndWait({
            // Fetch job based on name
            let job: Job? = Job.fetchJobWithName(name, inManagedObjectContext: self.masterMOC, andJenkinsInstance: jenkinsInstance)
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
        let userInfo: Dictionary = notification.userInfo!
        let jenkinsInstance: JenkinsInstance = userInfo[JobJenkinsInstanceKey] as JenkinsInstance
        let requestError: NSError = userInfo[RequestErrorKey] as NSError
        let errorUserInfo: Dictionary = requestError.userInfo!
        let url: NSURL = errorUserInfo[NSErrorFailingURLKey] as NSURL
        let jobName = Job.jobNameFromURL(url)
        
        if requestError.code == NSURLErrorCannotFindHost {
            masterMOC!.performBlockAndWait({
                Job.fetchAndDeleteJobWithName(jobName, inManagedObjectContext: self.masterMOC, andJenkinsInstance: jenkinsInstance)
            })
        } else {
            let status: Int = userInfo[StatusCodeKey] as Int            
            // if the error is 404
            if (status==404) {
                self.masterMOC?.performBlockAndWait({
                    Job.fetchAndDeleteJobWithName(jobName, inManagedObjectContext: self.masterMOC, andJenkinsInstance: jenkinsInstance)
                })
            }
        }
        
        saveMasterContext()
    }
    
    func viewDetailRequestFailed(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
        // parse the error for the view url and status code
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as NSError
        let errorUserInfo: Dictionary = requestError.userInfo!
        let url: NSURL = errorUserInfo[NSErrorFailingURLKey] as NSURL
        
        if requestError.code == NSURLErrorCannotFindHost {
            masterMOC!.performBlockAndWait({
                View.fetchAndDeleteViewWithURL(url.absoluteString, inContext: self.masterMOC)
            })
        } else {
            let status: Int = userInfo[StatusCodeKey] as Int
            // if the error is 404
            if (status==404) {
                self.masterMOC?.performBlockAndWait({
                    View.fetchAndDeleteViewWithURL(url.absoluteString, inContext: self.masterMOC)
                })
            }
        }
        
        saveMasterContext()
    }
    
    func jenkinsInstanceDetailResponseReceived(notification: NSNotification) {
        assert(self.masterMOC != nil, "main managed object context not set")
        var values: Dictionary = notification.userInfo!
        let url = values[JenkinsInstanceURLKey] as String
        
        NSLog("%@%@","Response received for Jenkins at URL: ",url)

        values[JenkinsInstanceCurrentKey] = false
        values[JenkinsInstanceEnabledKey] = true
        
        self.masterMOC?.performBlock({
            JenkinsInstance.findOrCreateJenkinsInstanceWithValues(values, inManagedObjectContext: self.masterMOC)
            self.saveMasterContext()
            NSLog("%@%@","Saved details for Jenkins at URL: ",url)
        })
        
        syncAllJobs()
        syncAllViews()
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
                jenkins!.enabled = false
                self.masterMOC?.performBlockAndWait({
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