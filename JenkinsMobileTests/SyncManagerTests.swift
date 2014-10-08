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
    
    func testJobDetailResponseReceived() {
        let build1Obj = ["number": 1, "url": "http://www.google.com"]
        let userInfo = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://www.google.com", JobBuildableKey: true, JobConcurrentBuildKey: false, JobDisplayNameKey: "Job1", JobFirstBuildKey: build1Obj, JobLastBuildKey: build1Obj, JobLastCompletedBuildKey: build1Obj, JobLastFailedBuildKey: build1Obj, JobLastStableBuildKey: build1Obj, JobLastSuccessfulBuildKey: build1Obj,JobLastUnstableBuildKey: build1Obj, JobLastUnsucessfulBuildKey: build1Obj, JobNextBuildNumberKey: 2, JobInQueueKey: false, JobDescriptionKey: "Job1 Description", JobKeepDependenciesKey: false, JobJenkinsInstanceKey: jenkinsInstance!]
        let notification = NSNotification(name: JobDetailResponseReceivedNotification, object: self, userInfo: userInfo)
        
        mgr.jobDetailResponseReceived(notification)
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("Job", inManagedObjectContext: context!)
        fetchreq.predicate = NSPredicate(format: "name = %@", "Job1")
        fetchreq.includesPropertyValues = false
        
        let jobs = context?.executeFetchRequest(fetchreq, error: nil)
        let job = jobs![0] as Job
        
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
    }
    
    /*
XCTAssert([job.upstreamProjects count]==1, @"wrong number of upstream projects");
XCTAssert([job.downstreamProjects count]==2, @"wrong number of downstream projects");
XCTAssert([[[job.upstreamProjects objectAtIndex:0] objectForKey:@"color"] isEqualToString:@"blue"], @"upstream project has wrong color");
XCTAssert([[[job.downstreamProjects objectAtIndex:0] objectForKey:@"color"] isEqualToString:@"green"], @"downstream project1 has wrong color");
XCTAssert([[[job.downstreamProjects objectAtIndex:1] objectForKey:@"url"] isEqualToString:@"http://www.yahoo.com"], @"downstream project2 has wrong url");
XCTAssert([[job.healthReport objectForKey:@"iconUrl"] isEqualToString:@"health-80plus.png"], @"health report is wrong %@", [job.healthReport objectForKey:@"iconUrl"]);
XCTAssert([job.activeConfigurations count]==2, @"wrong number of active configurations");
XCTAssert([[[job.activeConfigurations objectAtIndex:1] objectForKey:@"color"] isEqualToString:@"red"], @"active config has wrong color %@", [[job.activeConfigurations objectAtIndex:1] objectForKey:@"color"]);
XCTAssertTrue([job.getTestResultsImage isKindOfClass:[UIImage class]], @"%@%@",@"test results image is not UIImage, returned ",NSStringFromClass([job.getTestResultsImage class]));
XCTAssertNotNil(job.testResultsImage, @"job's test results image is nil");
*/
}
