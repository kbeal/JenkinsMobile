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
    
    func testUniqueQueueIterPop() {
        
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
}