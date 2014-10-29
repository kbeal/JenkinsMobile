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
        
        let modelURL = NSBundle.mainBundle().URLForResource("JenkinsMobile", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: modelURL!)
        let coord = NSPersistentStoreCoordinator(managedObjectModel: model)
        context = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        coord.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: nil)
        context!.persistentStoreCoordinator = coord
        mgr.mainMOC = context;
        mgr.masterMOC = context;
        
        let jenkinsInstanceValues = [JenkinsInstanceNameKey: "TestInstance", JenkinsInstanceURLKey: "http://tomcat:8080/", JenkinsInstanceCurrentKey: false]
        jenkinsInstance = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues, inManagedObjectContext: context)


    }
    
    func testSharedInstance() {
        XCTAssertNotNil(mgr, "shared instance is nil")
    }
    
    func testUniqueQueueIter() {
        let uq = UniqueQueue()
        
        uq.push("Job1")
        uq.push("Job2")
        uq.push("Job3")
        uq.push("Job3")
        uq.push("Job5")
        uq.push("Job1")
        
        for item in uq {
            //println(item)
            XCTAssertNotNil(item, "item is nil")
        }
    }
    
    func testUniqueQueueRemoveAll() {
        let uq = UniqueQueue()
        
        uq.push("Job1")
        uq.push("Job2")
        uq.push("Job3")
        uq.push("Job3")
        uq.push("Job5")
        uq.push("Job1")
        XCTAssertEqual(uq.count(), 4, "uq count is wrong")
        
        uq.removeAll()
        XCTAssertEqual(uq.count(), 0, "uq count is wrong")
    }
    
    func testSyncAllJobs() {
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com"]
        let job2vals = [JobNameKey: "Job2", JobColorKey: "green", JobURLKey: "http://www.weather.com"]
        let job3vals = [JobNameKey: "Job3", JobColorKey: "red", JobURLKey: "http://www.bing.com"]
        let job4vals = [JobNameKey: "Job4", JobColorKey: "yellow", JobURLKey: "http://www.google.com"]
        let job5vals = [JobNameKey: "Job5", JobColorKey: "blue", JobURLKey: "http://www.yahoo.com"]
        
        let job1 = Job.createJobWithValues(job1vals, inManagedObjectContext: self.mgr.mainMOC)
        let job2 = Job.createJobWithValues(job2vals, inManagedObjectContext: self.mgr.mainMOC)
        let job3 = Job.createJobWithValues(job3vals, inManagedObjectContext: self.mgr.mainMOC)
        let job4 = Job.createJobWithValues(job4vals, inManagedObjectContext: self.mgr.mainMOC)
        let job5 = Job.createJobWithValues(job5vals, inManagedObjectContext: self.mgr.mainMOC)
        
        self.jenkinsInstance?.addRel_JobsObject(job1)
        self.jenkinsInstance?.addRel_JobsObject(job2)
        self.jenkinsInstance?.addRel_JobsObject(job3)
        self.jenkinsInstance?.addRel_JobsObject(job4)
        self.jenkinsInstance?.addRel_JobsObject(job5)

        mgr.currentJenkinsInstance = self.jenkinsInstance
        mgr.syncAllJobs()
        XCTAssertEqual(mgr.jobSyncQueueSize(), 5, "sync manager's jobSyncQueueSize is wrong")
    }
    
    func testSwitchJenkinsInstance() {
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com"]
        let job2vals = [JobNameKey: "Job2", JobColorKey: "green", JobURLKey: "http://www.weather.com"]
        let job3vals = [JobNameKey: "Job3", JobColorKey: "red", JobURLKey: "http://www.bing.com"]
        let job4vals = [JobNameKey: "Job4", JobColorKey: "yellow", JobURLKey: "http://www.google.com"]
        let job5vals = [JobNameKey: "Job5", JobColorKey: "blue", JobURLKey: "http://www.yahoo.com"]
        
        let job1 = Job.createJobWithValues(job1vals, inManagedObjectContext: self.mgr.mainMOC)
        let job2 = Job.createJobWithValues(job2vals, inManagedObjectContext: self.mgr.mainMOC)
        let job3 = Job.createJobWithValues(job3vals, inManagedObjectContext: self.mgr.mainMOC)
        let job4 = Job.createJobWithValues(job4vals, inManagedObjectContext: self.mgr.mainMOC)
        let job5 = Job.createJobWithValues(job5vals, inManagedObjectContext: self.mgr.mainMOC)
        
        self.jenkinsInstance?.addRel_JobsObject(job1)
        self.jenkinsInstance?.addRel_JobsObject(job2)
        self.jenkinsInstance?.addRel_JobsObject(job3)
        self.jenkinsInstance?.addRel_JobsObject(job4)
        self.jenkinsInstance?.addRel_JobsObject(job5)
        
        mgr.currentJenkinsInstance = self.jenkinsInstance
        mgr.syncAllJobs()
        XCTAssertEqual(mgr.jobSyncQueueSize(), 5, "sync manager's jobSyncQueueSize is wrong")
        
        let jenkinsInstanceValues2 = [JenkinsInstanceNameKey: "TestInstance2", JenkinsInstanceURLKey: "http://tomcat2:8080/", JenkinsInstanceCurrentKey: false]
        let jenkinsInstance2 = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues2, inManagedObjectContext: context)
        mgr.currentJenkinsInstance = jenkinsInstance2
        mgr.syncAllJobs()
        XCTAssertEqual(mgr.jobSyncQueueSize(), 0, "sync manager's jobSyncQueueSize is wrong")
    }
    
    func testUniqueQueuePush() {
        let uq = UniqueQueue()
        
        //initial item count should be 0
        XCTAssertEqual(uq.count(), 0, "initial uq count is wrong")
        
        uq.push("Job1")
        XCTAssertEqual(uq.count(), 1, "uq count after push is wrong")
        uq.push("job2")
        XCTAssertEqual(uq.count(), 2, "uq count after push2 is wrong")
        uq.push("Job1")
        XCTAssertEqual(uq.count(), 2, "uq count after second push of Job1 is wrong")
    }
    
    func testUniqueQueuePop() {
        let uq = UniqueQueue()
        
        uq.push("Job1")
        uq.push("Job2")
        uq.push("Job3")
        uq.push("Job3")
        uq.push("Job5")
        uq.push("Job1")
        XCTAssertEqual(uq.count(), 4, "uq count is wrong")
        //should pop in this order: 1,2,3,5
        let pop1 = uq.pop() //1
        XCTAssertEqual(uq.count(), 3, "uq count is wrong after pop1")
        let pop2 = uq.pop() //2
        XCTAssertEqual(uq.count(), 2, "uq count is wrong after pop2")
        let pop3 = uq.pop() //3
        XCTAssertEqual(uq.count(), 1, "uq count is wrong after pop3")
        let pop4 = uq.pop() //5
        XCTAssertEqual(uq.count(), 0, "uq count is wrong after pop4")
        let pop5 = uq.pop() //empty
        
        XCTAssertEqual(pop1!, "Job1", "pop1 is wrong")
        XCTAssertEqual(pop2!, "Job2", "pop2 is wrong")
        XCTAssertEqual(pop3!, "Job3", "pop3 is wrong")
        XCTAssertEqual(pop4!, "Job5", "pop4 is wrong")
        XCTAssertNil(pop5, "pop5 is wrong")
        
        uq.push("Job1")
        uq.push("Job2")
        uq.push("Job3")
        let pop6 = uq.pop() //Job1
        uq.push("Job1")
        uq.push("Job5")
        uq.push("Job1")
        XCTAssertEqual(uq.count(), 4, "uq count is wrong")
        //should pop in this order: 2,3,1,5
        let pop7 = uq.pop() //Job2
        XCTAssertEqual(uq.count(), 3, "uq count is wrong after pop7")
        let pop8 = uq.pop() //Job3
        XCTAssertEqual(uq.count(), 2, "uq count is wrong after pop8")
        let pop9 = uq.pop() //Job1
        XCTAssertEqual(uq.count(), 1, "uq count is wrong after pop9")
        let pop10 = uq.pop() //Job5
        XCTAssertEqual(uq.count(), 0, "uq count is wrong after pop10")
        
        XCTAssertEqual(pop6!, "Job1", "pop6 is wrong")
        XCTAssertEqual(pop7!, "Job2", "pop7 is wrong")
        XCTAssertEqual(pop8!, "Job3", "pop8 is wrong")
        XCTAssertEqual(pop9!, "Job1", "pop9 is wrong")
        XCTAssertEqual(pop10!, "Job5", "pop10 is wrong")
    }
    
    func testJobShouldSync() {
        let jobvals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com", JobLastSyncKey: NSDate()]
        let job = Job.createJobWithValues(jobvals, inManagedObjectContext: context)
        
        XCTAssertFalse(job.shouldSync(), "shouldsync should be false")
    }
    
    func testJenkinsInstanceDetailResponseReceived() {
        let jobObj1 = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com"]
        let jobObj2 = [JobNameKey: "Job2", JobColorKey: "red", JobURLKey: "http://www.yahoo.com"]
        let jobObj3 = [JobNameKey: "Job3", JobColorKey: "green", JobURLKey: "http://www.bing.com"]
        let jobObj4 = [JobNameKey: "Job4", JobColorKey: "grey", JobURLKey: "http://www.amazon.com"]
        let jobs = [jobObj1, jobObj2, jobObj3, jobObj4]
        
        let userInfo = [JenkinsInstanceNameKey: "QA Ubuntu", JenkinsInstanceURLKey: "https://jenkins.qa.ubuntu.com/", JenkinsInstanceJobsKey: jobs]
        let notification = NSNotification(name: JenkinsInstanceDetailResponseReceivedNotification, object: self, userInfo: userInfo)
        
        mgr.jenkinsInstanceDetailResponseReceived(notification)
        
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("JenkinsInstance", inManagedObjectContext: context!)
        fetchreq.predicate = NSPredicate(format: "name = %@", "QA Ubuntu")
        fetchreq.includesPropertyValues = false
        
        let jenkinss = context?.executeFetchRequest(fetchreq, error: nil)
        let ji = jenkinss![0] as JenkinsInstance

        XCTAssertEqual(jenkinss!.count, 1, "jenkinss count is wrong. Should be 1 got: \(jenkinss!.count) instead")
        XCTAssertEqual(ji.name, "QA Ubuntu", "jenkins instance name is wrong. should be QA Ubuntu, got: \(ji.name) instead")
        XCTAssertEqual(ji.rel_Jobs.count, 4, "jenkins instance job count is wrong. should be 4, got:\(ji.rel_Jobs.count) instead")
    }
    
    func testJenkinsInstanceRequestFailed() {
        let expectation = expectationWithDescription("JenkinsInstance will be deleted")
        let url = NSURL(string: "https://www.google.com/api/json")
        let request = NSURLRequest(URL: url)
        let operation = AFHTTPRequestOperation(request: request)
        operation.responseSerializer = AFJSONResponseSerializer()
        
        operation.setCompletionBlockWithSuccess(
            { operation, response in
                println("jenkins request received")
            },
            failure: { operation, error in
                let userinfo = error.userInfo! as Dictionary
                let failurl = userinfo["NSErrorFailingURLKey"]
                println("jenkins request failed \(failurl!)")
                expectation.fulfill()
        })
        
        operation.start()
        
        waitForExpectationsWithTimeout(10, handler: { error in
            
        })
    }

    /*
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {

    [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstanceDetailResponseReceivedNotification object:self userInfo:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    
    
    NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    [[NSNotificationCenter defaultCenter] postNotificationName:JenkinsInstanceDetailRequestFailedNotification object:self userInfo:error.userInfo];
    }];
    
    [operation start];
    }*/
    
    
    func testJobDetailResponseReceived() {
        let build1Obj = ["number": 1, "url": "http://www.google.com"]
        let downstreamObj1 = ["name": "Job2", "color": "blue", "url":"http://www.google.com"]
        let downstreamObj2 = ["name": "Job3", "color": "green", "url":"http://www.yahoo.com"]
        let upstreamObj1 = ["name": "Job4", "color": "red", "url":"http://www.bing.com"]
        let downstreamProjects = [downstreamObj1, downstreamObj2]
        let upstreamProjects = [upstreamObj1]
        let healthReport = ["iconUrl": "health-80plus.png"]
        let activeConf1 = ActiveConfiguration(name:"conf1",color:"blue",andURL:"http://www.google.com")
        let activeConf2 = ActiveConfiguration(name:"conf2",color:"red",andURL:"http://www.yahoo.com")
        let activeConfs = [activeConf1,activeConf2]
        let testImage = UIImage(named: "blue.png")
        
        let userInfo = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com", JobBuildableKey: true, JobConcurrentBuildKey: false, JobDisplayNameKey: "Job1", JobFirstBuildKey: build1Obj, JobLastBuildKey: build1Obj, JobLastCompletedBuildKey: build1Obj, JobLastFailedBuildKey: build1Obj, JobLastStableBuildKey: build1Obj, JobLastSuccessfulBuildKey: build1Obj,JobLastUnstableBuildKey: build1Obj, JobLastUnsucessfulBuildKey: build1Obj, JobNextBuildNumberKey: 2, JobInQueueKey: false, JobDescriptionKey: "Job1 Description", JobKeepDependenciesKey: false, JobJenkinsInstanceKey: jenkinsInstance!, JobDownstreamProjectsKey: downstreamProjects, JobUpstreamProjectsKey: upstreamProjects, JobHealthReportKey: healthReport, JobActiveConfigurationsKey: activeConfs, JobLastSyncKey: NSDate()]
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
        XCTAssertEqual(job.url, "http://www.google.com", "job url is wrong. should be http://www.google.com, got: \(job.url) instead")
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
