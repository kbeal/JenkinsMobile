//
//  DataManager.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 9/14/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

import Foundation

public class DataManager: NSObject {
    public static let sharedInstance = DataManager()
    
    public lazy var masterMOC: NSManagedObjectContext = {
        let runningTests = NSClassFromString("XCTestCase") != nil
        if runningTests {
            return self.testMOC
        }
        
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            print("Failed to retrieve Persistent Store Coordinator")
            abort()
        }
        var moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        moc.persistentStoreCoordinator = coordinator
        return moc
        }()
        
    public lazy var mainMOC: NSManagedObjectContext = {
        var moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        moc.undoManager = NSUndoManager()
        moc.parentContext = self.masterMOC
        return moc
        }()
    
    // managed object context to be used by unit tests. Uses in memory data store.
    lazy var testMOC: NSManagedObjectContext = {
        let model = NSManagedObjectModel.mergedModelFromBundles([NSBundle.mainBundle()])
        let coord = NSPersistentStoreCoordinator(managedObjectModel: model!)
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coord.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            //dict[NSUnderlyingErrorKey] = error as! NSError
            let wrappedError = NSError(domain: "com.kylebeal.jenkinsmobile.test.data", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        let moc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        moc.persistentStoreCoordinator = coord
        moc.undoManager = NSUndoManager()
        return moc
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("JenkinsMobile.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            //dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "com.kylebeal.jenkinsmobile.data", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        return coordinator
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("JenkinsMobile", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.kylebeal.OOBMasterDetail" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] 
    
    }()
    
    //- (void) contextChanged: (NSNotification *) notification
    //{
    //    // Only interested in merging from master into main.
    //    if ([notification object] != self.masterMOC) return;
    //
    //    [_mainMOC performBlock:^{
    //        [_mainMOC mergeChangesFromContextDidSaveNotification:notification];
    //    }];
    //}
    
    // takes an NSManagedObject and if it isn't already on a background thread
    // ie. on the main queue NSManagedObjectContext
    // looks it up by NSManagedObjectID from the background NSManagedObjectContext
    // must be called from a background thread
    public func ensureObjectOnBackgroundThread(obj: NSManagedObject) -> NSManagedObject? {
        var bgobj: NSManagedObject?
        if obj.managedObjectContext?.concurrencyType == NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType {
//            do {
//                // try to get the object's permanent object ID. If the object exists on the main queue context only
//                // which means it hasn't been persisted to disk yet, it's objectID is temporary and won't return an object
//                // from the master context.
//                // obtainPermanentIDsForObjects forces a write to disk in order to determine/obtain the permanent object ID
//                try obj.managedObjectContext?.obtainPermanentIDsForObjects([obj])
//            } catch {
//                print("Error retrieving permanent ID for object")
//            }

            do {
                try bgobj = self.masterMOC.existingObjectWithID(obj.objectID)
            } catch {
                print("Error retrieving object from background context.")
            }
        }
        return bgobj
    }
    
    // saves the main managedObjectContext and then also updates the masterManagedObjectContext
    public func saveMainContext() {
        self.saveContext(self.mainMOC)
        self.masterMOC.performBlock({
            self.saveContext(self.masterMOC)
        })
    }
    
    public func saveContext (moc: NSManagedObjectContext) {
        if moc.hasChanges {
            do {
                try moc.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}