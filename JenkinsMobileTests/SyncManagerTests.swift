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
        uq.pop() //Job1
        uq.push("Job1")
        uq.push("Job5")
        uq.push("Job1")
        XCTAssertEqual(uq.count(), 4, "uq count is wrong")
        //should pop in this order: 2,3,1,5
        let pop6 = uq.pop() //Job2
        XCTAssertEqual(uq.count(), 3, "uq count is wrong after pop6")
        let pop7 = uq.pop() //Job3
        XCTAssertEqual(uq.count(), 2, "uq count is wrong after pop7")
        let pop8 = uq.pop() //Job1
        XCTAssertEqual(uq.count(), 1, "uq count is wrong after pop8")
        let pop9 = uq.pop() //Job5
        XCTAssertEqual(uq.count(), 0, "uq count is wrong after pop9")
        
        XCTAssertEqual(pop6!, "Job2", "pop6 is wrong")
        XCTAssertEqual(pop7!, "Job3", "pop7 is wrong")
        XCTAssertEqual(pop8!, "Job1", "pop8 is wrong")
        XCTAssertEqual(pop9!, "Job5", "pop9 is wrong")
    }
    
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
        
        let userInfo = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com", JobBuildableKey: true, JobConcurrentBuildKey: false, JobDisplayNameKey: "Job1", JobFirstBuildKey: build1Obj, JobLastBuildKey: build1Obj, JobLastCompletedBuildKey: build1Obj, JobLastFailedBuildKey: build1Obj, JobLastStableBuildKey: build1Obj, JobLastSuccessfulBuildKey: build1Obj,JobLastUnstableBuildKey: build1Obj, JobLastUnsucessfulBuildKey: build1Obj, JobNextBuildNumberKey: 2, JobInQueueKey: false, JobDescriptionKey: "Job1 Description", JobKeepDependenciesKey: false, JobJenkinsInstanceKey: jenkinsInstance!, JobDownstreamProjectsKey: downstreamProjects, JobUpstreamProjectsKey: upstreamProjects, JobHealthReportKey: healthReport, JobActiveConfigurationsKey: activeConfs]
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
    }
}
