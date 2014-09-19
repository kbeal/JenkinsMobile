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
    }
    
    func testSharedInstance() {
        XCTAssertNotNil(mgr, "shared instance is nil")
    }
    
    func testJobDetailResponseReceived() {
        let userInfo: [String: String] = [JobNameKey: "Job1"]
        let notification = NSNotification(name: JobDetailResponseReceivedNotification, object: self, userInfo: userInfo)
        
        mgr.jobDetailResponseReceived(notification)
        
        let fetchreq = NSFetchRequest()
        fetchreq.entity = NSEntityDescription.entityForName("Job", inManagedObjectContext: context!)
        fetchreq.predicate = NSPredicate(format: "name = %@", "Job1")
        fetchreq.includesPropertyValues = false
        
        let jobs = context?.executeFetchRequest(fetchreq, error: nil)
        
        XCTAssertEqual(jobs!.count, 1, "jobs count is wrong. Should be 1 got: \(jobs!.count) instead")
    }
}
