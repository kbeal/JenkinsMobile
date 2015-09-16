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
    let datamgr = DataManager.sharedInstance
    var context: NSManagedObjectContext?
    var jenkinsInstance: JenkinsInstance?
    
    override func setUp() {
        super.setUp()
        
        context = self.datamgr.mainMOC
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://localhost:8080/"]
        let jenkinsInstanceValues = [JenkinsInstanceNameKey: "TestInstance", JenkinsInstanceURLKey: "http://localhost:8080", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "admin", JenkinsInstancePrimaryViewKey: primaryView]
        
        context?.performBlockAndWait({self.jenkinsInstance = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues as [NSObject : AnyObject], inManagedObjectContext: self.context)})
        self.jenkinsInstance?.password = "password"
        self.jenkinsInstance?.allowInvalidSSLCertificate = true
        
        saveContext()
    }
    
    override func tearDown() {
        saveContext()
    }
    
    func saveContext () {
        datamgr.saveContext(datamgr.mainMOC)
        datamgr.masterMOC.performBlockAndWait({
            self.datamgr.saveContext(self.datamgr.masterMOC)
        })
    }
    
    func testSyncView() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
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
        
        let viewURL = "http://localhost:8080/view/GrandParent/"
        let viewVals = [ViewNameKey: "GrandParent", ViewURLKey: viewURL, ViewJenkinsInstanceKey: jenkinsInstance!]
        let view1 = View.createViewWithValues(viewVals, inManagedObjectContext: context)
        saveContext()
        
        self.mgr.syncView(view1)
        
        // wait for expectations
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testSyncJob() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let job = obj as? Job {
                        if job.url == "http://localhost:8080/job/Job3/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let jobVals1 = [JobNameKey: "Job3", JobColorKey: "blue", JobURLKey: "http://localhost:8080/job/Job3/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        saveContext()
        self.mgr.syncJob(job)
        
        // wait for expectations
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testSyncBuild() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
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
        
        let buildURL = "http://localhost:8080/job/Job3/1/"
        
        let buildVals = [BuildJobKey: job, BuildURLKey: buildURL, BuildNumberKey: 1]
        let build1 = Build.createBuildWithValues(buildVals, inManagedObjectContext: self.context)
        saveContext()
        
        self.mgr.syncBuild(build1)
        
        // wait for expectations
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testSyncActiveConfiguration() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
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
        
        let jobvals = [JobNameKey: "Job6", JobColorKey: "blue", JobURLKey: "http://localhost:8080/job/Job2/", JobLastSyncKey: NSDate(), JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobvals, inManagedObjectContext: context)
        
        let ac1 = [ActiveConfigurationColorKey:"blue",ActiveConfigurationNameKey:"config=1",ActiveConfigurationJobKey:job,ActiveConfigurationURLKey:"http://localhost:8080/job/Job2/config1=10,config2=test/"]
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
        
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://jenkins:8080/"]
        let values = [JenkinsInstanceNameKey: "QA Ubuntu", JenkinsInstanceURLKey: "https://jenkins.qa.ubuntu.com/", JenkinsInstanceEnabledKey: true, JenkinsInstancePrimaryViewKey: primaryView]

        JenkinsInstance.findOrCreateJenkinsInstanceWithValues(values as [NSObject : AnyObject], inManagedObjectContext: context!)
        saveContext()
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("JenkinsInstance", inManagedObjectContext: context!)
        fetchreq.predicate = NSPredicate(format: "name = %@", "QA Ubuntu")
        fetchreq.includesPropertyValues = false
        
        do {
            let jenkinss = try context?.executeFetchRequest(fetchreq)
            let ji = jenkinss![0] as! JenkinsInstance
            XCTAssertEqual(ji.name, "QA Ubuntu", "jenkins instance name is wrong. should be QA Ubuntu, got: \(ji.name) instead")
            XCTAssertEqual(jenkinss!.count, 1, "jenkinss count is wrong. Should be 1 got: \(jenkinss!.count) instead")
        } catch {
            abort()
        }
    }

    func testPerformanceJenkinsInstanceSaveValues() {
        let jobcount = 100
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.datamgr.masterMOC, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        if ji.url == "http://localhost:8080" && ji.rel_Jobs.count == jobcount {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        var jobs: [Dictionary<String, String>] = []
        for _ in 1...jobcount {
            let uuid = NSUUID().UUIDString
            jobs.append([JobNameKey: uuid, JobColorKey: "blue", JobURLKey: "http://www.google.com"])
        }

        let newvalues: [NSObject: AnyObject] = [JenkinsInstanceNameKey: self.jenkinsInstance!.name, JenkinsInstanceURLKey: self.jenkinsInstance!.url, JenkinsInstanceJobsKey: jobs]
        

        self.measureBlock({
            self.jenkinsInstance!.setValues(newvalues)
        })
        
        waitForExpectationsWithTimeout(20, handler: { error in
            
        })
        //XCTAssertEqual(ji.rel_Jobs.count, 20000, "jenkins instance's jobs count is wrong")
    }

    func testJenkinsInstanceUnauthenticated() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        if ji.url == "http://localhost:8080/" && ji.enabled.boolValue && !ji.authenticated.boolValue {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "http://localhost:8080/", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "admin", JenkinsInstanceAuthenticatedKey: true]
        let jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1 as [NSObject : AnyObject], inManagedObjectContext: self.context)
        jinstance1.allowInvalidSSLCertificate = true
        jinstance1.shouldAuthenticate = true
        jinstance1.password = "password1"
        saveContext()
        
        XCTAssert(jinstance1.enabled.boolValue, "jenkins instance should be enabled")
        XCTAssert(jinstance1.authenticated.boolValue, "jenkins instance should be authenticated")
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJenkinsInstance(jinstance1)
        
        waitForExpectationsWithTimeout(2, handler: { error in
            
        })
    }
    
    func testJenkinsInstanceReauthenticated() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        if ji.url == "http://localhost:8080/" && ji.enabled.boolValue && ji.authenticated.boolValue {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "http://localhost:8080/", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "admin"]
        let jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1 as [NSObject : AnyObject], inManagedObjectContext: self.context)
        jinstance1.allowInvalidSSLCertificate = true
        jinstance1.password = "password"
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
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        if ji.lastSyncResult == "200: OK" && ji.url == "http://localhost:8080/" {
                            expectationFulfilled=true
                        } else {
                            print(ji.url + ": " + ji.lastSyncResult)
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let primaryView = [ViewNameKey: "Test", ViewURLKey: "http://localhost:8080/"]
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "http://localhost:8080/", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "admin", JenkinsInstancePrimaryViewKey: primaryView]
        let jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1 as [NSObject : AnyObject], inManagedObjectContext: self.context)
        jinstance1.password = "password"
        jinstance1.allowInvalidSSLCertificate = true;
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJenkinsInstance(jinstance1)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testJenkinsInstanceLastSyncResult401() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        if ji.lastSyncResult == "401: unauthorized" && ji.url == "http://localhost:8080/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://jenkins:8080/"]
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "http://localhost:8080/", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "user", JenkinsInstancePrimaryViewKey: primaryView]
        let jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1 as [NSObject : AnyObject], inManagedObjectContext: self.context)
        jinstance1.password = "password1"
        jinstance1.allowInvalidSSLCertificate = true;
        jinstance1.shouldAuthenticate = true
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJenkinsInstance(jinstance1)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testJenkinsInstanceLastSyncResult403() {
        // this jenkins instance must not have anonymous access turned on
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        if ji.lastSyncResult == "403: forbidden" && ji.url == "http://localhost:8080/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://localhost:8080/"]
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "http://localhost:8080/", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "user", JenkinsInstancePrimaryViewKey: primaryView, JenkinsInstanceShouldAuthenticateKey: true]
        let jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1 as [NSObject : AnyObject], inManagedObjectContext: self.context)
        jinstance1.password = "password"
        jinstance1.allowInvalidSSLCertificate = true;
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJenkinsInstance(jinstance1)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }

    func testJobLastSyncResultOK() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let job1 = obj as? Job {
                        if job1.lastSyncResult == "200: OK" && job1.url == "http://localhost:8080/job/Job1/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let jobURLStr = "http://localhost:8080/job/Job1/"
        jenkinsInstance?.username = "admin"
        jenkinsInstance?.password = "password"
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: jobURLStr, JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJobWithValues(job1vals, inManagedObjectContext: context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJob(job1)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testJobLastSyncResult401() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
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
        jenkinsInstance?.shouldAuthenticate = true
        let jobURLStr = "http://localhost:8080/job/Job3/"
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: jobURLStr, JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJobWithValues(job1vals, inManagedObjectContext: context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJob(job1)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testJobLastSyncResult403() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
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
        jenkinsInstance?.shouldAuthenticate = true
        let jobURLStr = "http://localhost:8080/job/Job3/"
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: jobURLStr, JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJobWithValues(job1vals, inManagedObjectContext: context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForJob(job1)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
  
    func testViewLastSyncResultOK() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let view1 = obj as? View {
                        if view1.lastSyncResult == "200: OK" && view1.url == "http://localhost:8080/view/GrandParent/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let viewURLStr = "http://localhost:8080/view/GrandParent/"
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "http://localhost:8080/", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "admin"]
        let jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1 as [NSObject : AnyObject], inManagedObjectContext: self.context)
        jinstance1.password = "password"
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
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
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
        jenkinsInstance?.shouldAuthenticate = true
        let viewURLStr = "http://localhost:8080/view/GrandParent/"
        let childViewVals1 = [ViewNameKey: "GrandParent", ViewURLKey: viewURLStr, ViewJenkinsInstanceKey: jenkinsInstance!]
        let view = View.createViewWithValues(childViewVals1, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForView(view)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testViewLastSyncResult403() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let view = obj as? View {
                        if view.lastSyncResult == "403: forbidden" && view.url == "http://localhost:8080/view/GrandParent/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        jenkinsInstance?.username = "user"
        jenkinsInstance?.password = "password"
        jenkinsInstance?.shouldAuthenticate = true
        let viewURLStr = "http://localhost:8080/view/GrandParent/"
        let childViewVals1 = [ViewNameKey: "GrandParent", ViewURLKey: viewURLStr, ViewJenkinsInstanceKey: jenkinsInstance!]
        let view = View.createViewWithValues(childViewVals1, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForView(view)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
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
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let build = obj as? Build {
                        if build.lastSyncResult == "200: OK" && build.url == "http://localhost:8080/job/Job1/1/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let buildURLStr = "http://localhost:8080/job/Job1/1/"
        jenkinsInstance?.username = "admin"
        jenkinsInstance?.password = "password"
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
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
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
        jenkinsInstance?.shouldAuthenticate = true
        let buildURLStr = "http://localhost:8080/job/Job3/1/"
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://localhost:8080/job/Job3/", JobJenkinsInstanceKey: jenkinsInstance!]
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
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let build = obj as? Build {
                        if build.lastSyncResult == "403: forbidden" && build.url == "http://localhost:8080/job/Job3/1/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        jenkinsInstance?.username = "user"
        jenkinsInstance?.password = "password"
        let buildURLStr = "http://localhost:8080/job/Job3/1/"
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://localhost:8080/job/Job3/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        let buildVals1 = [BuildBuildingKey: false, BuildEstimatedDurationKey: 120000, BuildJobKey: job, BuildNumberKey: 100, BuildURLKey: buildURLStr]
        let build = Build.createBuildWithValues(buildVals1, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForBuild(build)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
   
    func testActiveConfigurationLastSyncResultOK() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ac = obj as? ActiveConfiguration {
                        if ac.lastSyncResult == "200: OK" && ac.url == "http://localhost:8080/job/Job2/config1=10,config2=test/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let jobVals1 = [JobNameKey: "Job2", JobColorKey: "blue", JobURLKey: "http://localhost:8080/job/Job2/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        let acURL = "http://localhost:8080/job/Job2/config1=10,config2=test/"
        
        let acVals = [ActiveConfigurationNameKey: "config1=10,config2=test", ActiveConfigurationURLKey: acURL, ActiveConfigurationJobKey: job, ActiveConfigurationColorKey: "blue"]
        let ac = ActiveConfiguration.createActiveConfigurationWithValues(acVals, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForActiveConfiguration(ac)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testActiveConfigurationLastSyncResult401() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ac = obj as? ActiveConfiguration {
                        if ac.lastSyncResult == "401: unauthorized" && ac.url == "http://localhost:8080/job/Job2/config1=10,config2=test/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        jenkinsInstance?.username = "user"
        jenkinsInstance?.password = "password1"
        jenkinsInstance?.shouldAuthenticate = true
        let jobVals1 = [JobNameKey: "Job6", JobColorKey: "blue", JobURLKey: "http://localhost:8080/job/Job2/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        let acURL = "http://localhost:8080/job/Job2/config1=10,config2=test/"
        
        let acVals = [ActiveConfigurationNameKey: "config1=10,config2=test", ActiveConfigurationURLKey: acURL, ActiveConfigurationJobKey: job, ActiveConfigurationColorKey: "blue"]
        let ac = ActiveConfiguration.createActiveConfigurationWithValues(acVals, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForActiveConfiguration(ac)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
    
    func testActiveConfigurationLastSyncResult403() {
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ac = obj as? ActiveConfiguration {
                        if ac.lastSyncResult == "403: forbidden" && ac.url == "http://localhost:8080/job/Job2/config1=10,config2=test/" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        jenkinsInstance?.username = "user"
        jenkinsInstance?.password = "password"
        let jobVals1 = [JobNameKey: "Job2", JobColorKey: "blue", JobURLKey: "http://localhost:8080/job/Job2/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        let acURL = "http://localhost:8080/job/Job2/config1=10,config2=test/"
        
        let acVals = [ActiveConfigurationNameKey: "config1=10,config2=test", ActiveConfigurationURLKey: acURL, ActiveConfigurationJobKey: job, ActiveConfigurationColorKey: "blue"]
        let ac = ActiveConfiguration.createActiveConfigurationWithValues(acVals, inManagedObjectContext: self.context)
        saveContext()
        
        let requestHandler: KDBJenkinsRequestHandler = KDBJenkinsRequestHandler()
        requestHandler.importDetailsForActiveConfiguration(ac)
        
        waitForExpectationsWithTimeout(3, handler: { error in
            
        })
    }
}
