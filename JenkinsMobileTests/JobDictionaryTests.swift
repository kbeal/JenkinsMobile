//
//  JobDictionaryTests.swift
//  JenkinsMobile
//
//  Tests our custom NSDictionary implementation that's called JobDictionary
//
//  Created by Kyle Beal on 11/16/15.
//  Copyright © 2015 Kyle Beal. All rights reserved.
//

import Foundation
import XCTest
import JenkinsMobile

class JobDictionaryTests: XCTestCase {
    
    func testInit() {
        let job1: JobDictionary? = JobDictionary(dictionary: NSDictionary(objects: ["blue","www.google.com/job/Job1/"], forKeys: [JobColorKey as NSCopying,JobURLKey as NSCopying]))
        let job2: JobDictionary? = JobDictionary(dictionary: NSDictionary(objects: ["Job1","blue","www.google.com/job/Job1/"], forKeys: [JobNameKey as NSCopying,JobColorKey as NSCopying,JobURLKey as NSCopying]))

        XCTAssertNil(job1)
        XCTAssertNotNil(job2)
    }
    func testSubScript() {
        let job1: JobDictionary? = JobDictionary(dictionary: NSDictionary(objects: ["Job1","blue","www.google.com/job/Job1/"], forKeys: [JobNameKey as NSCopying,JobColorKey as NSCopying,JobURLKey as NSCopying]))
        XCTAssertEqual((job1![JobNameKey as AnyObject] as! String), "Job1")
    }
    
    func testIsEqual() {
        let job1: JobDictionary? = JobDictionary(dictionary: NSDictionary(objects: ["Job1","blue","www.google.com/job/Job1/"], forKeys: [JobNameKey as NSCopying,JobColorKey as NSCopying,JobURLKey as NSCopying]))
        let job2: JobDictionary? = JobDictionary(dictionary: NSDictionary(objects: ["Job1","blue","www.google.com/job/Job2/"], forKeys: [JobNameKey as NSCopying,JobColorKey as NSCopying,JobURLKey as NSCopying]))
        let job3: JobDictionary? = JobDictionary(dictionary: NSDictionary(objects: ["Job3","blue","www.google.com/job/Job3/"], forKeys: [JobNameKey as NSCopying,JobColorKey as NSCopying,JobURLKey as NSCopying]))
        
        XCTAssertEqual(job1, job2)
        XCTAssertNotEqual(job1, job3)
    }
    
    func testHash() {
        let job1: JobDictionary? = JobDictionary(dictionary: NSDictionary(objects: ["Job1","blue","www.google.com/job/Job1/"], forKeys: [JobNameKey as NSCopying,JobColorKey as NSCopying,JobURLKey as NSCopying]))
        let job2: JobDictionary? = JobDictionary(dictionary: NSDictionary(objects: ["Job1","blue","www.google.com/job/Job2/"], forKeys: [JobNameKey as NSCopying,JobColorKey as NSCopying,JobURLKey as NSCopying]))
        
        XCTAssertEqual(job1?.hash, job2?.hash)
    }
    
    func testValueForKey() {
        let job1: JobDictionary? = JobDictionary(dictionary: NSDictionary(objects: ["Job1","blue","www.google.com/job/Job1/"], forKeys: [JobNameKey as NSCopying,JobColorKey as NSCopying,JobURLKey as NSCopying]))
        XCTAssertEqual((job1!.value(forKey: JobNameKey) as! String), "Job1")
    }
}
