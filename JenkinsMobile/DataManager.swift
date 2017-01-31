//
//  DataManager.swift
//  JenkinsMobile
//
//  Created by Kyle Beal on 9/14/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

import Foundation

open class DataManager: NSObject {
    open static let sharedInstance = DataManager()
    
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(DataManager.contextChanged(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: self.masterMOC)
    }
    
    open lazy var masterMOC: NSManagedObjectContext = {
        let runningTests = NSClassFromString("XCTestCase") != nil
        if runningTests {
            return self.testMOC
        }
        
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            print("Failed to retrieve Persistent Store Coordinator")
            abort()
        }
        var moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.persistentStoreCoordinator = coordinator
        return moc
        }()
        
    open lazy var mainMOC: NSManagedObjectContext = {
        var moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.undoManager = UndoManager()
        moc.parent = self.masterMOC
        return moc
        }()
    
    // managed object context to be used by unit tests. Uses in memory data store.
    lazy var testMOC: NSManagedObjectContext = {
        let model = NSManagedObjectModel.mergedModel(from: [Bundle.main])
        let coord = NSPersistentStoreCoordinator(managedObjectModel: model!)
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coord.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            //dict[NSUnderlyingErrorKey] = error as! NSError
            let wrappedError = NSError(domain: "com.kylebeal.jenkinsmobile.test.data", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.persistentStoreCoordinator = coord
        moc.undoManager = UndoManager()
        return moc
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("JenkinsMobile.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
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
        let modelURL = Bundle.main.url(forResource: "JenkinsMobile", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.kylebeal.OOBMasterDetail" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] 
    
    }()
    
    func contextChanged(_ notification: Notification) {
        let notificationObject: NSManagedObjectContext = notification.object as! NSManagedObjectContext
        if (notificationObject != self.masterMOC) { return }
        
        self.mainMOC.perform({
            self.mainMOC.mergeChanges(fromContextDidSave: notification)
        })
    }
    
    // takes an NSManagedObject and if it isn't already on a background thread
    // ie. on the main queue NSManagedObjectContext
    // looks it up by NSManagedObjectID from the background NSManagedObjectContext
    // must be called from a background thread
    open func ensureObjectOnBackgroundThread(_ obj: NSManagedObject) -> NSManagedObject? {
        var bgobj: NSManagedObject?
        if obj.managedObjectContext?.concurrencyType == NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType {
            // try to retrieve the object from the background context
            self.masterMOC.performAndWait({
                do {
                    try bgobj = self.masterMOC.existingObject(with: obj.objectID)
                } catch {
                    print("Error retrieving object from background context.")
                }
            })
        } else {
            bgobj = obj
        }
        return bgobj
    }
    
    // saves the main managedObjectContext and then also updates the masterManagedObjectContext
    open func saveMainContext() {
        self.saveContext(self.mainMOC)
        self.masterMOC.perform({
            self.saveContext(self.masterMOC)
        })
    }
    
    open func saveContext (_ moc: NSManagedObjectContext) {
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
