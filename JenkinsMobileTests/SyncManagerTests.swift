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
        
        let jenkinsInstanceValues = [JenkinsInstanceNameKey: "TestInstance", JenkinsInstanceURLKey: "http://jenkins:8080", JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true]
        
        context?.performBlockAndWait({self.jenkinsInstance = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues, inManagedObjectContext: self.context)})
        
        mgr.currentJenkinsInstanceURL = NSURL(string: jenkinsInstance!.url)
        
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
        } else {
            println("Successfully saved test managed object context")
        }
    }
    
    func testSharedInstance() {
        XCTAssertNotNil(mgr, "shared instance is nil")
    }
    
    func testJobShouldSync() {
        let jobvals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com", JobLastSyncKey: NSDate(), JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobvals, inManagedObjectContext: context)
        
        XCTAssertFalse(job.shouldSync(), "shouldsync should be false")
    }
    
    func testTwoJobsTwoJenkins() {
        let requestFailureExpectation = expectationWithDescription("notificaiton will be sent and TestJob from jenkins2:8080 is deleted")
        // create a jenkins instance
        var jinstance1: JenkinsInstance?
        let jenkinsInstanceValues1 = [JenkinsInstanceNameKey: "TestInstance1", JenkinsInstanceURLKey: "http://jenkins1:8080", JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true]
        context?.performBlockAndWait({jinstance1 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues1, inManagedObjectContext: self.context)})
        
        // create a job in the first instance
        let job1vals = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://jenkins1:8080/job/TestJob", JobJenkinsInstanceKey: jinstance1!]
        let job1 = Job.createJobWithValues(job1vals, inManagedObjectContext: context)
        
        // create a second jenkins instance
        var jinstance2: JenkinsInstance?
        let jenkinsInstanceValues2 = [JenkinsInstanceNameKey: "TestInstance2", JenkinsInstanceURLKey: "http://jenkins2:8080", JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true]
        context?.performBlockAndWait({jinstance2 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues2, inManagedObjectContext: self.context)})
        
        // create a job in the second jenkins instance
        let job2vals = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://jenkins2:8080/job/TestJob", JobJenkinsInstanceKey: jinstance2!]
        let job2 = Job.createJobWithValues(job2vals, inManagedObjectContext: context)
        
        saveContext()
        
        let job2URL = "http://jenkins2:8080/job/TestJob/api/json"
        let url = NSURL(string: job2URL)
        let request = NSURLRequest(URL: url!)
        let operation = AFHTTPRequestOperation(request: request)
        let serializer = AFJSONResponseSerializer()
        operation.responseSerializer = serializer
        
        var fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("Job", inManagedObjectContext: context!)
        let jobs = context?.executeFetchRequest(fetchreq, error: nil)
        XCTAssertEqual(jobs!.count, 2, "jobs count is wrong. should  be 2 got: \(jobs!.count) instead")
        
        // send a request to the job in jenkins instance 2
        operation.setCompletionBlockWithSuccess(
            { operation, response in
                // if it succeeds something went wrong
                // request to jenkins2:8080 should fail
                abort()
            },
            failure: { operation, error in
                // if it fails send notification
                var userInfo: [NSObject : AnyObject] = [RequestErrorKey: error]
                if let response = operation.response {
                    userInfo[StatusCodeKey] = response.statusCode
                }
                userInfo[JobJenkinsInstanceKey] = jinstance2
                let notification = NSNotification(name: JobDetailRequestFailedNotification, object: self, userInfo: userInfo)
                self.mgr.jobDetailRequestFailed(notification)
                
                var predicate = NSPredicate(format: "rel_Job_JenkinsInstance.url == %@", jinstance1!.url)
                fetchreq.predicate = predicate
                // after sending notification, should be one job left in the original jenkins instance
                let jobsafterfail = self.context?.executeFetchRequest(fetchreq, error: nil)
                XCTAssertEqual(jobsafterfail!.count, 1, "jobs count is wrong. should  be 1 got: \(jobsafterfail!.count) instead")
                let job: Job? = jobsafterfail!.first as? Job
                XCTAssertEqual(job!.rel_Job_JenkinsInstance!, jinstance1!, "remaining job should be in original jenkins instance")
                
                predicate = NSPredicate(format: "rel_Job_JenkinsInstance.url == %@", jinstance2!.url)
                fetchreq.predicate = predicate
                // after sending notification, should be one job left in the original jenkins instance
                let jobs2afterfail = self.context?.executeFetchRequest(fetchreq, error: nil)
                
                XCTAssertEqual(jobs2afterfail!.count, 0, "jobs count is wrong. should  be 0 got: \(jobs2afterfail!.count) instead")
                
                requestFailureExpectation.fulfill()
        })
        
        operation.start()
        
        // wait for expectations
        waitForExpectationsWithTimeout(5, handler: { error in
            
        })
        
    }
    
    func testJenkinsInstanceFindOrCreated() {
        let jobObj1 = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com"]
        let jobObj2 = [JobNameKey: "Job2", JobColorKey: "red", JobURLKey: "http://www.yahoo.com"]
        let jobObj3 = [JobNameKey: "Job3", JobColorKey: "green", JobURLKey: "http://www.bing.com"]
        let jobObj4 = [JobNameKey: "Job4", JobColorKey: "grey", JobURLKey: "http://www.amazon.com"]
        let jobs = [jobObj1, jobObj2, jobObj3, jobObj4]
        
        let values = [JenkinsInstanceNameKey: "QA Ubuntu", JenkinsInstanceURLKey: "https://jenkins.qa.ubuntu.com/", JenkinsInstanceJobsKey: jobs, JenkinsInstanceCurrentKey: false, JenkinsInstanceEnabledKey: true]

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
        
        let values = [JenkinsInstanceNameKey: "TestInstance", JenkinsInstanceURLKey: "http://www.google.com/api/json", JenkinsInstanceCurrentKey: false, JenkinsInstanceJobsKey: jobs]
        
        let ji = JenkinsInstance.createJenkinsInstanceWithValues(values, inManagedObjectContext: context)
        
        XCTAssertEqual(ji.rel_Jobs.count, 10000, "jenkins instance's jobs count is wrong")
        
        jobs.removeAll(keepCapacity: true)
        for i in 1...10000 {
            let uuid = NSUUID().UUIDString
            jobs.append([JobNameKey: uuid, JobColorKey: "blue", JobURLKey: "http://www.google.com"])
        }
        
        let newvalues = [JenkinsInstanceNameKey: "TestInstance", JenkinsInstanceURLKey: "http://www.google.com/api/json", JenkinsInstanceCurrentKey: false, JenkinsInstanceJobsKey: jobs]
        
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
        let request = NSURLRequest(URL: NSURL(string: "/404", relativeToURL: url)!)
        let operation = AFHTTPRequestOperation(request: request)
        let serializer = AFJSONResponseSerializer()
        operation.responseSerializer = serializer
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("JenkinsInstance", inManagedObjectContext: context!)
        fetchreq.includesPropertyValues = false
        let jenkinss = context?.executeFetchRequest(fetchreq, error: nil)
        XCTAssertEqual(jenkinss!.count, 1, "jenkinss count is wrong. should  be 1 got: \(jenkinss!.count) instead")
        
        operation.setCompletionBlockWithSuccess(
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
                let notification = NSNotification(name: JenkinsInstanceDetailRequestFailedNotification, object: self, userInfo: userInfo)
                self.mgr.jenkinsInstanceDetailRequestFailed(notification)
                requestFailureExpectation.fulfill()
        })
        
        operation.start()
        
        waitForExpectationsWithTimeout(5, handler: { error in
            
        })
    }
    
    func testJobDetailResponseReceived() {
        let build1Obj = ["number": 1, "url": "http://www.google.com/job/Job1/build/1"]
        let downstreamObj1 = ["name": "Job2", "color": "blue", "url":"http://www.ask.com"]
        let downstreamObj2 = ["name": "Job3", "color": "green", "url":"http://www.yahoo.com"]
        let upstreamObj1 = ["name": "Job4", "color": "red", "url":"http://www.bing.com"]
        let downstreamProjects = [downstreamObj1, downstreamObj2]
        let upstreamProjects = [upstreamObj1]
        let healthReport = ["iconUrl": "health-80plus.png"]
        let jobObj1 = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com", JobJenkinsInstanceKey: jenkinsInstance!]
        let jobObj2 = [JobNameKey: "Job2", JobColorKey: "blue", JobURLKey: "http://www.google.com", JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJobWithValues(jobObj1, inManagedObjectContext: context!)
        let job2 = Job.createJobWithValues(jobObj2, inManagedObjectContext: context!)
        
        let ac1 = [ActiveConfigurationColorKey:"blue",ActiveConfigurationNameKey:"config=1",ActiveConfigurationJobKey:job1,ActiveConfigurationURLKey:"http://www.google.com/job/Job1/config=1"]
        let ac2 = [ActiveConfigurationColorKey:"blue",ActiveConfigurationNameKey:"config=1",ActiveConfigurationJobKey:job2,ActiveConfigurationURLKey:"http://www.google.com/job/Job2/config=1"]
        let activeConf1 = ActiveConfiguration.createActiveConfigurationWithValues(ac1, inManagedObjectContext: context!)
        let activeConf2 = ActiveConfiguration.createActiveConfigurationWithValues(ac2, inManagedObjectContext: context!)
        let activeConfs = [activeConf1,activeConf2]
        let testImage = UIImage(named: "blue.png")
        
        let userInfo = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/Job1", JobBuildableKey: true, JobConcurrentBuildKey: false, JobDisplayNameKey: "Job1", JobFirstBuildKey: build1Obj, JobLastBuildKey: build1Obj, JobLastCompletedBuildKey: build1Obj, JobLastFailedBuildKey: build1Obj, JobLastStableBuildKey: build1Obj, JobLastSuccessfulBuildKey: build1Obj,JobLastUnstableBuildKey: build1Obj, JobLastUnsucessfulBuildKey: build1Obj, JobNextBuildNumberKey: 2, JobInQueueKey: false, JobDescriptionKey: "Job1 Description", JobKeepDependenciesKey: false, JobJenkinsInstanceKey: jenkinsInstance!, JobDownstreamProjectsKey: downstreamProjects, JobUpstreamProjectsKey: upstreamProjects, JobHealthReportKey: healthReport, JobActiveConfigurationsKey: activeConfs, JobLastSyncKey: NSDate()]
        let notification = NSNotification(name: JobDetailResponseReceivedNotification, object: self, userInfo: userInfo)
        
        mgr.jobDetailResponseReceived(notification)
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("Job", inManagedObjectContext: context!)
        fetchreq.predicate = NSPredicate(format: "name = %@", "Job1")
        fetchreq.includesPropertyValues = false
        
        let jobs = context?.executeFetchRequest(fetchreq, error: nil)
        let job = jobs![0] as Job
        job.setTestResultsImageWithImage(testImage)
        
        XCTAssertEqual(jobs!.count, 1, "jobs count is wrong. Should be 1 got: \(jobs!.count) instead")
        XCTAssertEqual(job.name, "Job1", "job name is wrong. should be Job1, got: \(job.name) instead")
        XCTAssertEqual(job.color, "blue", "job color is wrong. should be blue, got: \(job.color) instead")
        XCTAssertEqual(job.url, "http://www.google.com/job/Job1", "job url is wrong. should be http://www.google.com, got: \(job.url) instead")
        XCTAssertEqual(job.buildable, true, "job should be buildable")
        XCTAssertEqual(job.concurrentBuild, false, "job should not be a concurrent build")
        XCTAssertEqual(job.displayName, "Job1", "job displayName is wrong")
        XCTAssertEqual(job.firstBuild, 1, "job firstBuild is wrong")
        XCTAssertEqual(job.lastBuild, 1, "job lastBuild is wrong")
        XCTAssertEqual(job.lastCompletedBuild, 1, "job lastBuild is wrong")
        XCTAssertEqual(job.lastFailedBuild, 1, "job lastBuild is wrong")
        XCTAssertEqual(job.lastStableBuild, 1, "job lastBuild is wrong")
        XCTAssertEqual(job.lastSuccessfulBuild, 1, "job lastBuild is wrong")
        XCTAssertEqual(job.lastUnstableBuild, 1, "job lastBuild is wrong")
        XCTAssertEqual(job.lastUnsuccessfulBuild, 1, "job lastBuild is wrong")
        XCTAssertEqual(job.nextBuildNumber, 2, "job lastBuild is wrong")
        XCTAssertEqual(job.inQueue, false, "job should not be inQueue")
        XCTAssertEqual(job.job_description, "Job1 Description", "job description is wrong")
        XCTAssertEqual(job.keepDependencies, false, "Job keepDependencies should be false")
        XCTAssertNotNil(job.rel_Job_JenkinsInstance, "jenkins instance is nil")
        XCTAssertEqual(job.rel_Job_JenkinsInstance.name, jenkinsInstance!.name, "job's jenkins instance's name is wrong")
        XCTAssertEqual(job.upstreamProjects.count, 1, "upstream projects count is wrong")
        XCTAssertEqual(job.downstreamProjects.count, 2, "downstream projects count is wrong")
        XCTAssertEqual(job.upstreamProjects![0]["color"] as String, "red", "upstream project color is wrong")
        XCTAssertEqual(job.downstreamProjects![0]["color"] as String, "blue", "upstream project color is wrong")
        XCTAssertEqual(job.downstreamProjects![1]["url"] as String, "http://www.yahoo.com", "upstream project color is wrong")
        XCTAssertEqual(job.healthReport!["iconUrl"] as String, "health-80plus.png", "healthReport iconUrl is wrong")
        XCTAssertEqual(job.activeConfigurations.count, 2, "active configs count is wrong")
        XCTAssertEqual(job.activeConfigurations![1].color as String, "blue", "active config has wrong color")
        XCTAssertNotNil(job.testResultsImage, "job's test results image is nill")
        XCTAssertNotNil(job.lastSync, "job lastSync is nil")
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
        
        let request = NSURLRequest(URL: url!)
        let operation = AFHTTPRequestOperation(request: request)
        let serializer = AFJSONResponseSerializer()
        operation.responseSerializer = serializer
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("Job", inManagedObjectContext: context!)
        fetchreq.includesPropertyValues = false
        let jobs = context?.executeFetchRequest(fetchreq, error: nil)
        XCTAssertEqual(jobs!.count, 1, "jobs count is wrong. should  be 1 got: \(jobs!.count) instead")
        
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
                userInfo[JobJenkinsInstanceKey] = job1.rel_Job_JenkinsInstance
                let notification = NSNotification(name: JobDetailRequestFailedNotification, object: self, userInfo: userInfo)
                self.mgr.jobDetailRequestFailed(notification)
                requestFailureExpectation.fulfill()
        })
        
        operation.start()
        
        waitForExpectationsWithTimeout(5, handler: { error in
            
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
                        if view.url == "http://www.yourmomdoesnotexist.com/view/View1/api/json" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let viewURL = "http://www.yourmomdoesnotexist.com/view/View1/api/json"
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
                        if view.url == "http://www.google.com/view/View1/api/json" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let viewURL = "http://www.google.com/view/View1/api/json"
        let url = NSURL(string: viewURL)
        let viewVals = [ViewNameKey: "View1", ViewURLKey: viewURL, ViewJenkinsInstanceKey: jenkinsInstance!]
        let view1 = View.createViewWithValues(viewVals, inManagedObjectContext: context)
        
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
                let notification = NSNotification(name: ViewDetailRequestFailedNotification, object: self, userInfo: userInfo)
                self.mgr.viewDetailRequestFailed(notification)
                requestFailureExpectation.fulfill()
        })
        
        operation.start()
        
        waitForExpectationsWithTimeout(10, handler: { error in
            
        })
    }
    
    func testViewDetailResponseReceived() {
        let jobvals1 = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/Job1"]
        let jobvals2 = [JobNameKey: "Job2", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/Job2"]
        let jobvals3 = [JobNameKey: "Job3", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/Job3"]
        let jobs1 = [jobvals1,jobvals2,jobvals3]
        let jobs2 = [jobvals2,jobvals3]
        
        let childViewVals1 = [ViewNameKey: "child1", ViewURLKey: "http://www.google.com/jenkins/view/child1"]
        let childViewVals2 = [ViewNameKey: "child2", ViewURLKey: "http://www.google.com/jenkins/view/child2"]
        let childViews = [childViewVals1,childViewVals2]
        
        let userInfo = [ViewNameKey: "ParentView", ViewURLKey: "http://www.google.com/jenkins/view/Parent", ViewDescriptionKey: "this is the parent view", ViewJenkinsInstanceKey: jenkinsInstance!, ViewJobsKey: jobs1, ViewViewsKey: childViews]
        let notification = NSNotification(name: ViewDetailResponseReceivedNotification, object: self, userInfo: userInfo)
        
        mgr.viewDetailResponseReceived(notification)
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("View", inManagedObjectContext: context!)
        fetchreq.predicate = NSPredicate(format: "name = %@", "ParentView")

        let views = context?.executeFetchRequest(fetchreq, error: nil)
        let view  = views![0] as View
        
        XCTAssertEqual(views!.count, 1, "parent view count is wrong.")
        XCTAssertEqual(view.name, "ParentView", "view name is wrong")
        XCTAssertEqual(view.view_description, "this is the parent view", "parent view description is wrong")
        XCTAssertEqual(view.rel_View_JenkinsInstance, jenkinsInstance!, "parent view's jenkinsInstance is wrong")
        XCTAssertEqual(view.rel_View_Views.count, 2, "parent view's child view count is wrong")
        
        let allviewsfetchreq = NSFetchRequest()
        allviewsfetchreq.entity = NSEntityDescription.entityForName("View", inManagedObjectContext: context!)
        
        let allviews = context?.executeFetchRequest(allviewsfetchreq, error: nil)
        XCTAssertEqual(allviews!.count, 3, "all views count is wrong")
    }
    
    func testBuildDetailResponseReceived() {
        let causes = [[BuildCausesShortDescriptionKey: "because",BuildCausesUserIDKey: "10",BuildCausesUserNameKey: "kbeal"]]
        let actions = [[BuildCausesKey: causes]]
        let changeSetItems = ["one","two"]
        let changeSet = [BuildChangeSetItemsKey: changeSetItems, BuildChangeSetKindKey: "idk"]
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://jenkins:8080/job/TestJob", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        let userInfo = [BuildActionsKey: actions, BuildBuildingKey: true, BuildDescriptionKey: "A build", BuildDurationKey: 120000, BuildEstimatedDurationKey: 120001, BuildFullDisplayNameKey: "TestJob #1", BuildIDKey: "2015-01-07_21-57-03", BuildKeepLogKey: false, BuildNumberKey: 1, BuildResultKey: "SUCCESS", BuildTimestampKey:1420685823231, BuildURLKey: "http://jenkins:8080/TestJob/1", BuildChangeSetKey: changeSet, BuildJobKey: job]
        let notification = NSNotification(name: BuildDetailResponseReceivedNotification, object: self, userInfo: userInfo)
        
        mgr.buildDetailResponseReceived(notification)
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("Build", inManagedObjectContext: context!)
        fetchreq.predicate = NSPredicate(format: "url = %@", "http://jenkins:8080/TestJob/1")
        fetchreq.includesPropertyValues = false
        
        let builds = context?.executeFetchRequest(fetchreq, error: nil)
        let build = builds![0] as Build
        
        XCTAssertEqual(builds!.count, 1, "builds count is wrong. Should be 1 got: \(builds!.count) instead")
        XCTAssertEqual(build.url, "http://jenkins:8080/TestJob/1", "build url is wrong. got: \(build.url) instead")
        XCTAssertEqual(build.fullDisplayName, "TestJob #1", "build displayName is wrong")
        XCTAssertTrue(build.building.boolValue, "build should be building")
        XCTAssertEqual(build.build_description, "A build", "build description is wrong")
        XCTAssertEqual(build.duration, 120000, "build duration is wrong")
        XCTAssertEqual(build.estimatedDuration, 120001, "build estimated duration is wrong")
        XCTAssertEqual(build.fullDisplayName, "TestJob #1", "build display name is wrong")
        XCTAssertEqual(build.build_id, "2015-01-07_21-57-03", "build id is wrong")
        XCTAssertEqual(build.keepLog, false, "keepLog is wrong")
        XCTAssertEqual(build.number.integerValue, 1, "build number is wrong")
        XCTAssertEqual(build.result, "SUCCESS", "build result is wrong")
        XCTAssertEqual(build.timestamp.timeIntervalSince1970, 1420685823.231, "timestamp is wrong")
        XCTAssertEqual(build.url, "http://jenkins:8080/TestJob/1", "build url is wrong")
        
        let changeset: Dictionary = build.changeset as [String:AnyObject]
        let changeSetKind: String = changeset[BuildChangeSetKindKey] as String
        XCTAssertEqual(changeSetKind, "idk", "build change set kind is wrong")
        
        let buildAction: Dictionary = build.actions![0] as [String:AnyObject]
        let buildCauses: [Dictionary] = buildAction[BuildCausesKey]! as [[String:AnyObject]]
        let buildCause1: Dictionary = buildCauses[0] as [String:AnyObject]
        let causeDesc: String = buildCause1[BuildCausesShortDescriptionKey] as String
        XCTAssertEqual(causeDesc, "because", "build cause description is wrong")

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
                        if build.url == "http://www.google.com/TestJob/1" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://www.google.com/job/TestJob", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        let buildURL = "http://www.google.com/TestJob/1"
        let url = NSURL(string: buildURL)

        let buildVals = [BuildJobKey: job, BuildURLKey: buildURL, BuildNumberKey: 1]
        let build1 = Build.createBuildWithValues(buildVals, inManagedObjectContext: self.context)
        
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
    
    func testActiveConfigurationResponseReceived() {
        let build1Obj = ["number": 1, "url": "http://www.google.com/job/Job1/config=1/1"]
        let healthReport = ["iconUrl": "health-80plus.png"]
        let jobVals1 = [JobNameKey: "TestJob", JobColorKey: "blue", JobURLKey: "http://jenkins:8080/job/TestJob", JobJenkinsInstanceKey: jenkinsInstance!]
        let job = Job.createJobWithValues(jobVals1, inManagedObjectContext: context)
        
        let userInfo = [ActiveConfigurationNameKey: "config=1", ActiveConfigurationColorKey: "blue", ActiveConfigurationURLKey: "http://www.google.com/job/Job1/config=1", ActiveConfigurationBuildableKey: true, ActiveConfigurationConcurrentBuildKey: false, ActiveConfigurationDisplayNameKey: "Job1", ActiveConfigurationFirstBuildKey: build1Obj, ActiveConfigurationLastBuildKey: build1Obj, ActiveConfigurationLastCompletedBuildKey: build1Obj, ActiveConfigurationLastFailedBuildKey: build1Obj, ActiveConfigurationLastStableBuildKey: build1Obj, ActiveConfigurationLastSuccessfulBuildKey: build1Obj,ActiveConfigurationLastUnstableBuildKey: build1Obj, ActiveConfigurationLastUnsucessfulBuildKey: build1Obj, ActiveConfigurationNextBuildNumberKey: 2, ActiveConfigurationInQueueKey: false, ActiveConfigurationDescriptionKey: "Job1, config=1 Description", ActiveConfigurationKeepDependenciesKey: false,  ActiveConfigurationHealthReportKey: healthReport, ActiveConfigurationJobKey: job, ActiveConfigurationLastSyncKey: NSDate()]
        let notification = NSNotification(name: ActiveConfigurationDetailResponseReceivedNotification, object: self, userInfo: userInfo)
        
        mgr.activeConfigurationDetailResponseReceived(notification)
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("ActiveConfiguration", inManagedObjectContext: context!)
        fetchreq.predicate = NSPredicate(format: "url = %@", "http://www.google.com/job/Job1/config=1")
        fetchreq.includesPropertyValues = false
        
        let acs = context?.executeFetchRequest(fetchreq, error: nil)
        let ac = acs![0] as ActiveConfiguration
        
        XCTAssertEqual(acs!.count, 1, "jobs count is wrong. Should be 1 got: \(acs!.count) instead")
        XCTAssertEqual(ac.name, "config=1", "job name is wrong. should be Job1, got: \(ac.name) instead")
        XCTAssertEqual(ac.color, "blue", "job color is wrong. should be blue, got: \(ac.color) instead")
        XCTAssertEqual(ac.url, "http://www.google.com/job/Job1/config=1", "ac url is wrong.")
        XCTAssertEqual(ac.buildable, true, "ac should be buildable")
        XCTAssertEqual(ac.concurrentBuild, false, "ac should not be a concurrent build")
        XCTAssertEqual(ac.displayName, "Job1", "ac displayName is wrong")
        XCTAssertEqual(ac.firstBuild, 1, "ac firstBuild is wrong")
        XCTAssertEqual(ac.lastBuild, 1, "ac lastBuild is wrong")
        XCTAssertEqual(ac.lastCompletedBuild, 1, "ac lastBuild is wrong")
        XCTAssertEqual(ac.lastFailedBuild, 1, "ac lastBuild is wrong")
        XCTAssertEqual(ac.lastStableBuild, 1, "ac lastBuild is wrong")
        XCTAssertEqual(ac.lastSuccessfulBuild, 1, "ac lastBuild is wrong")
        XCTAssertEqual(ac.lastUnstableBuild, 1, "ac lastBuild is wrong")
        XCTAssertEqual(ac.lastUnsuccessfulBuild, 1, "ac lastBuild is wrong")
        XCTAssertEqual(ac.nextBuildNumber, 2, "ac lastBuild is wrong")
        XCTAssertEqual(ac.inQueue, false, "ac should not be inQueue")
        XCTAssertEqual(ac.activeConfiguration_description, "Job1, config=1 Description", "ac description is wrong")
        XCTAssertEqual(ac.keepDependencies, false, "ac keepDependencies should be false")
        XCTAssertNotNil(ac.rel_ActiveConfiguration_Job, "job is nil")
        XCTAssertEqual(ac.healthReport!["iconUrl"] as String, "health-80plus.png", "healthReport iconUrl is wrong")
    }
}
