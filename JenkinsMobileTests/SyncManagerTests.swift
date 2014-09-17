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
    func testSharedInstance() {
        let instance = SyncManager.sharedInstance
        XCTAssertNotNil(instance, "shared instance is nil")
    }
}
