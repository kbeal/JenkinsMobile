//
//  BuildDictionaryTests.swift
//  JenkinsMobile
//
//  Tests our custom NSDictionary implementation that's called BuildDictionary
//
//  Created by Kyle Beal on 3/2/15.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import Foundation
import XCTest
import JenkinsMobile

class BuildDictionaryTests: XCTestCase {
    
    func testInit() {
        let build1: BuildDictionary? = BuildDictionary(dictionary: NSDictionary(objects: ["SUCCESS","www.google.com/job/Job1/1/"], forKeys: [BuildResultKey as NSCopying,BuildURLKey as NSCopying]))
        let build2: BuildDictionary? = BuildDictionary(dictionary: NSDictionary(objects: [1,"SUCCESS","www.google.com/job/Job1/1/"], forKeys: [BuildNumberKey as NSCopying,BuildResultKey as NSCopying,BuildURLKey as NSCopying]))
        
        XCTAssertNil(build1)
        XCTAssertNotNil(build2)
    }
    func testSubScript() {
        let build1: BuildDictionary? = BuildDictionary(dictionary: NSDictionary(objects: [1,"SUCCESS","www.google.com/job/Job1/1/"], forKeys: [BuildNumberKey as NSCopying,BuildResultKey as NSCopying,BuildURLKey as NSCopying]))
        XCTAssertEqual(build1![BuildNumberKey as AnyObject] as? Int, 1)
    }
    
    func testIsEqual() {
        let build1: BuildDictionary? = BuildDictionary(dictionary: NSDictionary(objects: [1,"SUCCESS","www.google.com/job/Job1/1/"], forKeys: [BuildNumberKey as NSCopying,BuildResultKey as NSCopying,BuildURLKey as NSCopying]))
        let build2: BuildDictionary? = BuildDictionary(dictionary: NSDictionary(objects: [1,"SUCCESS","www.google.com/job/Job2/1/"], forKeys: [BuildNumberKey as NSCopying,BuildResultKey as NSCopying,BuildURLKey as NSCopying]))
        let build3: BuildDictionary? = BuildDictionary(dictionary: NSDictionary(objects: [2,"SUCCESS","www.google.com/job/Job3/2/"], forKeys: [BuildNumberKey as NSCopying,BuildResultKey as NSCopying,BuildURLKey as NSCopying]))
        
        XCTAssertEqual(build1, build2)
        XCTAssertNotEqual(build1, build3)
    }
    
    func testHash() {
        let build1: BuildDictionary? = BuildDictionary(dictionary: NSDictionary(objects: [1,"SUCCESS","www.google.com/job/Job1/1/"], forKeys: [BuildNumberKey as NSCopying,BuildResultKey as NSCopying,BuildURLKey as NSCopying]))
        let build2: BuildDictionary? = BuildDictionary(dictionary: NSDictionary(objects: [1,"SUCCESS","www.google.com/job/Job2/1/"], forKeys: [BuildNumberKey as NSCopying,BuildResultKey as NSCopying,BuildURLKey as NSCopying]))
        
        XCTAssertEqual(build1?.hash, build2?.hash)
    }
    
    func testValueForKey() {
        let build1: BuildDictionary? = BuildDictionary(dictionary: NSDictionary(objects: [1,"SUCCESS","www.google.com/job/Job1/1/"], forKeys: [BuildNumberKey as NSCopying,BuildResultKey as NSCopying,BuildURLKey as NSCopying]))
        XCTAssertEqual((build1!.value(forKey: BuildNumberKey) as! Int), 1)
    }
}
