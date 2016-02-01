//
//  BuildProgress.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 2/23/16.
//  Copyright © 2016 Kyle Beal. All rights reserved.
//

import Foundation

public class BuildProgress: NSProgress {
    
    var buildToWatch: Build!
    var dataMgr: DataManager = DataManager.sharedInstance
    
    public init?(build: Build) {
        super.init(parent: nil, userInfo: nil)
        let bgbuild: Build? = dataMgr.ensureObjectOnBackgroundThread(build) as? Build
        if bgbuild == nil { return nil }
        self.buildToWatch = bgbuild
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BuildProgress.handleDataModelChange(_:)), name: NSManagedObjectContextDidSaveNotification, object: dataMgr.masterMOC)
    }
    
    func handleDataModelChange(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let updatedObjects = userInfo[NSUpdatedObjectsKey] as! NSSet as! Set<NSManagedObject>
            let insertedObjects = userInfo[NSInsertedObjectsKey] as! NSSet as! Set<NSManagedObject>
            for obj: NSManagedObject in updatedObjects {
                if obj.objectID == self.buildToWatch.objectID {
                    self.updateProgress()
                }
            }
            for obj: NSManagedObject in insertedObjects {
                if obj.objectID == self.buildToWatch.objectID {
                    self.updateProgress()
                }
            }
        }
    }
    
    func updateProgress() {
        self.totalUnitCount = self.buildToWatch.estimatedDuration.longLongValue
        if let executor: NSDictionary = self.buildToWatch.executor as? NSDictionary {
            if let progress: Int = executor[BuildExecutorProgressKey] as? Int {
                let duration: Double = self.buildToWatch.estimatedDuration.doubleValue * (Double(progress) / 100)
                self.completedUnitCount = Int64(duration)
            }
        } else {
            self.completedUnitCount = self.totalUnitCount
        }
        
    }
}