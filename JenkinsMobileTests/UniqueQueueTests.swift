//
//  UniqueQueueTests.swift
//  JenkinsMobile
//
//  Created by Kyle on 11/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

import Foundation
import XCTest
import JenkinsMobile

class UniqueQueueTests: XCTestCase {
    
    var jenkinsInstance: JenkinsInstance?
    let datamgr: DataManager = DataManager.sharedInstance
    var context: NSManagedObjectContext!
    
    override func setUp() {
        context = datamgr.mainMOC
        let primaryView = [ViewNameKey: "All", ViewURLKey: "http://jenkins:8080/"]
        let jenkinsInstanceValues = [JenkinsInstanceNameKey: "TestInstance", JenkinsInstanceURLKey: "http://jenkins:8080", JenkinsInstanceEnabledKey: true, JenkinsInstanceUsernameKey: "admin", JenkinsInstancePrimaryViewKey: primaryView]
        
        self.jenkinsInstance = JenkinsInstance.createJenkinsInstance(withValues: jenkinsInstanceValues as [AnyHashable: Any], in: datamgr.mainMOC)
    }

    func testUniqueQueueIter() {
        let uq = UniqueQueue<Job>()
        
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job1/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job2vals = [JobNameKey: "Job2", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job2/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job3vals = [JobNameKey: "Job3", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job3/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job4vals = [JobNameKey: "Job4", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job4/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJob(withValues: job1vals, in: context)
        let job2 = Job.createJob(withValues: job2vals, in: context)
        let job3 = Job.createJob(withValues: job3vals, in: context)
        let job4 = Job.createJob(withValues: job4vals, in: context)
        
        uq.push(job1)
        uq.push(job2)
        uq.push(job3)
        uq.push(job3)
        uq.push(job4)
        uq.push(job1)
        
        for item in uq {
            //println(item)
            XCTAssertNotNil(item, "item is nil")
        }
    }
    
    func testUniqueQueueIterPop() {
        let uq = UniqueQueue<Job>()
        
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job1/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job2vals = [JobNameKey: "Job2", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job2/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job3vals = [JobNameKey: "Job3", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job3/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job4vals = [JobNameKey: "Job4", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job4/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJob(withValues: job1vals, in: context)
        let job2 = Job.createJob(withValues: job2vals, in: context)
        let job3 = Job.createJob(withValues: job3vals, in: context)
        let job4 = Job.createJob(withValues: job4vals, in: context)
        
        uq.push(job1)
        uq.push(job2)
        uq.push(job3)
        uq.push(job3)
        uq.push(job4)
        uq.push(job1)
        
        var itmcnt = 0
        
        for item in uq {
            let popped = uq.pop()
            XCTAssertEqual(popped!, item, "popped item is not correct")
            itmcnt = itmcnt + 1
        }
        
        XCTAssertEqual(itmcnt, 4, "item count is wrong after iterating and popping")
        XCTAssertEqual(uq.count(), 0, "uq count is wrong")
    }
    
    func testUniqueQueueRemoveAll() {
        let uq = UniqueQueue<Job>()
        
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job1/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job2vals = [JobNameKey: "Job2", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job2/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job3vals = [JobNameKey: "Job3", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job3/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job4vals = [JobNameKey: "Job4", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job4/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJob(withValues: job1vals, in: context)
        let job2 = Job.createJob(withValues: job2vals, in: context)
        let job3 = Job.createJob(withValues: job3vals, in: context)
        let job4 = Job.createJob(withValues: job4vals, in: context)
        
        uq.push(job1)
        uq.push(job2)
        uq.push(job3)
        uq.push(job3)
        uq.push(job4)
        uq.push(job1)
        
        XCTAssertEqual(uq.count(), 4, "uq count is wrong")
        
        uq.removeAll()
        XCTAssertEqual(uq.count(), 0, "uq count is wrong")
    }
    
    func testUniqueQueuePush() {
        let uq = UniqueQueue<Job>()
        
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job1/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job2vals = [JobNameKey: "Job2", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job2/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJob(withValues: job1vals, in: context)
        let job2 = Job.createJob(withValues: job2vals, in: context)
        
        //initial item count should be 0
        XCTAssertEqual(uq.count(), 0, "initial uq count is wrong")
        
        uq.push(job1)
        XCTAssertEqual(uq.count(), 1, "uq count after push is wrong")
        uq.push(job2)
        XCTAssertEqual(uq.count(), 2, "uq count after push2 is wrong")
        uq.push(job1)
        XCTAssertEqual(uq.count(), 2, "uq count after second push of Job1 is wrong")
    }
    
    func testUniqueQueuePop() {
        let uq = UniqueQueue<Job>()
        
        let job1vals = [JobNameKey: "Job1", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job1/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job2vals = [JobNameKey: "Job2", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job2/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job3vals = [JobNameKey: "Job3", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job3/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job4vals = [JobNameKey: "Job4", JobColorKey: "blue", JobURLKey: "http://snowman:8080/jenkins/job/Job4/", JobJenkinsInstanceKey: jenkinsInstance!]
        let job1 = Job.createJob(withValues: job1vals, in: context)
        let job2 = Job.createJob(withValues: job2vals, in: context)
        let job3 = Job.createJob(withValues: job3vals, in: context)
        let job4 = Job.createJob(withValues: job4vals, in: context)
        
        uq.push(job1)
        uq.push(job2)
        uq.push(job3)
        uq.push(job3)
        uq.push(job4)
        uq.push(job1)
        
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
        
        XCTAssertEqual(pop1!, job1, "pop1 is wrong")
        XCTAssertEqual(pop2!, job2, "pop2 is wrong")
        XCTAssertEqual(pop3!, job3, "pop3 is wrong")
        XCTAssertEqual(pop4!, job4, "pop4 is wrong")
        XCTAssertNil(pop5, "pop5 is wrong")
        
        uq.push(job1)
        uq.push(job2)
        uq.push(job3)
        let pop6 = uq.pop() //Job1
        uq.push(job1)
        uq.push(job4)
        uq.push(job1)
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
        
        XCTAssertEqual(pop6!, job1, "pop6 is wrong")
        XCTAssertEqual(pop7!, job2, "pop7 is wrong")
        XCTAssertEqual(pop8!, job3, "pop8 is wrong")
        XCTAssertEqual(pop9!, job1, "pop9 is wrong")
        XCTAssertEqual(pop10!, job4, "pop10 is wrong")
    }
}
