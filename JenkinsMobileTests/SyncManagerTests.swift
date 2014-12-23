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
        coord.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: nil)
        context!.persistentStoreCoordinator = coord
        mgr.mainMOC = context;
        mgr.masterMOC = context;
        mgr.requestHandler = requestHandler
        
        let jenkinsInstanceValues = [JenkinsInstanceNameKey: "TestInstance", JenkinsInstanceURLKey: "http://www.google.com", JenkinsInstanceCurrentKey: false]
        
        context?.performBlockAndWait({self.jenkinsInstance = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues, inManagedObjectContext: self.context)})
        
        mgr.currentJenkinsInstanceURL = NSURL(string: jenkinsInstance!.url)
    }
    
    func testSharedInstance() {
        XCTAssertNotNil(mgr, "shared instance is nil")
    }
    
    func testJobShouldSync() {
        let jobvals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com", JobLastSyncKey: NSDate()]
        let job = Job.createJobWithValues(jobvals, inManagedObjectContext: context)
        
        XCTAssertFalse(job.shouldSync(), "shouldsync should be false")
    }
    
    func testJenkinsInstanceFindOrCreated() {
        let jobObj1 = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com"]
        let jobObj2 = [JobNameKey: "Job2", JobColorKey: "red", JobURLKey: "http://www.yahoo.com"]
        let jobObj3 = [JobNameKey: "Job3", JobColorKey: "green", JobURLKey: "http://www.bing.com"]
        let jobObj4 = [JobNameKey: "Job4", JobColorKey: "grey", JobURLKey: "http://www.amazon.com"]
        let jobs = [jobObj1, jobObj2, jobObj3, jobObj4]
        
        let values = [JenkinsInstanceNameKey: "QA Ubuntu", JenkinsInstanceURLKey: "https://jenkins.qa.ubuntu.com/", JenkinsInstanceJobsKey: jobs, JenkinsInstanceCurrentKey: false]

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
        let requestFailureExpectation = expectationWithDescription("JenkinsInstance will be deleted")
        let jInstanceDeletedNotificationExpectionat = expectationForNotification(NSManagedObjectContextObjectsDidChangeNotification, object: self.context, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let deletedObjects: NSSet? = notification.userInfo![NSDeletedObjectsKey] as NSSet?
            if deletedObjects != nil {
                for obj in deletedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        if ji.url == "http://www.google.com" {
                            expectationFulfilled=true
                        }
                    }
                }
            }
            return expectationFulfilled
        })
        
        let url = NSURL(string: "http://www.google.com")
        let request = NSURLRequest(URL: NSURL(string: "/api/json", relativeToURL: url)!)
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
            },
            failure: { operation, error in
                var userInfo: Dictionary = error.userInfo!
                userInfo[StatusCodeKey] = operation.response.statusCode
                let notification = NSNotification(name: JenkinsInstanceDetailRequestFailedNotification, object: self, userInfo: userInfo)
                self.mgr.jenkinsInstanceDetailRequestFailed(notification)
                requestFailureExpectation.fulfill()
        })
        
        operation.start()
        
        waitForExpectationsWithTimeout(10, handler: { error in
            
        })
    }
    
    func testJobDetailRequestFailed() {
        let requestFailureExpectation = expectationWithDescription("Job1 will be deleted")
        let jobDeletedNotificationExpectionat = expectationForNotification(NSManagedObjectContextObjectsDidChangeNotification, object: self.context, handler: {
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
            },
            failure: { operation, error in
                var userInfo: Dictionary = error.userInfo!
                userInfo[StatusCodeKey] = operation.response.statusCode
                let url: NSURL = userInfo[NSErrorFailingURLKey] as NSURL
                let jobName = url.relativeString
                let notification = NSNotification(name: JobDetailRequestFailedNotification, object: self, userInfo: userInfo)
                self.mgr.jobDetailRequestFailed(notification)
                requestFailureExpectation.fulfill()
        })
        
        operation.start()
        
        waitForExpectationsWithTimeout(5, handler: { error in
            
        })
    }
    
    func testViewDetailRequestFailed() {
        let requestFailureExpectation = expectationWithDescription("View1 will be deleted")
        let viewDeletedNotificationExpectionat = expectationForNotification(NSManagedObjectContextObjectsDidChangeNotification, object: self.context, handler: {
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
                var userInfo: Dictionary = error.userInfo!
                userInfo[StatusCodeKey] = operation.response.statusCode
                let url: NSURL = userInfo[NSErrorFailingURLKey] as NSURL
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
    
    func testJobDetailResponseReceived() {
        let build1Obj = ["number": 1, "url": "http://www.google.com/job/Job1/build/1"]
        let downstreamObj1 = ["name": "Job2", "color": "blue", "url":"http://www.ask.com"]
        let downstreamObj2 = ["name": "Job3", "color": "green", "url":"http://www.yahoo.com"]
        let upstreamObj1 = ["name": "Job4", "color": "red", "url":"http://www.bing.com"]
        let downstreamProjects = [downstreamObj1, downstreamObj2]
        let upstreamProjects = [upstreamObj1]
        let healthReport = ["iconUrl": "health-80plus.png"]
        let activeConf1 = ActiveConfiguration(name:"conf1",color:"blue",andURL:"http://www.altavista.com")
        let activeConf2 = ActiveConfiguration(name:"conf2",color:"red",andURL:"http://www.yahoo.com")
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
        XCTAssertEqual(job.activeConfigurations![1].color as String, "red", "active config has wrong color")
        XCTAssertNotNil(job.testResultsImage, "job's test results image is nill")
        XCTAssertNotNil(job.lastSync, "job lastSync is nil")
    }
}
