//
//  KDBAppDelegate.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBAppDelegate.h"

#import "KDBMasterViewController.h"
#import "KDBJobDetailViewController.h"
#import "JenkinsInstance.h"
#import "KDBJenkinsRequestHandler.h"
#import "JenkinsMobile-Swift.h"

@implementation KDBAppDelegate

@synthesize masterMOC = _masterMOC;
@synthesize mainMOC = _mainMOC;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:self.masterMOC];
    [self mainMOC];
    
    JenkinsInstance *jinstance = [self createJenkinsInstance];
    SyncManager *mgr = [SyncManager sharedInstance];
    mgr.requestHandler = [[KDBJenkinsRequestHandler alloc] init];
    [mgr setCurrentJenkinsInstance:jinstance];
    mgr.masterMOC = self.masterMOC;
    mgr.mainMOC = self.mainMOC;
    
    /*
    KDBJenkinsRequestHandler *handler = [[KDBJenkinsRequestHandler alloc] initWithJenkinsInstance:jinstance];
    handler.managedObjectContext = self.masterMOC;
    [handler importAllViews];
     */
    
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
        
        UINavigationController *masterNavigationController = splitViewController.viewControllers[0];
        KDBMasterViewController *masterController = (KDBMasterViewController *)masterNavigationController.topViewController;
        masterController.managedObjectContext = _mainMOC;
        KDBJobDetailViewController *detailController = (KDBJobDetailViewController *)navigationController.topViewController;
        detailController.managedObjectContext = _mainMOC;
        
    } else {
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        KDBMasterViewController *controller = (KDBMasterViewController *)navigationController.topViewController;
        controller.managedObjectContext = _mainMOC;
    }
    
    return YES;
}

- (JenkinsInstance *) createJenkinsInstance
{
    NSString *jenkinsURL = @"https://jenkins.qa.ubuntu.com";
    NSArray *jenkinskeys = [NSArray arrayWithObjects:@"name",@"url",@"current", nil];
    NSArray *jenkinsvalues = [NSArray arrayWithObjects:@"TestInstance",jenkinsURL,[NSNumber numberWithBool:YES], nil];
    NSDictionary *jenkins = [NSDictionary dictionaryWithObjects:jenkinsvalues forKeys:jenkinskeys];
    
    JenkinsInstance *jinstance = [JenkinsInstance fetchJenkinsInstanceWithURL:jenkinsURL fromManagedObjectContext:self.mainMOC];
    if (jinstance == nil) {
        jinstance = [JenkinsInstance createJenkinsInstanceWithValues:jenkins inManagedObjectContext:self.mainMOC];
        [self saveMainContext];
    }
    
    return jinstance;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder
{
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder
{
    return YES;
}

- (void) contextChanged: (NSNotification *) notification
{
    // Only interested in merging from master into main.
    if ([notification object] != self.masterMOC) return;
    
    [_mainMOC performBlock:^{
        [_mainMOC mergeChangesFromContextDidSaveNotification:notification];
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.masterMOC;
    if (managedObjectContext != nil) {
        [self.masterMOC performBlock:^{
            NSError *error = nil;
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
                 // Replace this implementation with code to handle the error appropriately.
                 // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }];
    }
}

- (void)saveMainContext
{
    NSManagedObjectContext *managedObjectContext = self.mainMOC;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        [self saveContext];
    }
}

#pragma mark - Core Data stack

// Returns the master managed object context for the application.
// This context writes to disk in a background thread
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)masterMOC
{
    @synchronized(_masterMOC) {
        if (_masterMOC != nil) {
            return _masterMOC;
        }
        
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil) {
            _masterMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [_masterMOC setPersistentStoreCoordinator:coordinator];
        }
        return _masterMOC;
    }
}

// Returns the main managed object context for the application.
// This context is for UI use as it exists on the main thread
// If the context doesn't already exist, it is created and bound to the master managed object context
- (NSManagedObjectContext *)mainMOC
{
    @synchronized(_mainMOC) {
        if (_mainMOC != nil) {
            return _mainMOC;
        }
        
        _mainMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainMOC setUndoManager:nil];
        [_mainMOC setParentContext:_masterMOC];
        
        return _mainMOC;
    }
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"JenkinsMobile" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"JenkinsMobile.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
