//
//  SyncManager.swift
//  JenkinsMobile
//
//  Created by Kyle on 9/15/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

import Foundation
import CoreData

open class SyncManager: NSObject {

    var dataMgr: DataManager = DataManager.sharedInstance
    var masterMOC: NSManagedObjectContext
    var mainMOC: NSManagedObjectContext
    
    var currentJenkinsInstance: JenkinsInstance? {
        didSet {
            if (currentJenkinsInstance != nil) {
                self.syncJenkinsInstance(currentJenkinsInstance!)
                self.updateCurrentURLPref(currentJenkinsInstance!.url!)
                let notification = Notification(name: NSNotification.Name.SyncManagerCurrentJenkinsInstanceChanged, object: nil)
                NotificationCenter.default.post(notification)
            }
        }
    }
    
    fileprivate var jobSyncQueue = UniqueQueue<Job>()
    fileprivate var viewSyncQueue = UniqueQueue<View>()
    fileprivate var buildSyncQueue = UniqueQueue<Build>()
    fileprivate var syncTimer: Timer?
    //var currentBuilds: NSMutableArray
    //var currentBuildsTimer: NSTimer
    var requestHandler: KDBJenkinsRequestHandler
    
    
    // MARK: - Init and Setup
    open class var sharedInstance : SyncManager {
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
        let defaults = UserDefaults.standard
        if let url: String = defaults.string(forKey: SyncManagerCurrentJenkinsInstance) {
            self.currentJenkinsInstance = JenkinsInstance.fetch(withURL: url, from: self.mainMOC)
        }
    }
    
    func initTimer() {
        let runningTests = NSClassFromString("XCTestCase") != nil
        if !runningTests {
            // only start the timer if we aren't running unit tests
            syncTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(SyncManager.syncTimerTick), userInfo: nil, repeats: true)
        }
    }
    
    // set up any NSNotificationCenter observers
    func initObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.jobDetailResponseReceived(_:)), name: NSNotification.Name.JobDetailResponseReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.jobDetailRequestFailed(_:)), name: NSNotification.Name.JobDetailRequestFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.jenkinsInstanceDetailResponseReceived(_:)), name: NSNotification.Name.JenkinsInstanceDetailResponseReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.jenkinsInstanceDetailRequestFailed(_:)), name: NSNotification.Name.JenkinsInstanceDetailRequestFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.jenkinsInstanceViewsResponseReceived(_:)), name: NSNotification.Name.JenkinsInstanceViewsResponseReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.jenkinsInstanceDetailRequestFailed(_:)), name: NSNotification.Name.JenkinsInstanceViewsRequestFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.viewDetailResponseReceived(_:)), name: NSNotification.Name.ViewDetailResponseReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.viewChildViewsResponseReceived(_:)), name: NSNotification.Name.ViewChildViewsResponseReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.viewDetailRequestFailed(_:)), name: NSNotification.Name.ViewDetailRequestFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.viewDetailRequestFailed(_:)), name: NSNotification.Name.ViewChildViewsRequestFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.buildDetailResponseReceived(_:)), name: NSNotification.Name.BuildDetailResponseReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.buildDetailRequestFailed(_:)), name: NSNotification.Name.BuildDetailRequestFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.activeConfigurationDetailResponseReceived(_:)), name: NSNotification.Name.ActiveConfigurationDetailResponseReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.activeConfigurationDetailRequestFailed(_:)), name: NSNotification.Name.ActiveConfigurationDetailRequestFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.buildProgressResponseReceived(_:)), name: NSNotification.Name.BuildProgressResponseReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SyncManager.buildConsoleTextReceived(_:)), name: NSNotification.Name.BuildConsoleTextResponseReceived, object: nil)
    }
    
    func syncTimerTick() {
        if (jobSyncQueue.count() > 0) {
            // pop a job from the jobQueue and sync it
            self.masterMOC.perform({
                let job = self.jobSyncQueue.pop()!
                self.syncJob(job)
            })
        }
        
        if (viewSyncQueue.count() > 0) {
            // pop a view from the jobQueue and sync it
            self.masterMOC.perform({
                let view = self.viewSyncQueue.pop()!
                self.syncView(view)
            })
        }
        
        if (buildSyncQueue.count() > 0) {
            // pop a build from the jobQueue and sync it
            self.masterMOC.perform({
                let build = self.buildSyncQueue.pop()!
                self.syncBuild(build)
            })
        }
    }
    
    func updateCurrentURLPref(_ newURL: String) {
        let defaults = UserDefaults.standard
        defaults.set(newURL, forKey: SyncManagerCurrentJenkinsInstance)
    }
    
    open func jobSyncQueueSize() -> Int { return jobSyncQueue.count() }
    
    // MARK: - Sync Objects
    open func syncAllJobs(_ jenkinsInstance: JenkinsInstance) {
        masterMOC.perform({
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
    
    open func syncAllViews(_ jenkinsInstance: JenkinsInstance) {
        masterMOC.perform({
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
    
    open func syncAllJobsForView(_ view: View) {
        if let bgview: View = self.dataMgr.ensureObjectOnBackgroundThread(view) as? View {
            masterMOC.perform({
                let viewjobs = bgview.rel_View_Jobs
                for job in viewjobs! {
                    self.jobSyncQueue.push(job)
                }
            })
        }
    }
    
    open func syncSubViewsForView(_ view: View) {
        if let bgview: View = self.dataMgr.ensureObjectOnBackgroundThread(view) as? View {
            masterMOC.perform({
                let subviews = bgview.rel_View_Views
                for subview in subviews! {
                    self.viewSyncQueue.push(subview)
                }
            })
        }
    }
    
    open func syncJenkinsInstance(_ instance: JenkinsInstance) {
        if let bgji: JenkinsInstance = self.dataMgr.ensureObjectOnBackgroundThread(instance) as? JenkinsInstance {
            self.masterMOC.perform({
                self.requestHandler.importDetails(for: bgji)                
            })
        }
    }
    
    open func syncViewsForJenkinsInstance(_ instance: JenkinsInstance) {
        if let bgji: JenkinsInstance = self.dataMgr.ensureObjectOnBackgroundThread(instance) as? JenkinsInstance {
            self.masterMOC.perform({
                self.requestHandler.importViews(for: bgji)
            })
        }
    }
    
    open func syncView(_ view: View) {
        if let bgview: View = self.dataMgr.ensureObjectOnBackgroundThread(view) as? View {
            self.masterMOC.perform({
                // sync view details and queue all jobs in view for sync
                self.requestHandler.importDetails(for: bgview)
            })
        }
    }
    
    open func syncChildViewsForView(_ view: View) {
        if let bgview: View = self.dataMgr.ensureObjectOnBackgroundThread(view) as? View {
            self.masterMOC.perform({
                self.requestHandler.importChildViews(for: bgview)
            })
        }
    }
    
    open func syncJob(_ job: Job) {
        if let bgjob: Job = self.dataMgr.ensureObjectOnBackgroundThread(job) as? Job {
            self.masterMOC.perform({
                self.requestHandler.importDetails(for: bgjob)
            })
        }
    }
    
    open func syncLatestBuildsForJob(_ job: Job, numberOfBuilds: Int32) {
        if let bgjob: Job = self.dataMgr.ensureObjectOnBackgroundThread(job) as? Job {
            self.masterMOC.perform({
                if let latestBuilds: [Build] = bgjob.fetchLatestBuilds(numberOfBuilds) as? [Build] {
                    for build: Build in latestBuilds {
                        self.buildSyncQueue.push(build)
                    }
                }
            })
        }
    }
    
    open func syncBuild(_ build: Build) {
        if let bgbuild: Build = self.dataMgr.ensureObjectOnBackgroundThread(build) as? Build {
            self.masterMOC.perform({
                self.requestHandler.importDetails(for: bgbuild)
            })
        }
    }
    
    open func syncActiveConfiguration(_ ac: ActiveConfiguration) {
        if let bgac: ActiveConfiguration = self.dataMgr.ensureObjectOnBackgroundThread(ac) as? ActiveConfiguration {
            self.masterMOC.perform({
                self.requestHandler.importDetails(for: bgac)
            })
        }
    }
    
    open func syncProgressForBuild(_ build: Build, jenkinsInstance: JenkinsInstance) {
        if let bgbuild: Build = self.dataMgr.ensureObjectOnBackgroundThread(build) as? Build,
            let bgji: JenkinsInstance = self.dataMgr.ensureObjectOnBackgroundThread(jenkinsInstance) as? JenkinsInstance{
            self.masterMOC.perform({
                self.requestHandler.importProgress(for: bgbuild, on: bgji)
            })
        }
    }
    
    open func syncConsoleTextForBuild(_ build: Build, jenkinsInstance: JenkinsInstance) {
        if let bgbuild: Build = self.dataMgr.ensureObjectOnBackgroundThread(build) as? Build,
            let bgji: JenkinsInstance = self.dataMgr.ensureObjectOnBackgroundThread(jenkinsInstance) as? JenkinsInstance{
            self.masterMOC.perform({
                self.requestHandler.importConsoleText(for: bgbuild, on: bgji)
            })
        }
    }
    
    // MARK: - Responses Received
    func jobDetailResponseReceived(_ notification: Notification) {
        var values: Dictionary = notification.userInfo!
        let job = values[RequestedObjectKey] as! Job
        
        job.managedObjectContext?.perform({
            values[JobLastSyncResultKey] = "200: OK"
            values[JobJenkinsInstanceKey] = job.rel_Job_JenkinsInstance
            values[JobLastSyncKey] = Date()
            job.setValues(values)
            self.saveContext(job.managedObjectContext)
        })
    }
    
    // triggered by successful view details requests
    func viewDetailResponseReceived(_ notification: Notification) {
        var values: Dictionary = notification.userInfo!
        let view = values[RequestedObjectKey] as! View
        
        view.managedObjectContext?.perform({
            values[ViewLastSyncResultKey] = "200: OK"
            values[ViewJenkinsInstanceKey] = view.rel_View_JenkinsInstance
            values[ViewParentViewKey] = view.rel_Parent
            view.setValues(values)
            self.saveContext(view.managedObjectContext)
            self.dataMgr.masterMOC.perform({
                self.dataMgr.saveContext(self.dataMgr.masterMOC)
            })
        })
        
        //self.syncAllJobsForView(view)
        self.syncSubViewsForView(view)
    }
    
    // triggered by successful view child views requests
    func viewChildViewsResponseReceived(_ notification: Notification) {
        var values: Dictionary = notification.userInfo!
        let view = values[RequestedObjectKey] as! View
        
        view.managedObjectContext?.perform({
            values[ViewLastSyncResultKey] = "200: OK"
            values[ViewJenkinsInstanceKey] = view.rel_View_JenkinsInstance
            values[ViewParentViewKey] = view.rel_Parent
            view.updateValues(values)
            self.saveContext(view.managedObjectContext)
            self.dataMgr.masterMOC.perform({
                self.dataMgr.saveContext(self.dataMgr.masterMOC)
            })
        })
        
        self.syncAllJobsForView(view)
        //self.syncSubViewsForView(view)
    }
    
    func jenkinsInstanceDetailResponseReceived(_ notification: Notification) {
        var values: Dictionary = notification.userInfo!
        let ji: JenkinsInstance = values[RequestedObjectKey] as! JenkinsInstance
        
        ji.managedObjectContext?.perform({
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
            self.dataMgr.masterMOC.perform({
                self.dataMgr.saveContext(self.dataMgr.masterMOC)
            })
            // post notification that we're done saving this JenkinsInstance
            let notification = Notification(name: NSNotification.Name.JenkinsInstanceDidSave, object: nil, userInfo: [JenkinsInstanceURLKey: ji.url!])
            NotificationCenter.default.post(notification)

            self.syncAllViews(ji)
        })
    }
    
    // sends notification if this instance has > 1,000 jobs
    func notifyOfNewLargeInstance(_ values: [AnyHashable: Any], url: String) {
        let views: [[String: AnyObject]] = values[JenkinsInstanceViewsKey] as! [[String: AnyObject]]
        var largestJobCnt = 0
        for view in views {
            let jobs: [[String: AnyObject]] = view[ViewJobsKey] as! [[String: AnyObject]]
            if (jobs.count > largestJobCnt) {
                largestJobCnt = jobs.count
            }
        }
        
        if (largestJobCnt > 1000) {
            // post notification that we're saving a new JenkinsInstance
            let notification = Notification(name: NSNotification.Name.NewLargeJenkinsInstanceDetailResponseReceived, object: nil, userInfo: [JenkinsInstanceURLKey: url])
            NotificationCenter.default.post(notification)
        }
    }
    
    func jenkinsInstanceViewsResponseReceived(_ notification: Notification) {
        var values: Dictionary = notification.userInfo!
        let ji: JenkinsInstance = values[RequestedObjectKey] as! JenkinsInstance
        
        ji.managedObjectContext?.perform({
            values[JenkinsInstanceEnabledKey] = true
            values[JenkinsInstanceAuthenticatedKey] = true
            values[JenkinsInstanceLastSyncResultKey] = "200: OK"
            values[JenkinsInstanceNameKey] = ji.name
            values[JenkinsInstanceURLKey] = ji.url
            values[JenkinsInstanceUsernameKey] = ji.username
            
            ji.updateValues(values)
            self.saveContext(ji.managedObjectContext)
            self.dataMgr.masterMOC.perform({
                self.dataMgr.saveContext(self.dataMgr.masterMOC)
            })


        })
    }
    
    func buildDetailResponseReceived(_ notification: Notification) {
        var values: Dictionary = notification.userInfo!
        let build: Build = values[RequestedObjectKey] as! Build
        
        build.managedObjectContext?.perform({
            values[BuildLastSyncResultKey] = "200: OK"
            values[BuildJobKey] = build.rel_Build_Job
            build.setValues(values)
            self.saveContext(build.managedObjectContext)
        })
    }
    
    func activeConfigurationDetailResponseReceived(_ notification: Notification) {
        var values: Dictionary = notification.userInfo!
        let ac: ActiveConfiguration = values[RequestedObjectKey] as! ActiveConfiguration
        let job = ac.rel_ActiveConfiguration_Job
        
        ac.managedObjectContext?.perform({
            values[ActiveConfigurationLastSyncResultKey] = "200: OK"
            values[ActiveConfigurationJobKey] = job
            values[ActiveConfigurationLastSyncKey] = Date()
            ac.setValues(values)
            self.saveContext(ac.managedObjectContext)
        })
    }
    
    func buildProgressResponseReceived(_ notification: Notification) {
        var values: Dictionary = notification.userInfo!
        let build: Build = values[RequestedObjectKey] as! Build
        
        build.managedObjectContext?.perform({
            build.setProgressUpdateValues(values)
            
            // if we switched to building to not building, re-query the job itself
            if let _ = build.changedValues()[BuildBuildingKey] {
                self.syncJob(build.rel_Build_Job!)
            }
            
            self.saveContext(build.managedObjectContext)
        })
    }
    
    func buildConsoleTextReceived(_ notification: Notification) {
        let values: Dictionary = notification.userInfo!
        let build: Build = values[RequestedObjectKey] as! Build
        let consoleText: String = values[BuildConsoleTextKey] as! String
        
        build.managedObjectContext?.perform({
            build.updateConsoleText(consoleText)
            self.saveContext(build.managedObjectContext)
        })
    }
    
    // MARK: - Requests that Failed
    func jobDetailRequestFailed(_ notification: Notification) {
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        //let errorUserInfo: Dictionary = requestError.userInfo
        let job: Job = userInfo[RequestedObjectKey] as! Job
        switch requestError.code {
        case NSURLErrorBadServerResponse:
            let status: Int = userInfo[StatusCodeKey] as! Int
            switch status {
            case 404:
                job.managedObjectContext?.perform({
                    job.managedObjectContext?.delete(job)
                    self.saveContext(job.managedObjectContext)
                })
            default:
                job.managedObjectContext?.perform({
                    job.lastSyncResult = String(status) + ": " + HTTPURLResponse.localizedString(forStatusCode: status)
                    self.saveContext(job.managedObjectContext)
                })
            }
        default:
            job.managedObjectContext?.perform({
                job.managedObjectContext?.delete(job)
                self.saveContext(job.managedObjectContext)
            })
        }
    }
    
    // triggered by failed view details requests as well as failed view child views requests
    func viewDetailRequestFailed(_ notification: Notification) {
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        //let errorUserInfo: Dictionary = requestError.userInfo
        let view: View = userInfo[RequestedObjectKey] as! View
        
        switch requestError.code {
        case NSURLErrorBadServerResponse:
            let status: Int = userInfo[StatusCodeKey] as! Int
            switch status {
            case 404:
                view.managedObjectContext?.perform({
                    view.managedObjectContext?.delete(view)
                    self.saveContext(view.managedObjectContext)
                })
            default:
                view.managedObjectContext?.perform({
                    view.lastSyncResult = String(status) + ": " + HTTPURLResponse.localizedString(forStatusCode: status)
                    self.saveContext(view.managedObjectContext)
                })
            }
        default:
            view.managedObjectContext?.perform({
                view.managedObjectContext?.delete(view)
                self.saveContext(view.managedObjectContext)
            })
        }
    }
    
    func jenkinsInstanceDetailRequestFailed(_ notification: Notification) {
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        //let errorUserInfo: Dictionary = requestError.userInfo
        let ji: JenkinsInstance = userInfo[RequestedObjectKey] as! JenkinsInstance
        
        switch requestError.code {
        case NSURLErrorBadServerResponse:
            let status: Int = userInfo[StatusCodeKey] as! Int
            let message: String = String(status) + ": " + HTTPURLResponse.localizedString(forStatusCode: status)
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
    
    func buildDetailRequestFailed(_ notification: Notification) {
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        //let errorUserInfo: Dictionary = requestError.userInfo
        let build: Build = userInfo[RequestedObjectKey] as! Build
        
        switch requestError.code {
        case NSURLErrorBadServerResponse:
            let status: Int = userInfo[StatusCodeKey] as! Int
            switch status {
            case 404:
                build.managedObjectContext?.perform({
                    build.managedObjectContext?.delete(build)
                    self.saveContext(build.managedObjectContext)
                })
            default:
                build.managedObjectContext?.perform({
                    build.lastSyncResult = String(status) + ": " + HTTPURLResponse.localizedString(forStatusCode: status)
                    self.saveContext(build.managedObjectContext)
                })
            }
        default:
            build.managedObjectContext?.perform({
                build.managedObjectContext?.delete(build)
                self.saveContext(build.managedObjectContext)
            })
        }
    }
    
    func activeConfigurationDetailRequestFailed(_ notification: Notification) {
        let userInfo: Dictionary = notification.userInfo!
        let requestError: NSError = userInfo[RequestErrorKey] as! NSError
        //let errorUserInfo: Dictionary = requestError.userInfo
        let ac: ActiveConfiguration = userInfo[RequestedObjectKey] as! ActiveConfiguration
        
        switch requestError.code {
        case NSURLErrorBadServerResponse:
            let status: Int = userInfo[StatusCodeKey] as! Int
            switch status {
            case 404:
                ac.managedObjectContext?.perform({
                    ac.managedObjectContext?.delete(ac)
                    self.saveContext(ac.managedObjectContext)
                })
            default:
                ac.managedObjectContext?.perform({
                    ac.lastSyncResult = String(status) + ": " + HTTPURLResponse.localizedString(forStatusCode: status)
                    self.saveContext(ac.managedObjectContext)
                })
            }
        default:
            ac.managedObjectContext?.perform({
                ac.managedObjectContext?.delete(ac)
                self.saveContext(ac.managedObjectContext)
            })
        }
    }

    // MARK: - Helper methods
    // TODO: Should these go in the JenkinsInstance model?
    func unauthenticateJenkinsInstance(_ ji: JenkinsInstance, message: String) {
        ji.managedObjectContext?.perform({
            ji.authenticated = false
            ji.lastSyncResult = message
            self.saveContext(ji.managedObjectContext)
        })
    }
    
    func disableJenkinsInstance(_ ji: JenkinsInstance, message: String) {
        ji.managedObjectContext?.perform({
            ji.enabled = false
            ji.lastSyncResult = message
            self.saveContext(ji.managedObjectContext)
        })
    }
    
    // MARK: NSManagedObjectContext management
    func saveContext(_ context: NSManagedObjectContext?) {
        self.dataMgr.saveContext(context!)
    }
}
