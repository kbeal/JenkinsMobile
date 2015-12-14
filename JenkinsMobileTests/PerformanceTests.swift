//
//  PerformanceTests.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 11/11/15.
//  Copyright © 2015 Kyle Beal. All rights reserved.
//

import Foundation
import XCTest
import JenkinsMobile

class PerformanceTests: XCTestCase {
    let mgr = SyncManager.sharedInstance
    let datamgr = DataManager.sharedInstance
    var context: NSManagedObjectContext?
    var jenkinsInstance: JenkinsInstance?
    
    override func setUp() {
        super.setUp()

        //context = self.datamgr.mainMOC
        context = self.datamgr.masterMOC
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://localhost:8080/"]
        let jenkinsInstanceValues = [JenkinsInstanceNameKey: "TestInstance", JenkinsInstanceURLKey: "http://localhost:8080", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "admin", JenkinsInstancePrimaryViewKey: primaryView]
        
        context?.performBlockAndWait({self.jenkinsInstance = JenkinsInstance.createJenkinsInstanceWithValues(jenkinsInstanceValues as [NSObject : AnyObject], inManagedObjectContext: self.context!)})
        self.jenkinsInstance?.password = "password"
        self.jenkinsInstance?.allowInvalidSSLCertificate = true
        
        saveContext()
    }
    
    override func tearDown() {
        self.jenkinsInstance?.managedObjectContext?.deleteObject(self.jenkinsInstance!)
        saveContext()
    }
    
    func saveContext () {
        datamgr.saveContext(datamgr.mainMOC)
        datamgr.masterMOC.performBlockAndWait({
            self.datamgr.saveContext(self.datamgr.masterMOC)
        })
    }
    
    func testPerformanceFindJobsWithNames() {
        let existingJobCount = 10000
        let jobBatchCount = 1000
        var jobNames: [String] = []
        var existingJobNames: [String] = []
        
        for i in 1...existingJobCount {
            let uuid = NSUUID().UUIDString
            let vals: [String: AnyObject] = [JobNameKey: uuid, JobURLKey: "http://localhost:8080/job/"+uuid, JobColorKey: "blue", JobJenkinsInstanceKey: self.jenkinsInstance!]
            Job.createJobWithValues(vals, inManagedObjectContext: self.context)
            // save half of the names up to jobBatchCount
            if ((i%2 == 0) && (existingJobNames.count < jobBatchCount)){
                existingJobNames.append(uuid)
            }
        }
        
        let knownuuid = NSUUID().UUIDString
        let knownVals: [String: AnyObject] = [JobNameKey: knownuuid, JobURLKey: "http://localhost:8080/job/"+knownuuid, JobColorKey: "blue", JobJenkinsInstanceKey: self.jenkinsInstance!]
        Job.createJobWithValues(knownVals, inManagedObjectContext: self.context)
        jobNames.append(knownuuid)
        
        for _ in 1...jobBatchCount {
            let uuid = NSUUID().UUIDString
            jobNames.append(uuid)
        }
        
        saveContext()
        XCTAssertEqual(self.jenkinsInstance?.rel_Jobs!.count, existingJobCount+1)
        XCTAssertEqual(existingJobNames.count, jobBatchCount)
        
        self.measureBlock({
            let jobs = Job.fetchJobsWithNames(jobNames, inManagedObjectContext: self.context, andJenkinsInstance: self.jenkinsInstance)
            XCTAssertEqual(jobs.count, 1)
            //let existingJobs = Job.fetchJobsWithNames(existingJobNames, inManagedObjectContext: self.context, andJenkinsInstance: self.jenkinsInstance)
            //XCTAssertEqual(existingJobs.count, jobBatchCount)
        })
    }
    
    func testPerformanceSetFromArray() {
        let jobcount = 1000
        var jobs: [JobDictionary] = []
        var jobSet: NSSet
        
        for _ in 1...jobcount {
            let uuid = NSUUID().UUIDString
            let dict = NSDictionary(objects: [uuid,"blue","http://www.google.com"], forKeys: [JobNameKey,JobColorKey,JobURLKey])
            jobs.append(JobDictionary(dictionary: dict)!)
        }
        
        jobSet = NSSet(array: jobs)
        
        self.measureBlock({
            jobSet = NSSet(array: jobs)
        })
        
        XCTAssertEqual(jobSet.count, jobcount)
    }

    func testPerformanceViewSaveValues() {
        let jobcount = 1000
        _ = expectationForNotification(NSManagedObjectContextDidSaveNotification, object: self.datamgr.masterMOC, handler: {
            (notification: NSNotification!) -> Bool in
            var expectationFulfilled = false
            let updatedObjects: NSSet? = notification.userInfo![NSUpdatedObjectsKey] as! NSSet?
            if updatedObjects != nil {
                for obj in updatedObjects! {
                    if let ji = obj as? JenkinsInstance {
                        if ji.url == "http://localhost:8080/" && ji.rel_Jobs!.count == jobcount {
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
        
        let values: [NSObject: AnyObject] = [ViewNameKey: "TestView", ViewURLKey: "http://localhost:8080/view/TestView/", ViewJobsKey: jobs, ViewJenkinsInstanceKey: self.jenkinsInstance!]
        
        self.measureBlock({
            View.createViewWithValues(values, inManagedObjectContext: self.datamgr.masterMOC)
        })
        
        waitForExpectationsWithTimeout(20, handler: { error in
            
        })
    }
}