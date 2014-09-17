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

    let instance = SyncManager.sharedInstance
    
    func testSharedInstance() {
        XCTAssertNotNil(instance, "shared instance is nil")
    }
    
    func testJobDetailResponseReceived() {
        let notification = NSNotification(name: JobDetailResponseReceivedNotification, object: self)
        instance.jobDetailResponseReceived(notification)
        XCTAssert(true, "true")
    }
}
