//
//  SyncManager.swift
//  JenkinsMobile
//
//  Created by Kyle on 9/15/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

import Foundation
import CoreData

public class SyncManager: NSObject {

    var dataMgr: DataManager = DataManager.sharedInstance
    var masterMOC: NSManagedObjectContext
    var mainMOC: NSManagedObjectContext
    
    var currentJenkinsInstance: JenkinsInstance? {
        didSet {
            if (currentJenkinsInstance != nil) {
                self.syncJenkinsInstance(currentJenkinsInstance!)
                self.updateCurrentURLPref(currentJenkinsInstance!.url!)
                let notification = NSNotification(name: SyncManagerCurrentJenkinsInstanceChangedNotification, object: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)
            }
        }
    }
    
    private var jobSyncQueue = UniqueQueue<Job>()
    private var viewSyncQueue = UniqueQueue<View>()
    private var buildSyncQueue = UniqueQueue<Build>()
    private var syncTimer: NSTimer?
    //var currentBuilds: NSMutableArray
    //var currentBuildsTimer: NSTimer
    var requestHandler: KDBJenkinsRequestHandler
    
    
    // MARK: - Init and Setup
    public class var sharedInstance : SyncManager {
        struct Static {
            static let instance : SyncManager = SyncManager()
        }
        return Static.instance
    }
    
    public override init() {
        self.masterMOC = dataMgr.masterMOC
        self.mainMOC = dataMgr.mainMOC
        self.requestHandler = KDBJenkinsRequestHandler()
        super.init()
        initTimer()
        initObservers()
        let defaults = NSUserDefaults.standardUserDefaults()
        if let url: String = defaults.stringForKey(SyncManagerCurrentJenkinsInstance) {
            self.currentJenkinsInstance = JenkinsInstance.fetchJenkinsInstanceWithURL(url, fromManagedObjectContext: self.mainMOC)
        }
    }
    
    func initTimer() {
        let runningTests = NSClassFromString("XCTestCase") != nil
        if !runningTests {
            // only start the timer if we aren't running unit tests
            syncTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("syncTimerTick"), userInfo: nil, repeats: true)
        }
    }
    
    // set up any NSNotificationCenter observers
    func initObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jobDetailResponseReceived:"), name: JobDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jobDetailRequestFailed:"), name: JobDetailRequestFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jenkinsInstanceDetailResponseReceived:"), name: JenkinsInstanceDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jenkinsInstanceDetailRequestFailed:"), name: JenkinsInstanceDetailRequestFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jenkinsInstanceViewsResponseReceived:"), name: JenkinsInstanceViewsResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jenkinsInstanceDetailRequestFailed:"), name: JenkinsInstanceViewsRequestFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("viewDetailResponseReceived:"), name: ViewDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("viewChildViewsResponseReceived:"), name: ViewChildViewsResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("viewDetailRequestFailed:"), name: ViewDetailRequestFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("viewDetailRequestFailed:"), name: ViewChildViewsRequestFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("buildDetailResponseReceived:"), name: BuildDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("buildDetailRequestFailed:"), name: BuildDetailRequestFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("activeConfigurationDetailResponseReceived:"), name: ActiveConfigurationDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("activeConfigurationDetailRequestFailed:"), name: ActiveConfigurationDetailRequestFailedNotification, object: nil)
    }
    
    func syncTimerTick() {
        if (jobSyncQueue.count() > 0) {
            // pop a job from the jobQueue and sync it
            self.masterMOC.performBlock({
                let job = self.jobSyncQueue.pop()!
                self.syncJob(job)
            })
        }
        
        if (viewSyncQueue.count() > 0) {
            // pop a view from the jobQueue and sync it
            self.masterMOC.performBlock({
                let view = self.viewSyncQueue.pop()!
                self.syncView(view)
            })
        }
        
        if (buildSyncQueue.count() > 0) {
            // pop a build from the jobQueue and sync it
            self.masterMOC.performBlock({
                let build = self.buildSyncQueue.pop()!
                self.syncBuild(build)
            })
        }
    }
    
    func updateCurrentURLPref(newURL: String) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(newURL, forKey: SyncManagerCurrentJenkinsInstance)
    }
    
    public func jobSyncQueueSize() -> Int { return jobSyncQueue.count() }
    
    // MARK: - Sync Objects
    public func syncAllJobs(jenkinsInstance: JenkinsInstance) {
        masterMOC.performBlock({
            if let bgji: JenkinsInstance = self.dataMgr.ensureObjectOnBackgroundThread(jenkinsInstance) as? JenkinsInstance {
                let allJobs = bgji.rel_Jobs
                for job in allJobs! {
                    self.jobSyncQueue.push(job)
                }
            } else {
                print("Error syncing all Jobs: Unable to retrieve JenkinsInstance from background context.")
            }
        })
    }
    
    public func syncAllViews(jenkinsInstance: JenkinsInstance) {
        masterMOC.performBlock({
            if let bgji: JenkinsInstance = self.dataMgr.ensureObjectOnBackgroundThread(jenkinsInstance) as? JenkinsInstance {
                let allViews = bgji.rel_Views
                for view in allViews! {
                    self.viewSyncQueue.push(view)
                }
            } else {
                print("Error syncing all Views: Unable to retrieve JenkinsInstance from background context.")
            }
        })
    }
    
    public func syncAllJobsForView(view: View) {
        if let bgview: View = self.dataMgr.ensureObjectOnBackgroundThread(view) as? View {
            masterMOC.performBlock({
                let viewjobs = bgview.rel_View_Jobs
                for job in viewjobs! {
                    self.jobSyncQueue.push(job)
                }
            })
        }
    }
    
    public func syncSubViewsForView(view: View) {
        if let bgview: View = self.dataMgr.ensureObjectOnBackgroundThread(view) as? View {
            masterMOC.performBlock({
                let subviews = bgview.rel_View_Views
                for subview in subviews! {
                    self.viewSyncQueue.push(subview)
                }
            })
        }
    }
    
    public func syncJenkinsInstance(instance: JenkinsInstance) {
        if let bgji: JenkinsInstance = self.dataMgr.ensureObjectOnBackgroundThread(instance) as? JenkinsInstance {
            self.masterMOC.performBlock({
                self.requestHandler.importDetailsForJenkinsInstance(bgji)                
            })
        }
    }
    
    public func syncViewsForJenkinsInstance(instance: JenkinsInstance) {
        if let bgji: JenkinsInstance = self.dataMgr.ensureObjectOnBackgroundThread(instance) as? JenkinsInstance {
            self.masterMOC.performBlock({
                self.requestHandler.importViewsForJenkinsInstance(bgji)
            })
        }
    }
    
    public func syncView(view: View) {
        if let bgview: View = self.dataMgr.ensureObjectOnBackgroundThread(view) as? View {
            self.masterMOC.performBlock({
                // sync view details and queue all jobs in view for sync
                self.requestHandler.importDetailsForView(bgview)
            })
        }
    }
    
    public func syncChildViewsForView(view: View) {
        if let bgview: View = self.dataMgr.ensureObjectOnBackgroundThread(view) as? View {
            self.masterMOC.performBlock({
                self.requestHandler.importChildViewsForView(bgview)
            })
        }
    }
    
    public func syncJob(job: Job) {
        if let bgjob: Job = self.dataMgr.ensureObjectOnBackgroundThread(job) as? Job {
            self.masterMOC.performBlock({
                self.requestHandler.importDetailsForJob(bgjob)
            })
        }
    }
    
    public func syncBuild(build: Build) {
        if let bgbuild: Build = self.dataMgr.ensureObjectOnBackgroundThread(build) as? Build {
            self.masterMOC.performBlock({
                self.requestHandler.importDetailsForBuild(bgbuild)
            })
        }
    }
    
    public func syncActiveConfiguration(ac: ActiveConfiguration) {
        if let bgac: ActiveConfiguration = self.dataMgr.ensureObjectOnBackgroundThread(ac) as? ActiveConfiguration {
            self.masterMOC.performBlock({
                self.requestHandler.importDetailsForActiveConfiguration(bgac)
            })
        }
    }
    
    // MARK: - Responses Received
    func jobDetailResponseReceived(notification: NSNotification) {
        var values: Dictionary = notification.userInfo!
        let job = values[RequestedObjectKey] as! Job
        
        job.managedObjectContext?.performBlock({
            values[JobLastSyncResultKey] = "200: OK"
            values[JobJenkinsInstanceKey] = job.rel_Job_JenkinsInstance
            values[JobLastSyncKey] = NSDate()
            job.setValues(values)
            self.saveContext(job.managedObjectContext)
        })
    }
    
    // triggered by successful view details requests
    func viewDetailResponseReceived(notification: NSNotification) {
        var values: Dictionary = notification.userInfo!
        let view = values[RequestedObjectKey] as! View
        
        view.managedObjectContext?.performBlock({
            values[ViewLastSyncResultKey] = "200: OK"
            values[ViewJenkinsInstanceKey] = view.rel_View_JenkinsInstance
            values[ViewParentViewKey] = view.rel_ParentView
            view.setValues(values)
            self.saveContext(view.managedObjectContext)
            self.dataMgr.masterMOC.performBlock({
                self.dataMgr.saveContext(self.dataMgr.masterMOC)
            })
        })
        
        //self.syncAllJobsForView(view)
        self.syncSubViewsForView(view)
    }
    
    // triggered by successful view child views requests
    func viewChildViewsResponseReceived(notification: NSNotification) {
        var values: Dictionary = notification.userInfo!
        let view = values[RequestedObjectKey] as! View
        
        view.managedObjectContext?.performBlock({
            values[ViewLastSyncResultKey] = "200: OK"
            values[ViewJenkinsInstanceKey] = view.rel_View_JenkinsInstance
            values[ViewParentViewKey] = view.rel_ParentView
            view.updateValues(values)
            self.saveContext(view.managedObjectContext)
            self.dataMgr.masterMOC.performBlock({
                self.dataMgr.saveContext(self.dataMgr.masterMOC)
            })
        })
        
        self.syncAllJobsForView(view)
        self.syncSubViewsForView(view)
    }
    
    func jenkinsInstanceDetailResponseReceived(notification: NSNotification) {
        var values: Dictionary = notification.userInfo!
        let ji: JenkinsInstance = values[RequestedObjectKey] as! JenkinsInstance
        
        ji.managedObjectContext?.performBlock({
            if (ji.lastSyncResult == nil) {
                self.notifyOfNewLargeInstance(values,url: ji.url!)
            }
            values[JenkinsInstanceEnabledKey] = true
            values[JenkinsInstanceAuthenticatedKey] = true
            values[JenkinsInstanceLastSyncResultKey] = "200: OK"
            values[JenkinsInstanceNameKey] = ji.name
            values[JenkinsInstanceURLKey] = ji.url
            values[JenkinsInstanceUsernameKey] = ji.username

            ji.setValues(values)
            self.saveContext(ji.managedObjectContext)
            self.dataMgr.masterMOC.performBlock({
                self.dataMgr.saveContext(self.dataMgr.masterMOC)
            })
            // post notification that we're done saving this JenkinsInstance
            let notification = NSNotification(name: JenkinsInstanceDidSaveNotification, object: nil, userInfo: [JenkinsInstanceURLKey: ji.url!])
            NSNotificationCenter.defaultCenter().postNotification(notification)

            self.syncAllViews(ji)
        })
    }
    
    // sends notification if this instance has > 1,000 jobs
    func notifyOfNewLargeInstance(values: [NSObject: AnyObject], url: String) {
        let views: [[String: AnyObject]] = values[JenkinsInstanceViewsKey] as! [[String: AnyObject]]
        var largestJobCnt = 0
        for view in views {
            let jobs: [[String: String]] = view[ViewJobsKey] as! [[String: String]]
            if (jobs.count > largestJobCnt) {
                largestJobCnt = jobs.count
            }
        }
        
        if (largestJobCnt > 1000) {
            // post notification that we're saving a new JenkinsInstance
            let notification = NSNotification(name: NewLargeJenkinsInstanceDetailResponseReceivedNotification, object: nil, userInfo: [JenkinsInstanceURLKey: url])
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }
    
    func jenkinsInstanceViewsResponseReceived(notification: NSNotification) {
        var values: Dictionary = notification.userInfo!
        let ji: JenkinsInstance = values[RequestedObjectKey] as! JenkinsInstance
        
        ji.managedObjectContext?.performBlock({
            values[JenkinsInstanceEnabledKey] = true
            values[JenkinsInstanceAuthenticatedKey] = true
            values[JenkinsInstanceLastSyncResultKey] = "200: OK"
            values[JenkinsInstanceNameKey] = ji.name
            values[JenkinsInstanceURLKey] = ji.url
            values[JenkinsInstanceUsernameKey] = ji.username
            
            ji.updateValues(values)
            self.saveContext(ji.managedObjectContext)
            self.dataMgr.masterMOC.performBlock({
                self.dataMgr.saveContext(self.dataMgr.masterMOC)
            })

            self.syncAllViews(ji)
        })
    }
    
    func buildDetailResponseReceived(notification: NSNotification) {
        var values: Dictionary = notification.userInfo!
        let build: Build = values[RequestedObjectKey] as! Build
        
        build.managedObjectContext?.performBlock({
            values[BuildLastSyncResultKey] = "200: OK"
            build.setValues(values)
            self.saveContext(build.managedObjectContext)
        })
    }
    
    func activeConfigurationDetailResponseReceived(notification: NSNotification) {
        var values: Dictionary = notification.userInfo!
        let ac: ActiveConfiguration = values[RequestedObjectKey] as! ActiveConfiguration
        let job = ac.rel_ActiveConfiguration_Job
        
        ac.managedObjectContext?.performBlock({
            values[ActiveConfigurationLastSyncResultKey] = "200: OK"
            values[ActiveConfigurationJobKey] = job
            values[ActiveConfigurationLastSyncKey] = NSDate()
            ac.setValues(values)
            self.saveContext(ac.managedObjectContext)
        })
    }
    
    // MARK: - Requests that Failed
    func jobDetailRequestFailed(notification: NSNotification) {
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        //let errorUserInfo: Dictionary = requestError.userInfo
        let job: Job = userInfo[RequestedObjectKey] as! Job
        switch requestError.code {
        case NSURLErrorBadServerResponse:
            let status: Int = userInfo[StatusCodeKey] as! Int
            switch status {
            case 404:
                job.managedObjectContext?.performBlock({
                    job.managedObjectContext?.deleteObject(job)
                    self.saveContext(job.managedObjectContext)
                })
            default:
                job.managedObjectContext?.performBlock({
                    job.lastSyncResult = String(status) + ": " + NSHTTPURLResponse.localizedStringForStatusCode(status)
                    self.saveContext(job.managedObjectContext)
                })
            }
        default:
            job.managedObjectContext?.performBlock({
                job.managedObjectContext?.deleteObject(job)
                self.saveContext(job.managedObjectContext)
            })
        }
    }
    
    // triggered by failed view details requests as well as failed view child views requests
    func viewDetailRequestFailed(notification: NSNotification) {
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        //let errorUserInfo: Dictionary = requestError.userInfo
        let view: View = userInfo[RequestedObjectKey] as! View
        
        switch requestError.code {
        case NSURLErrorBadServerResponse:
            let status: Int = userInfo[StatusCodeKey] as! Int
            switch status {
            case 404:
                view.managedObjectContext?.performBlock({
                    view.managedObjectContext?.deleteObject(view)
                    self.saveContext(view.managedObjectContext)
                })
            default:
                view.managedObjectContext?.performBlock({
                    view.lastSyncResult = String(status) + ": " + NSHTTPURLResponse.localizedStringForStatusCode(status)
                    self.saveContext(view.managedObjectContext)
                })
            }
        default:
            view.managedObjectContext?.performBlock({
                view.managedObjectContext?.deleteObject(view)
                self.saveContext(view.managedObjectContext)
            })
        }
    }
    
    func jenkinsInstanceDetailRequestFailed(notification: NSNotification) {
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        //let errorUserInfo: Dictionary = requestError.userInfo
        let ji: JenkinsInstance = userInfo[RequestedObjectKey] as! JenkinsInstance
        
        switch requestError.code {
        case NSURLErrorBadServerResponse:
            let status: Int = userInfo[StatusCodeKey] as! Int
            let message: String = String(status) + ": " + NSHTTPURLResponse.localizedStringForStatusCode(status)
            switch status {
            case 401:
                unauthenticateJenkinsInstance(ji,message: message)
            case 403:
                unauthenticateJenkinsInstance(ji,message: message)
            case 404:
                disableJenkinsInstance(ji,message: message)
            default:
                disableJenkinsInstance(ji,message: message)
            }
        default:
            print(requestError.localizedDescription)
            disableJenkinsInstance(ji,message: requestError.localizedDescription)
        }
    }
    
    func buildDetailRequestFailed(notification: NSNotification) {
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        //let errorUserInfo: Dictionary = requestError.userInfo
        let build: Build = userInfo[RequestedObjectKey] as! Build
        
        switch requestError.code {
        case NSURLErrorBadServerResponse:
            let status: Int = userInfo[StatusCodeKey] as! Int
            switch status {
            case 404:
                build.managedObjectContext?.performBlock({
                    build.managedObjectContext?.deleteObject(build)
                    self.saveContext(build.managedObjectContext)
                })
            default:
                build.managedObjectContext?.performBlock({
                    build.lastSyncResult = String(status) + ": " + NSHTTPURLResponse.localizedStringForStatusCode(status)
                    self.saveContext(build.managedObjectContext)
                })
            }
        default:
            build.managedObjectContext?.performBlock({
                build.managedObjectContext?.deleteObject(build)
                self.saveContext(build.managedObjectContext)
            })
        }
    }
    
    func activeConfigurationDetailRequestFailed(notification: NSNotification) {
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        //let errorUserInfo: Dictionary = requestError.userInfo
        let ac: ActiveConfiguration = userInfo[RequestedObjectKey] as! ActiveConfiguration
        
        switch requestError.code {
        case NSURLErrorBadServerResponse:
            let status: Int = userInfo[StatusCodeKey] as! Int
            switch status {
            case 404:
                ac.managedObjectContext?.performBlock({
                    ac.managedObjectContext?.deleteObject(ac)
                    self.saveContext(ac.managedObjectContext)
                })
            default:
                ac.managedObjectContext?.performBlock({
                    ac.lastSyncResult = String(status) + ": " + NSHTTPURLResponse.localizedStringForStatusCode(status)
                    self.saveContext(ac.managedObjectContext)
                })
            }
        default:
            ac.managedObjectContext?.performBlock({
                ac.managedObjectContext?.deleteObject(ac)
                self.saveContext(ac.managedObjectContext)
            })
        }
    }

    // MARK: - Helper methods
    // TODO: Should these go in the JenkinsInstance model?
    func unauthenticateJenkinsInstance(ji: JenkinsInstance, message: String) {
        ji.managedObjectContext?.performBlock({
            ji.authenticated = false
            ji.lastSyncResult = message
            self.saveContext(ji.managedObjectContext)
        })
    }
    
    func disableJenkinsInstance(ji: JenkinsInstance, message: String) {
        ji.managedObjectContext?.performBlock({
            ji.enabled = false
            ji.lastSyncResult = message
            self.saveContext(ji.managedObjectContext)
        })
    }
    
    // MARK: NSManagedObjectContext management
    func saveContext(context: NSManagedObjectContext?) {
        self.dataMgr.saveContext(context!)
    }
}