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
    var currentJenkinsInstance: JenkinsInstance?    
    private var jobSyncQueue = UniqueQueue<Job>()
    private var viewSyncQueue = UniqueQueue<View>()
    private var buildSyncQueue = UniqueQueue<Build>()
    private var syncTimer: NSTimer?
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
            syncTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("syncTimerTick"), userInfo: nil, repeats: true)
        }
    }
    
    // set up any NSNotificationCenter observers
    func initObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jobDetailResponseReceived:"), name: JobDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jobDetailRequestFailed:"), name: JobDetailRequestFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jenkinsInstanceDetailResponseReceived:"), name: JenkinsInstanceDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("jenkinsInstanceDetailRequestFailed:"), name: JenkinsInstanceDetailRequestFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("viewDetailResponseReceived:"), name: ViewDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("viewDetailRequestFailed:"), name: ViewDetailRequestFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("buildDetailResponseReceived:"), name: BuildDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("buildDetailRequestFailed:"), name: BuildDetailRequestFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("activeConfigurationDetailResponseReceived:"), name: ActiveConfigurationDetailResponseReceivedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("activeConfigurationDetailRequestFailed:"), name: ActiveConfigurationDetailRequestFailedNotification, object: nil)
    }
    
    func syncTimerTick() {
        if (jobSyncQueue.count() > 0) {
            // pop a job from the jobQueue and sync it
            self.masterMOC?.performBlock({
                let job = self.jobSyncQueue.pop()!
                self.syncJob(job)
            })
        }
        
        if (viewSyncQueue.count() > 0) {
            // pop a view from the jobQueue and sync it
            self.masterMOC?.performBlock({
                let view = self.viewSyncQueue.pop()!
                self.syncView(view)
            })
        }
        
        if (buildSyncQueue.count() > 0) {
            // pop a build from the jobQueue and sync it
            self.masterMOC?.performBlock({
                let build = self.buildSyncQueue.pop()!
                self.syncBuild(build)
            })
        }
    }
    
    public func jobSyncQueueSize() -> Int { return jobSyncQueue.count() }
    
    func syncAllJobs(jenkinsInstance: JenkinsInstance) {
        masterMOC?.performBlock({
            if let bgji: JenkinsInstance = self.ensureObjectOnBackgroundThread(jenkinsInstance) as? JenkinsInstance {
                let allJobs = bgji.rel_Jobs
                for job in allJobs {
                    self.jobSyncQueue.push(job as! Job)
                }
            } else {
                println("Error syncing all Jobs: Unable to retrieve JenkinsInstance from background context.")
            }
        })
    }
    
    func syncAllViews(jenkinsInstance: JenkinsInstance) {
        masterMOC?.performBlock({
            if let bgji: JenkinsInstance = self.ensureObjectOnBackgroundThread(jenkinsInstance) as? JenkinsInstance {
                let allViews = bgji.rel_Views
                for view in allViews {
                    self.viewSyncQueue.push(view as! View)
                }
            } else {
                println("Error syncing all Views: Unable to retrieve JenkinsInstance from background context.")
            }
        })
    }
    
    func syncAllJobsForView(view: View) {
        masterMOC?.performBlock({
            let viewjobs = view.rel_View_Jobs
            for job in viewjobs {
                self.jobSyncQueue.push(job as! Job)
            }
        })
    }
    
    func syncSubViewsForView(view: View) {
        masterMOC?.performBlock({
            let subviews = view.rel_View_Views
            for subview in subviews {
                self.viewSyncQueue.push(subview as! View)
            }
        })
    }
    
    func syncJenkinsInstance(instance: JenkinsInstance) {
        assert(self.requestHandler != nil, "sync manager's requestHandler is nil!!!")
        self.requestHandler!.importDetailsForJenkinsInstance(instance)
    }
    
    func syncView(view: View) {
        // sync view details and queue all jobs in view for sync
        assert(self.requestHandler != nil, "sync manager's requestHandler is nil!!!")
        self.requestHandler!.importDetailsForView(view)
    }
    
    func syncJob(job: Job) {
        assert(self.requestHandler != nil, "sync manager's requestHandler is nil!!")
        self.requestHandler!.importDetailsForJob(job)
    }
    
    func syncBuild(build: Build) {
        assert(self.requestHandler != nil, "sync manager's requestHandler is nil!!")
        self.requestHandler!.importDetailsForBuild(build)
    }
    
    func syncActiveConfiguration(ac: ActiveConfiguration) {
        assert(self.requestHandler != nil, "sync manager's requestHandler is nil!!")
        self.requestHandler!.importDetailsForActiveConfiguration(ac)
    }
    
    func jobDetailResponseReceived(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
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
    
    func jobDetailRequestFailed(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set!!")
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        let errorUserInfo: Dictionary = requestError.userInfo!
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
    
    func viewDetailResponseReceived(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
        var values: Dictionary = notification.userInfo!
        let view = values[RequestedObjectKey] as! View
        
        view.managedObjectContext?.performBlock({
            values[ViewLastSyncResultKey] = "200: OK"
            values[ViewJenkinsInstanceKey] = view.rel_View_JenkinsInstance
            view.setValues(values)
            self.saveContext(view.managedObjectContext)
        })
        
        // TODO: fix so that this works
        //self.syncAllJobsForView(view!)
    }
    
    func viewDetailRequestFailed(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        let errorUserInfo: Dictionary = requestError.userInfo!
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
    
    func jenkinsInstanceDetailResponseReceived(notification: NSNotification) {
        assert(self.masterMOC != nil, "main managed object context not set")
        var values: Dictionary = notification.userInfo!
        let ji: JenkinsInstance = values[RequestedObjectKey] as! JenkinsInstance
        
        ji.managedObjectContext?.performBlock({
            values[JenkinsInstanceCurrentKey] = false
            values[JenkinsInstanceEnabledKey] = true
            values[JenkinsInstanceAuthenticatedKey] = true
            values[JenkinsInstanceLastSyncResultKey] = "200: OK"
            values[JenkinsInstanceNameKey] = ji.name
            values[JenkinsInstanceURLKey] = ji.url
            values[JenkinsInstanceUsernameKey] = ji.username
            
            ji.setValues(values)
            self.saveContext(ji.managedObjectContext)            
            self.syncAllJobs(ji)
            self.syncAllViews(ji)
        })
    }
    
    func jenkinsInstanceDetailRequestFailed(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        let errorUserInfo: Dictionary = requestError.userInfo!
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
            println(requestError.localizedDescription)
            disableJenkinsInstance(ji,message: requestError.localizedDescription)
        }
    }
    
    func buildDetailResponseReceived(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
        var values: Dictionary = notification.userInfo!
        let build: Build = values[RequestedObjectKey] as! Build
        
        build.managedObjectContext?.performBlock({
            values[BuildLastSyncResultKey] = "200: OK"
            build.setValues(values)
            self.saveContext(build.managedObjectContext)
        })
    }
    
    func buildDetailRequestFailed(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        let errorUserInfo: Dictionary = requestError.userInfo!
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
    
    func activeConfigurationDetailResponseReceived(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
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
    
    func activeConfigurationDetailRequestFailed(notification: NSNotification) {
        assert(self.masterMOC != nil, "master managed object context not set")
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        let errorUserInfo: Dictionary = requestError.userInfo!
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
    
    // takes an NSManagedObject and if it isn't already on a background thread
    // ie. on the main queue NSManagedObjectContext
    // looks it up by NSManagedObjectID from the background NSManagedObjectContext
    func ensureObjectOnBackgroundThread(obj: NSManagedObject) -> NSManagedObject? {
        var bgobj: NSManagedObject? = obj
        if obj.managedObjectContext?.concurrencyType == NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType {
            var error: NSError? = nil
            bgobj = self.masterMOC?.existingObjectWithID(obj.objectID, error: &error)
            if bgobj == nil {
               println("Error retrieving object from background context: \(error?.localizedDescription)\n\(error?.userInfo)")
            }
        }
        return bgobj
    }
    
    // saves the main managedObjectContext and then also updates the masterManagedObjectContext
    func saveMainContext() {
        self.saveContext(self.mainMOC)
        self.masterMOC?.performBlock({
            self.saveContext(self.masterMOC)
        })
    }
    
    func saveContext(moc: NSManagedObjectContext?) {
        var error: NSError? = nil
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
            //println("Successfully saved master managed object context")
        }
    }
}