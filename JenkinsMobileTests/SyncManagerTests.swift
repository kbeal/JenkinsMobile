//
//  SyncManagerTests.swift
//  JenkinsMobile
//
//  Created by Kyle on 9/16/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

import Foundation
import XCTest
import JenkinsMobile


class SyncManagerTests: XCTestCase {

    let mgr = SyncManager.sharedInstance
    var context: NSManagedObjectContext?
    var jenkinsInstance: JenkinsInstance?
    
    override func setUp() {
        super.setUp()
        
        let requestHandler = KDBJenkinsRequestHandler()
        let modelURL = NSBundle.mainBundle().URLForResource("JenkinsMobile", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: modelURL!)
        let coord = NSPersistentStoreCoordinator(managedObjectModel: model!)
        context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)

        /* uncomment to use sqlite persistent store
        let bundle = NSBundle.mainBundle()
        let resourceURL = bundle.resourceURL
        let storeURL = resourceURL?.URLByAppendingPathComponent("JenkinsMobileTests.sqlite")
        coord.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: nil)
        */
        
        coord.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: nil)
        context!.persistentStoreCoordinator = coord
        mgr.mainMOC = context;
        mgr.masterMOC = context;
        mgr.requestHandler = requestHandler
        
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://jenkins:8080/"]
        let jenkinsInstanceValues = [JenkinsInstanceNameKey: "TestInstance", JenkinsInstanceURLKey: "http://jenkins:8080", JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "admin", JenkinsInstancePrimaryViewKey: primaryView]
        
        context?.performBlockAndWait({self.jenkinsInstance = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues, inManagedObjectContext: self.context)})
        self.jenkinsInstance?.password = "admin"
        self.jenkinsInstance?.allowInvalidSSLCertificate = true
        
        saveContext()
    }
    
    override func tearDown() {
        saveContext()
    }
    
    func saveContext () {
        var error: NSError? = nil
        if context == nil {
            return
        }
        if !context!.hasChanges {
            return
        }
        let saveResult: Bool = context!.save(&error)
        
        if (!saveResult) {
            println("Error saving context: \(error?.localizedDescription)\n\(error?.userInfo)")
            abort()
        }
        //else {
          //  println("Successfully saved test managed object context")
        //}
    }
    
    func testSyncView() {
        let viewSavedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let view = obj as? View {
                        if view.rel_View_Views.count==3 && view.name == "GrandParent" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let viewURL = "http://jenkins:8080/view/GrandParent/"
        let url = NSURL(string: viewURL)
        let viewVals = [ViewNameKey: "View1", ViewURLKey: viewURL, ViewJenkinsInstanceKey: jenkinsInstance!]
        let view1 = View.createViewWithValues(viewVals, inManagedObjectContext: context)
        saveContext()
        
        self.mgr.syncView(view1)
        
        // wait for expectations
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testSyncJob() {
        let jobSavedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let job = obj as? Job {
                        if job.url == "http://jenkins:8080/job/Job3/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let jobVals1 = [JobNameKey: "Job3", JobColorKey: "blue", JobURLKey: "http://jenkins:8080/job/Job3/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        saveContext()
        self.mgr.syncJob(job)
        
        // wait for expectations
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testSyncBuild() {
        let buildSavedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let build = obj as? Build {
                        if build.fullDisplayName == "Job3 #1" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/TestJob/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        let buildURL = "http://jenkins:8080/job/Job3/1/"
        let url = NSURL(string: buildURL)
        
        let buildVals = [BuildJobKey: job, BuildURLKey: buildURL, BuildNumberKey: 1]
        let build1 = Build.createBuildWithValues(buildVals, inManagedObjectContext: self.context)
        saveContext()
        
        self.mgr.syncBuild(build1)
        
        // wait for expectations
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testSyncActiveConfiguration() {
        let acSavedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ac = obj as? ActiveConfiguration {
                        if ac.name == "config1=10,config2=test" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let jobvals = [JobNameKey: "Job6", JobColorKey: "blue", JobURLKey: "http://jenkins:8080/job/Job6/", JobLastSyncKey: NSDate(), JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobvals, inManagedObjectContext: context)
        
        let ac1 = [ActiveConfigurationColorKey:"blue",ActiveConfigurationNameKey:"config=1",ActiveConfigurationJobKey:job,ActiveConfigurationURLKey:"http://jenkins:8080/job/Job6/config1=10,config2=test/"]
        let activeConf1 = ActiveConfiguration.createActiveConfigurationWithValues(ac1, inManagedObjectContext: context!)
        saveContext()
        
        self.mgr.syncActiveConfiguration(activeConf1)

        
        // wait for expectations
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testSharedInstance() {
        XCTAssertNotNil(mgr, "shared instance is nil")
    }
    
    func testJobShouldSync() {
        let jobvals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com", JobLastSyncKey: NSDate(), JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobvals, inManagedObjectContext: context)
        
        XCTAssertFalse(job.shouldSync(), "shouldsync should be false")
    }
    
    func testJenkinsInstanceFindOrCreated() {
        let jobObj1 = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com"]
        let jobObj2 = [JobNameKey: "Job2", JobColorKey: "red", JobURLKey: "http://www.yahoo.com"]
        let jobObj3 = [JobNameKey: "Job3", JobColorKey: "green", JobURLKey: "http://www.bing.com"]
        let jobObj4 = [JobNameKey: "Job4", JobColorKey: "grey", JobURLKey: "http://www.amazon.com"]
        let jobs = [jobObj1, jobObj2, jobObj3, jobObj4]
        
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://jenkins:8080/"]
        let values = [JenkinsInstanceNameKey: "QA Ubuntu", JenkinsInstanceURLKey: "https://jenkins.qa.ubuntu.com/", JenkinsInstanceJobsKey: jobs, JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true, JenkinsInstancePrimaryViewKey: primaryView]

        JenkinsInstance.findOrCreateJenkinsInstanceWithValues(values, inManagedObjectContext: context!)
        
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("JenkinsInstance", inManagedObjectContext: context!)
        fetchreq.predicate = NSPredicate(format: "name = %@", "QA Ubuntu")
        fetchreq.includesPropertyValues = false
        
        let jenkinss = context?.executeFetchRequest(fetchreq, error: nil)
        let ji = jenkinss![0] as JenkinsInstance

        XCTAssertEqual(jenkinss!.count, 1, "jenkinss count is wrong. Should be 1 got: \(jenkinss!.count) instead")
        XCTAssertEqual(ji.name, "QA Ubuntu", "jenkins instance name is wrong. should be QA Ubuntu, got: \(ji.name) instead")
        XCTAssertEqual(ji.rel_Jobs.count, 4, "jenkins instance job count is wrong. should be 4, got:\(ji.rel_Jobs.count) instead")
        XCTAssertEqual(ji.current, 0, "jenkins current should be false")
    }
    
    /*
    func testJenkinsInstanceSaveValues() {
        var jobs: [Dictionary<String, String>] = []
        
        for i in 1...10000 {
            let uuid = NSUUID().UUIDString
            jobs.append([JobNameKey: uuid, JobColorKey: "blue", JobURLKey: "http://www.google.com"])
        }
        
        let values = [JenkinsInstanceNameKey: "TestInstance", JenkinsInstanceURLKey: "http://www.google.com/api/json", JenkinsInstanceCurrentKey: false, JenkinsInstanceJobsKey: jobs, JenkinsInstanceEnabledKey: true]
        
        let ji = JenkinsInstance.createJenkinsInstanceWithValues(values, inManagedObjectContext: context)
        
        XCTAssertEqual(ji.rel_Jobs.count, 10000, "jenkins instance's jobs count is wrong")
        
        jobs.removeAll(keepCapacity: true)
        for i in 1...10000 {
            let uuid = NSUUID().UUIDString
            jobs.append([JobNameKey: uuid, JobColorKey: "blue", JobURLKey: "http://www.google.com"])
        }
        
        let newvalues = [JenkinsInstanceNameKey: "TestInstance", JenkinsInstanceURLKey: "http://www.google.com/api/json", JenkinsInstanceCurrentKey: false, JenkinsInstanceJobsKey: jobs, JenkinsInstanceEnabledKey: true]
        
        self.measureBlock({
          ji.setValues(newvalues)
        })
        
        XCTAssertEqual(ji.rel_Jobs.count, 20000, "jenkins instance's jobs count is wrong")
    }*/
    
    func testJenkinsInstanceRequestFailed() {
        let requestFailureExpectation = expectationWithDescription("JenkinsInstance will be disabled")
        let jInstanceDisabledNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        if ji.url == self.jenkinsInstance!.url && !ji.enabled.boolValue {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        // set up a request to a url that doesn't exist
        let url = NSURL(string: self.jenkinsInstance!.url)
        let requestURL = NSURL(string: "404", relativeToURL: url!)
        let manager = AFHTTPRequestOperationManager(baseURL: url)
        let reqSerializer = AFHTTPRequestSerializer()
        reqSerializer.setAuthorizationHeaderFieldWithUsername("admin", password: "admin")
        manager.requestSerializer = reqSerializer
        let respSerializer = AFJSONResponseSerializer()
        manager.responseSerializer = respSerializer
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("JenkinsInstance", inManagedObjectContext: context!)
        fetchreq.includesPropertyValues = false
        let jenkinss = context?.executeFetchRequest(fetchreq, error: nil)
        XCTAssertEqual(jenkinss!.count, 1, "jenkinss count is wrong. should  be 1 got: \(jenkinss!.count) instead")
        
        manager.GET(requestURL?.absoluteString, parameters: nil, success:
            { operation, response in
                println("jenkins request received")
                abort()
            },
            failure: { operation, error in
                var errUserInfo: [NSObject : AnyObject] = error.userInfo!
                // since the JenkinsInstance actually exists, we need to inject it's url so that coredata can find it.
                errUserInfo[NSErrorFailingURLKey] = NSURL(string: self.jenkinsInstance!.url)
                let newError = NSError(domain: error.domain, code: error.code, userInfo: errUserInfo)
                var userInfo: [NSObject : AnyObject] = [RequestErrorKey: newError]
                if let response = operation.response {
                    userInfo[StatusCodeKey] = response.statusCode
                }
                userInfo[RequestedObjectKey] = self.jenkinsInstance
                let notification = NSNotification(name: JenkinsInstanceDetailRequestFailedNotification, object: self, userInfo: userInfo)
                self.mgr.jenkinsInstanceDetailRequestFailed(notification)
                requestFailureExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testJenkinsInstanceUnauthenticated() {
        let jInstanceUnauthenticatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        if ji.url == "https://snowman:8443/jenkins/" && ji.enabled.boolValue && !ji.authenticated.boolValue {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://jenkins:8080/"]
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "https://snowman:8443/jenkins/", JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "admin", JenkinsInstanceAuthenticatedKey: true, JenkinsInstancePrimaryViewKey: primaryView]
        let jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1, inManagedObjectContext: self.context)
        jinstance1.allowInvalidSSLCertificate = true
        jinstance1.password = "password"
        saveContext()
        
        XCTAssert(jinstance1.enabled.boolValue, "jenkins instance should be enabled")
        XCTAssert(jinstance1.authenticated.boolValue, "jenkins instance should be authenticated")
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJenkinsInstance(jinstance1)
        
        waitForExpectationsWithTimeout(2, handler: { error in
            
        })
    }
    
    func testJenkinsInstanceReauthenticated() {
        let jInstanceUnauthenticatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        if ji.url == "https://snowman:8443/jenkins/" && ji.enabled.boolValue && ji.authenticated.boolValue {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://jenkins:8080/"]
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "https://snowman:8443/jenkins/", JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "jenkinsadmin", JenkinsInstancePrimaryViewKey: primaryView]
        let jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1, inManagedObjectContext: self.context)
        jinstance1.allowInvalidSSLCertificate = true
        jinstance1.password = "changeme"
        jinstance1.authenticated = false
        saveContext()
        
        XCTAssert(jinstance1.enabled.boolValue, "jenkins instance should be enabled")
        XCTAssertFalse(jinstance1.authenticated.boolValue, "jenkins instance should not be authenticated")
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJenkinsInstance(jinstance1)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testJenkinsInstanceLastSyncResultOK() {
        let jiUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        let priView: [String: String] = ji.primaryView as [String: String]
                        let priViewName = priView[ViewNameKey]
                        let jiviews: [View] = ji.rel_Views.allObjects as [View]
                        var priViewURL: String?
                        for view: View in jiviews {
                            if view.name == priViewName {
                                priViewURL = view.url
                            }
                        }
                        if ji.lastSyncResult == "200: OK" && ji.url == "http://snowman:8080/jenkins/" && priViewURL == "https://snowman:8443/jenkins/view/Test/" {
                            expectationFulfilled=true
                        } else {
                            println(ji.url + ": " + ji.lastSyncResult)
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let primaryView = [ViewNameKey: "Test", ViewURLKey: "https://snowman:8443/jenkins/"]
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "http://snowman:8080/jenkins/", JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "jenkinsadmin", JenkinsInstancePrimaryViewKey: primaryView]
        let jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1, inManagedObjectContext: self.context)
        jinstance1.password = "changeme"
        jinstance1.allowInvalidSSLCertificate = true;
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJenkinsInstance(jinstance1)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testJenkinsInstanceLastSyncResult401() {
        let viewUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        if ji.lastSyncResult == "401: unauthorized" && ji.url == "https://snowman:8443/jenkins/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://jenkins:8080/"]
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "https://snowman:8443/jenkins/", JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "user", JenkinsInstancePrimaryViewKey: primaryView]
        let jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1, inManagedObjectContext: self.context)
        jinstance1.password = "password1"
        jinstance1.allowInvalidSSLCertificate = true;
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJenkinsInstance(jinstance1)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testJenkinsInstanceLastSyncResult403() {
        let viewUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        if ji.lastSyncResult == "403: forbidden" && ji.url == "https://snowman:8443/jenkins/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://jenkins:8080/"]
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "https://snowman:8443/jenkins/", JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "littleone", JenkinsInstancePrimaryViewKey: primaryView]
        let jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1, inManagedObjectContext: self.context)
        jinstance1.password = "changeme"
        jinstance1.allowInvalidSSLCertificate = true;
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJenkinsInstance(jinstance1)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testJobDetailResponseReceived() {
        let jobUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let job = obj as? Job {
                        if job.name == "Job1" && job.job_description == "Job1 Description" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        // create the job as it would be received from a JenkinsInstance jobs object
        let jobObj1 = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com", JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJobWithValues(jobObj1, inManagedObjectContext: context!)
        saveContext()
        
        // create the data that would be returned by a call to this job's api/json
        let build1Obj = ["number": 1, "url": "http://www.google.com/job/Job1/build/1"]
        let downstreamObj1 = ["name": "Job2", "color": "blue", "url":"http://www.ask.com"]
        let downstreamObj2 = ["name": "Job3", "color": "green", "url":"http://www.yahoo.com"]
        let upstreamObj1 = ["name": "Job4", "color": "red", "url":"http://www.bing.com"]
        let downstreamProjects = [downstreamObj1, downstreamObj2]
        let upstreamProjects = [upstreamObj1]
        let healthReport = ["iconUrl": "health-80plus.png"]
        let ac1 = [ActiveConfigurationColorKey:"blue",ActiveConfigurationNameKey:"config=1",ActiveConfigurationJobKey:job1,ActiveConfigurationURLKey:"http://www.google.com/job/Job1/config=1"]
        let activeConf1 = ActiveConfiguration.createActiveConfigurationWithValues(ac1, inManagedObjectContext: context!)
        let activeConfs = [activeConf1]
        let testImage = UIImage(named: "blue.png")
        
        let userInfo = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/Job1", JobBuildableKey: true, JobConcurrentBuildKey: false, JobDisplayNameKey: "Job1", JobFirstBuildKey: build1Obj, JobLastBuildKey: build1Obj, JobLastCompletedBuildKey: build1Obj, JobLastFailedBuildKey: build1Obj, JobLastStableBuildKey: build1Obj, JobLastSuccessfulBuildKey: build1Obj,JobLastUnstableBuildKey: build1Obj, JobLastUnsucessfulBuildKey: build1Obj, JobNextBuildNumberKey: 2, JobInQueueKey: false, JobDescriptionKey: "Job1 Description", JobKeepDependenciesKey: false, JobJenkinsInstanceKey: jenkinsInstance!, JobDownstreamProjectsKey: downstreamProjects, JobUpstreamProjectsKey: upstreamProjects, JobHealthReportKey: healthReport, JobActiveConfigurationsKey: activeConfs, JobLastSyncKey: NSDate(), RequestedObjectKey: job1]
        let notification = NSNotification(name: JobDetailResponseReceivedNotification, object: self, userInfo: userInfo)
        
        mgr.jobDetailResponseReceived(notification)
        
        waitForExpectationsWithTimeout(2, handler: { error in
            
        })
    }
    
    func testJobDetailRequestFailed() {
        let requestFailureExpectation = expectationWithDescription("Job1 will be deleted")
        let jobDeletedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
                var expectationFulfilled = false
                let deletedObjects: NSSet? = notification.userInfo![NSDeletedObjectsKey] as NSSet?
                if deletedObjects != nil {
                    for obj in deletedObjects! {
                        if let job1 = obj as? Job {
                            if job1.name == "Job1" {
                                expectationFulfilled=true
                            }
                        }
                    }
                }
                return expectationFulfilled
        })

        let jobURL = "http://www.google.com/job/Job1/api/json"
        let url = NSURL(string: jobURL)
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com", JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJobWithValues(job1vals, inManagedObjectContext: context)
        saveContext()
        
        // set up a request to a url that doesn't exist
        let manager = AFHTTPRequestOperationManager(baseURL: url)
        let reqSerializer = AFHTTPRequestSerializer()
        reqSerializer.setAuthorizationHeaderFieldWithUsername("admin", password: "admin")
        manager.requestSerializer = reqSerializer
        let respSerializer = AFJSONResponseSerializer()
        manager.responseSerializer = respSerializer
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("Job", inManagedObjectContext: context!)
        fetchreq.includesPropertyValues = false
        let jobs = context?.executeFetchRequest(fetchreq, error: nil)
        XCTAssertEqual(jobs!.count, 1, "jobs count is wrong. should  be 1 got: \(jobs!.count) instead")
        
        manager.GET(url?.absoluteString, parameters: nil, success:
            { operation, response in
                println("jenkins request received")
                abort()
            },
            failure: { operation, error in
                var userInfo: [NSObject : AnyObject] = [RequestErrorKey: error]
                if let response = operation.response {
                    userInfo[StatusCodeKey] = response.statusCode
                }
                userInfo[RequestedObjectKey] = job1
                let notification = NSNotification(name: JobDetailRequestFailedNotification, object: self, userInfo: userInfo)
                self.mgr.jobDetailRequestFailed(notification)
                requestFailureExpectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testJobLastSyncResultOK() {
        let jobUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let job1 = obj as? Job {
                        if job1.lastSyncResult == "200: OK" && job1.url == "https://snowman:8443/jenkins/job/Job1/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let jobURLStr = "http://snowman:8080/jenkins/job/Job1/"
        let jobURL = NSURL(string: jobURLStr)
        jenkinsInstance?.username = "jenkinsadmin"
        jenkinsInstance?.password = "changeme"
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: jobURLStr, JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJobWithValues(job1vals, inManagedObjectContext: context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJob(job1)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testJobLastSyncResult401() {
        let jobUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let job1 = obj as? Job {
                        if job1.lastSyncResult == "401: unauthorized" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        jenkinsInstance?.username = "user"
        jenkinsInstance?.password = "password1"
        let jobURLStr = "http://jenkins:8080/job/Job3/"
        let jobURL = NSURL(string: jobURLStr)
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: jobURLStr, JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJobWithValues(job1vals, inManagedObjectContext: context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJob(job1)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testJobLastSyncResult403() {
        let jobUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let job1 = obj as? Job {
                        if job1.lastSyncResult == "403: forbidden" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        jenkinsInstance?.username = "user"
        jenkinsInstance?.password = "password"
        let jobURLStr = "http://jenkins:8080/job/Job3/"
        let jobURL = NSURL(string: jobURLStr)
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: jobURLStr, JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJobWithValues(job1vals, inManagedObjectContext: context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJob(job1)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testViewDetailResponseReceived() {
        let viewUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let view = obj as? View {
                        if view.lastSyncResult == "200: OK" && view.url == "http://www.google.com/jenkins/view/Parent/" && view.view_description == "this is the parent view" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let viewURL = "http://www.google.com/jenkins/view/Parent/"
        let url = NSURL(string: viewURL)
        let viewVals = [ViewNameKey: "Parent", ViewURLKey: viewURL, ViewJenkinsInstanceKey: jenkinsInstance!]
        let view1 = View.createViewWithValues(viewVals, inManagedObjectContext: context)
        saveContext()
        
        let jobvals1 = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/Job1"]
        let jobvals2 = [JobNameKey: "Job2", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/Job2"]
        let jobvals3 = [JobNameKey: "Job3", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/Job3"]
        let jobs1 = [jobvals1,jobvals2,jobvals3]
        
        let childViewVals1 = [ViewNameKey: "child1", ViewURLKey: "http://www.google.com/jenkins/view/child1"]
        let childViewVals2 = [ViewNameKey: "child2", ViewURLKey: "http://www.google.com/jenkins/view/child2"]
        let childViews = [childViewVals1,childViewVals2]
        
        let userInfo = [ViewNameKey: "Parent", ViewURLKey: viewURL, ViewDescriptionKey: "this is the parent view", ViewJenkinsInstanceKey: jenkinsInstance!, ViewJobsKey: jobs1, ViewViewsKey: childViews, RequestedObjectKey: view1]
        let notification = NSNotification(name: ViewDetailResponseReceivedNotification, object: self, userInfo: userInfo)
        
        mgr.viewDetailResponseReceived(notification)
        
        waitForExpectationsWithTimeout(2, handler: { error in
            
        })
    }
    
    func testViewDetailRequestServerNotFound() {
        let requestFailureExpectation = expectationWithDescription("View1 will be deleted")
        let viewDeletedNotificationExpectionat = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let deletedObjects: NSSet? = notification.userInfo![NSDeletedObjectsKey] as NSSet?
            if deletedObjects != nil {
                for obj in deletedObjects! {
                    if let view = obj as? View {
                        if view.url == "http://www.yourmomdoesnotexist.com/view/View1/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let viewURL = "http://www.yourmomdoesnotexist.com/view/View1/"
        let url = NSURL(string: viewURL)
        let viewVals = [ViewNameKey: "View1", ViewURLKey: viewURL, ViewJenkinsInstanceKey: jenkinsInstance!]
        let view1 = View.createViewWithValues(viewVals, inManagedObjectContext: context)
        
        saveContext()
        
        let request = NSURLRequest(URL: url!)
        let operation = AFHTTPRequestOperation(request: request)
        let serializer = AFJSONResponseSerializer()
        operation.responseSerializer = serializer
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("View", inManagedObjectContext: context!)
        fetchreq.includesPropertyValues = false
        let views = context?.executeFetchRequest(fetchreq, error: nil)
        XCTAssertEqual(views!.count, 1, "views count is wrong. should  be 1 got: \(views!.count) instead")
        
        
        operation.setCompletionBlockWithSuccess(
            { operation, response in
                println("jenkins request received")
                abort()
            },
            failure: { operation, error in
                var userInfo: [NSObject : AnyObject] = [RequestErrorKey: error]
                if let response = operation.response {
                    userInfo[StatusCodeKey] = response.statusCode
                }
                userInfo[RequestedObjectKey] = view1
                let notification = NSNotification(name: ViewDetailRequestFailedNotification, object: self, userInfo: userInfo)
                self.mgr.viewDetailRequestFailed(notification)
                requestFailureExpectation.fulfill()
        })
        
        operation.start()
        
        waitForExpectationsWithTimeout(10, handler: { error in
            
        })
    }
    
    func testViewDetailRequestFailed() {
        let requestFailureExpectation = expectationWithDescription("View1 will be deleted")
        let viewDeletedNotificationExpectionat = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let deletedObjects: NSSet? = notification.userInfo![NSDeletedObjectsKey] as NSSet?
            if deletedObjects != nil {
                for obj in deletedObjects! {
                    if let view = obj as? View {
                        if view.url == "http://www.google.com/view/View1/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let viewURL = "http://www.google.com/view/View1/"
        let url = NSURL(string: viewURL)
        let viewVals = [ViewNameKey: "View1", ViewURLKey: viewURL, ViewJenkinsInstanceKey: jenkinsInstance!]
        let view1 = View.createViewWithValues(viewVals, inManagedObjectContext: context)
        saveContext()
        
        let request = NSURLRequest(URL: url!)
        let operation = AFHTTPRequestOperation(request: request)
        let serializer = AFJSONResponseSerializer()
        operation.responseSerializer = serializer
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("View", inManagedObjectContext: context!)
        fetchreq.includesPropertyValues = false
        let views = context?.executeFetchRequest(fetchreq, error: nil)
        XCTAssertEqual(views!.count, 1, "views count is wrong. should  be 1 got: \(views!.count) instead")
        
        
        operation.setCompletionBlockWithSuccess(
            { operation, response in
                println("jenkins request received")
            },
            failure: { operation, error in
                var userInfo: [NSObject : AnyObject] = [RequestErrorKey: error]
                if let response = operation.response {
                    userInfo[StatusCodeKey] = response.statusCode
                }
                userInfo[RequestedObjectKey] = view1
                let notification = NSNotification(name: ViewDetailRequestFailedNotification, object: self, userInfo: userInfo)
                self.mgr.viewDetailRequestFailed(notification)
                requestFailureExpectation.fulfill()
        })
        
        operation.start()
        
        waitForExpectationsWithTimeout(10, handler: { error in
            
        })
    }
    
    func testViewLastSyncResultOK() {
        let viewUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let view1 = obj as? View {
                        if view1.lastSyncResult == "200: OK" && view1.url == "https://snowman:8443/jenkins/view/All/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let viewURLStr = "https://snowman:8443/jenkins/view/All/"
        let viewURL = NSURL(string: viewURLStr)
        let primaryView = [ViewNameKey: "Nunya", ViewURLKey: "http://jenkins:8080/"]
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "http://snowman:8080/jenkins/", JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "jenkinsadmin", JenkinsInstancePrimaryViewKey: primaryView]
        let jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1, inManagedObjectContext: self.context)
        jinstance1.password = "changeme"
        jinstance1.allowInvalidSSLCertificate = true;
        let childViewVals1 = [ViewNameKey: "All", ViewURLKey: viewURLStr, ViewJenkinsInstanceKey: jinstance1]
        let view = View.createViewWithValues(childViewVals1, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForView(view)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testViewLastSyncResult401() {
        let viewUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let view = obj as? View {
                        if view.lastSyncResult == "401: unauthorized" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        jenkinsInstance?.username = "user"
        jenkinsInstance?.password = "password1"
        let viewURLStr = "http://jenkins:8080/view/GrandParent/"
        let viewURL = NSURL(string: viewURLStr)
        let childViewVals1 = [ViewNameKey: "GrandParent", ViewURLKey: viewURLStr, ViewJenkinsInstanceKey: jenkinsInstance!]
        let view = View.createViewWithValues(childViewVals1, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForView(view)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testViewLastSyncResult403() {
        let viewUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let view = obj as? View {
                        if view.lastSyncResult == "403: forbidden" && view.url == "http://jenkins:8080/view/GrandParent/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        jenkinsInstance?.username = "user"
        jenkinsInstance?.password = "password"
        let viewURLStr = "http://jenkins:8080/view/GrandParent/"
        let viewURL = NSURL(string: viewURLStr)
        let childViewVals1 = [ViewNameKey: "GrandParent", ViewURLKey: viewURLStr, ViewJenkinsInstanceKey: jenkinsInstance!]
        let view = View.createViewWithValues(childViewVals1, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForView(view)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testBuildDetailResponseReceived() {
        let buildUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let build = obj as? Build {
                        if build.lastSyncResult == "200: OK" && build.url == "http://jenkins:8080/TestJob/1/" && build.build_description == "A build" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let initBuildVals = [BuildNumberKey: 1, BuildURLKey:"http://jenkins:8080/TestJob/1/"]
        let build = Build.createBuildWithValues(initBuildVals, inManagedObjectContext: self.context)
        saveContext()
        
        let causes = [[BuildCausesShortDescriptionKey: "because",BuildCausesUserIDKey: "10",BuildCausesUserNameKey: "kbeal"]]
        let actions = [[BuildCausesKey: causes]]
        let changeSetItems = ["one","two"]
        let changeSet = [BuildChangeSetItemsKey: changeSetItems, BuildChangeSetKindKey: "idk"]
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://jenkins:8080/job/TestJob", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        let userInfo = [BuildActionsKey: actions, BuildBuildingKey: true, BuildDescriptionKey: "A build", BuildDurationKey: 120000, BuildEstimatedDurationKey: 120001, BuildFullDisplayNameKey: "TestJob #1", BuildIDKey: "2015-01-07_21-57-03", BuildKeepLogKey: false, BuildNumberKey: 1, BuildResultKey: "SUCCESS", BuildTimestampKey:1420685823231, BuildURLKey: "http://jenkins:8080/TestJob/1/", BuildChangeSetKey: changeSet, BuildJobKey: job, RequestedObjectKey: build]
        let notification = NSNotification(name: BuildDetailResponseReceivedNotification, object: self, userInfo: userInfo)
        
        mgr.buildDetailResponseReceived(notification)
        
        waitForExpectationsWithTimeout(2, handler: { error in
            
        })
    }
    
    func testBuildDetailRequestFailed() {
        let requestFailureExpectation = expectationWithDescription("Build will be deleted")
        let buildDeletedNotificationExpection = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let deletedObjects: NSSet? = notification.userInfo![NSDeletedObjectsKey] as NSSet?
            if deletedObjects != nil {
                for obj in deletedObjects! {
                    if let build = obj as? Build {
                        if build.url == "http://www.google.com/TestJob/1/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/TestJob/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        let buildURL = "http://www.google.com/TestJob/1/"
        let url = NSURL(string: buildURL)

        let buildVals = [BuildJobKey: job, BuildURLKey: buildURL, BuildNumberKey: 1]
        let build1 = Build.createBuildWithValues(buildVals, inManagedObjectContext: self.context)
        saveContext()
        
        let request = NSURLRequest(URL: url!)
        let operation = AFHTTPRequestOperation(request: request)
        let serializer = AFJSONResponseSerializer()
        operation.responseSerializer = serializer
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("Build", inManagedObjectContext: context!)
        fetchreq.includesPropertyValues = false
        let builds = context?.executeFetchRequest(fetchreq, error: nil)
        XCTAssertEqual(builds!.count, 1, "builds count is wrong. should  be 1 got: \(builds!.count) instead")
        
        
        operation.setCompletionBlockWithSuccess(
            { operation, response in
                println("jenkins request received")
                abort()
            },
            failure: { operation, error in
                var userInfo: [NSObject : AnyObject] = [RequestErrorKey: error]
                if let response = operation.response {
                    userInfo[StatusCodeKey] = response.statusCode
                }
                userInfo[RequestedObjectKey] = build1
                let notification = NSNotification(name: BuildDetailRequestFailedNotification, object: self, userInfo: userInfo)
                self.mgr.buildDetailRequestFailed(notification)
                requestFailureExpectation.fulfill()
        })
        
        operation.start()
        
        waitForExpectationsWithTimeout(5, handler: { error in
            
        })
    }
    
    func testBuildShouldSync() {
        let now = (NSDate().timeIntervalSince1970) * 1000
        let fourSecondsAgo = now - 4000000
        let tenSecondsAgo = now - 10000000
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://jenkins:8080/job/TestJob", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        // should only sync
        // if building and duration (currentTime - build.timestamp) is within 80% of estimatedDuration
        let buildVals1 = [BuildBuildingKey: false, BuildEstimatedDurationKey: 120000, BuildTimestampKey: now, BuildJobKey: job, BuildNumberKey: 100, BuildURLKey: "http://jenkins:8080/job/TestJob/100"]
        let buildVals2 = [BuildBuildingKey: true, BuildEstimatedDurationKey: 120000, BuildTimestampKey: now, BuildJobKey: job, BuildNumberKey: 101, BuildURLKey: "http://jenkins:8080/job/TestJob/101"]
        let buildVals3 = [BuildBuildingKey: true, BuildEstimatedDurationKey: 5000, BuildTimestampKey: fourSecondsAgo, BuildJobKey: job, BuildNumberKey: 102, BuildURLKey: "http://jenkins:8080/job/TestJob/102"]
        let buildVals4 = [BuildBuildingKey: true, BuildEstimatedDurationKey: 5000, BuildTimestampKey: tenSecondsAgo, BuildJobKey: job, BuildNumberKey: 103, BuildURLKey: "http://jenkins:8080/job/TestJob/103"]
        let buildVals5 = [BuildJobKey: job, BuildNumberKey: 103, BuildURLKey: "http://jenkins:8080/job/TestJob/103"]
        
        let build1 = Build.createBuildWithValues(buildVals1, inManagedObjectContext: context)
        let build2 = Build.createBuildWithValues(buildVals2, inManagedObjectContext: context)
        let build3 = Build.createBuildWithValues(buildVals3, inManagedObjectContext: context)
        let build4 = Build.createBuildWithValues(buildVals4, inManagedObjectContext: context)
        let build5 = Build.createBuildWithValues(buildVals5, inManagedObjectContext: context)
        
        XCTAssertFalse(build1.shouldSync(), "build1 should not sync because its building value is false")
        XCTAssertFalse(build2.shouldSync(), "build2 should not sync because it was just kicked off")
        XCTAssertTrue(build3.shouldSync(), "build3 should sync because it's close to completion time")
        XCTAssertTrue(build4.shouldSync(), "build4 should sync because it's after estimated completion time and it's still building")
        XCTAssertTrue(build5.shouldSync(), "build5 should sync because it hasn't synced yet")
    }
    
    func testBuildLastSyncResultOK() {
        let buildUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let build = obj as? Build {
                        if build.lastSyncResult == "200: OK" && build.url == "https://snowman:8443/jenkins/job/Job1/1/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let buildURLStr = "https://snowman:8443/jenkins/job/Job1/1/"
        jenkinsInstance?.username = "jenkinsadmin"
        jenkinsInstance?.password = "changeme"
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job1/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        let buildVals1 = [BuildBuildingKey: false, BuildEstimatedDurationKey: 120000, BuildJobKey: job, BuildNumberKey: 100, BuildURLKey: buildURLStr]
        let build = Build.createBuildWithValues(buildVals1, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForBuild(build)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testBuildLastSyncResult401() {
        let buildUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let build = obj as? Build {
                        if build.lastSyncResult == "401: unauthorized" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        jenkinsInstance?.username = "user"
        jenkinsInstance?.password = "password1"
        let buildURLStr = "http://jenkins:8080/job/Job3/1/"
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://jenkins:8080/job/Job3/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        let buildVals1 = [BuildBuildingKey: false, BuildEstimatedDurationKey: 120000, BuildJobKey: job, BuildNumberKey: 100, BuildURLKey: buildURLStr]
        let build = Build.createBuildWithValues(buildVals1, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForBuild(build)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testBuildLastSyncResult403() {
        let buildUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let build = obj as? Build {
                        if build.lastSyncResult == "403: forbidden" && build.url == "http://jenkins:8080/job/Job3/1/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        jenkinsInstance?.username = "user"
        jenkinsInstance?.password = "password"
        let buildURLStr = "http://jenkins:8080/job/Job3/1/"
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://jenkins:8080/job/Job3/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        let buildVals1 = [BuildBuildingKey: false, BuildEstimatedDurationKey: 120000, BuildJobKey: job, BuildNumberKey: 100, BuildURLKey: buildURLStr]
        let build = Build.createBuildWithValues(buildVals1, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForBuild(build)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testActiveConfigurationResponseReceived() {
        let acUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ac = obj as? ActiveConfiguration {
                        if ac.lastSyncResult == "200: OK" && ac.url == "http://www.google.com/job/Job1/config=1/" && ac.activeConfiguration_description == "Job1, config=1 Description" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })

        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://jenkins:8080/job/TestJob", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        let initACVals = [ActiveConfigurationNameKey:"config=1",ActiveConfigurationURLKey:"http://www.google.com/job/Job1/config=1/",ActiveConfigurationColorKey:"blue",ActiveConfigurationJobKey: job]
        let ac = ActiveConfiguration.createActiveConfigurationWithValues(initACVals, inManagedObjectContext: context)
        saveContext()
        
        let build1Obj = ["number": 1, "url": "http://www.google.com/job/Job1/config=1/1"]
        let healthReport = ["iconUrl": "health-80plus.png"]

        
        let userInfo = [ActiveConfigurationNameKey: "config=1", ActiveConfigurationColorKey: "blue", ActiveConfigurationURLKey: "http://www.google.com/job/Job1/config=1/", ActiveConfigurationBuildableKey: true, ActiveConfigurationConcurrentBuildKey: false, ActiveConfigurationDisplayNameKey: "Job1", ActiveConfigurationFirstBuildKey: build1Obj, ActiveConfigurationLastBuildKey: build1Obj, ActiveConfigurationLastCompletedBuildKey: build1Obj, ActiveConfigurationLastFailedBuildKey: build1Obj, ActiveConfigurationLastStableBuildKey: build1Obj, ActiveConfigurationLastSuccessfulBuildKey: build1Obj,ActiveConfigurationLastUnstableBuildKey: build1Obj, ActiveConfigurationLastUnsucessfulBuildKey: build1Obj, ActiveConfigurationNextBuildNumberKey: 2, ActiveConfigurationInQueueKey: false, ActiveConfigurationDescriptionKey: "Job1, config=1 Description", ActiveConfigurationKeepDependenciesKey: false,  ActiveConfigurationHealthReportKey: healthReport, ActiveConfigurationJobKey: job, ActiveConfigurationLastSyncKey: NSDate(),RequestedObjectKey:ac]
        let notification = NSNotification(name: ActiveConfigurationDetailResponseReceivedNotification, object: self, userInfo: userInfo)
        
        mgr.activeConfigurationDetailResponseReceived(notification)
        waitForExpectationsWithTimeout(2, handler: { error in
            
        })
    }
    
    func testActiveConfigurationDetailRequestFailed() {
        let requestFailureExpectation = expectationWithDescription("Active Config will be deleted")
        let activeConfigDeletedNotificationExpection = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let deletedObjects: NSSet? = notification.userInfo![NSDeletedObjectsKey] as NSSet?
            if deletedObjects != nil {
                for obj in deletedObjects! {
                    if let ac = obj as? ActiveConfiguration {
                        if ac.url == "http://www.google.com/TestJob/config=1/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/TestJob/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)

        let acURL = "http://www.google.com/TestJob/config=1/"
        let url = NSURL(string: acURL)
        
        let acVals = [ActiveConfigurationNameKey: "config=1", ActiveConfigurationURLKey: acURL, ActiveConfigurationJobKey: job, ActiveConfigurationColorKey: "blue"]
        let ac = ActiveConfiguration.createActiveConfigurationWithValues(acVals, inManagedObjectContext: self.context)
        saveContext()
        
        let request = NSURLRequest(URL: url!)
        let operation = AFHTTPRequestOperation(request: request)
        let serializer = AFJSONResponseSerializer()
        operation.responseSerializer = serializer
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("ActiveConfiguration", inManagedObjectContext: context!)
        fetchreq.includesPropertyValues = false
        let acs = context?.executeFetchRequest(fetchreq, error: nil)
        XCTAssertEqual(acs!.count, 1, "acs count is wrong. should  be 1 got: \(acs!.count) instead")
        
        
        operation.setCompletionBlockWithSuccess(
            { operation, response in
                println("jenkins request received")
                abort()
            },
            failure: { operation, error in
                var userInfo: [NSObject : AnyObject] = [RequestErrorKey: error]
                if let response = operation.response {
                    userInfo[StatusCodeKey] = response.statusCode
                }
                userInfo[RequestedObjectKey] = ac
                let notification = NSNotification(name: ActiveConfigurationDetailRequestFailedNotification, object: self, userInfo: userInfo)
                self.mgr.activeConfigurationDetailRequestFailed(notification)
                requestFailureExpectation.fulfill()
        })
        
        operation.start()
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testActiveConfigurationLastSyncResultOK() {
        let acUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ac = obj as? ActiveConfiguration {
                        if ac.lastSyncResult == "200: OK" && ac.url == "https://snowman:8443/jenkins/job/Job2/config=10/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        jenkinsInstance?.username = "jenkinsadmin"
        jenkinsInstance?.password = "changeme"
        
        let jobVals1 = [JobNameKey: "Job2", JobColorKey: "blue", JobURLKey: "https://snowman:8443/jenkins/job/Job2/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        let acURL = "https://snowman:8443/jenkins/job/Job2/config=10/"
        let url = NSURL(string: acURL)
        
        let acVals = [ActiveConfigurationNameKey: "config=10", ActiveConfigurationURLKey: acURL, ActiveConfigurationJobKey: job, ActiveConfigurationColorKey: "blue"]
        let ac = ActiveConfiguration.createActiveConfigurationWithValues(acVals, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForActiveConfiguration(ac)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testActiveConfigurationLastSyncResult401() {
        let acUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ac = obj as? ActiveConfiguration {
                        if ac.lastSyncResult == "401: unauthorized" && ac.url == "http://jenkins:8080/job/Job6/config1=10,config2=test/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        jenkinsInstance?.username = "user"
        jenkinsInstance?.password = "password1"
        let jobVals1 = [JobNameKey: "Job6", JobColorKey: "blue", JobURLKey: "http://jenkins:8080/job/Job6/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        let acURL = "http://jenkins:8080/job/Job6/config1=10,config2=test/"
        let url = NSURL(string: acURL)
        
        let acVals = [ActiveConfigurationNameKey: "config1=10,config2=test", ActiveConfigurationURLKey: acURL, ActiveConfigurationJobKey: job, ActiveConfigurationColorKey: "blue"]
        let ac = ActiveConfiguration.createActiveConfigurationWithValues(acVals, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForActiveConfiguration(ac)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testActiveConfigurationLastSyncResult403() {
        let acUpdatedNotificationExpectation = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ac = obj as? ActiveConfiguration {
                        if ac.lastSyncResult == "403: forbidden" && ac.url == "http://jenkins:8080/job/Job6/config1=10,config2=test/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        jenkinsInstance?.username = "user"
        jenkinsInstance?.password = "password"
        let jobVals1 = [JobNameKey: "Job6", JobColorKey: "blue", JobURLKey: "http://jenkins:8080/job/Job6/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        let acURL = "http://jenkins:8080/job/Job6/config1=10,config2=test/"
        let url = NSURL(string: acURL)
        
        let acVals = [ActiveConfigurationNameKey: "config1=10,config2=test", ActiveConfigurationURLKey: acURL, ActiveConfigurationJobKey: job, ActiveConfigurationColorKey: "blue"]
        let ac = ActiveConfiguration.createActiveConfigurationWithValues(acVals, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForActiveConfiguration(ac)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
}
