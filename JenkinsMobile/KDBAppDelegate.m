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
//#import "JenkinsMobile-Swift.h"
#import "Constants.h"

@implementation KDBAppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
//    [notificationCenter addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:self.masterMOC];
//    [self mainMOC];
    
    //SyncManager *mgr = [SyncManager sharedInstance];
    
    //NSURL *jenkinsURL = [NSURL URLWithString:@"https://jenkins.qa.ubuntu.com"];
    //NSURL *jenkinsURL = [NSURL URLWithString:@"http://ci.thermofisher.com/jenkins"];
    //NSURL *jenkinsURL = [NSURL URLWithString:@"https://snowman:8443/jenkins/"];
    
    //JenkinsInstance *ji = [self createJenkinsInstanceWithURL:jenkinsURL];
    //mgr.currentJenkinsInstance = ji;
    //mgr.requestHandler = [[KDBJenkinsRequestHandler alloc] init];
//    mgr.masterMOC = self.masterMOC;
//    mgr.mainMOC = self.mainMOC;
    
    //[mgr syncJenkinsInstance:ji];
    
    /*
    SWRevealViewController *revealViewController = (SWRevealViewController *)self.window.rootViewController;
    UISplitViewController *splitViewController = (UISplitViewController *)revealViewController.frontViewController;
    KDBMasterViewController *masterVC = splitViewController.viewControllers[0];
    UINavigationController *viewsNavController = masterVC.viewControllers[0];
    UINavigationController *allJobsNavController = masterVC.viewControllers[1];
    UINavigationController *currentBuildsNavController = masterVC.viewControllers[2];
    KDBViewsTableViewController *viewsTVC = (KDBViewsTableViewController *)viewsNavController.topViewController;
    KDBJobsTableViewController *jobsTVC = (KDBJobsTableViewController *)allJobsNavController.topViewController;
    KDBBuildsTableViewController *buildsTVC = (KDBBuildsTableViewController *)currentBuildsNavController.topViewController;
    viewsTVC.managedObjectContext = self.mainMOC;
    jobsTVC.managedObjectContext = self.mainMOC;
    buildsTVC.managedObjectContext = self.mainMOC;*/
    
    /*
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    KDBMasterViewController *masterVC = splitViewController.viewControllers[0];
    UINavigationController *viewsNavController = masterVC.viewControllers[0];
    UINavigationController *allJobsNavController = masterVC.viewControllers[1];
    UINavigationController *currentBuildsNavController = masterVC.viewControllers[2];
    KDBViewsTableViewController *viewsTVC = (KDBViewsTableViewController *)viewsNavController.topViewController;
    KDBJobsTableViewController *jobsTVC = (KDBJobsTableViewController *)allJobsNavController.topViewController;
    KDBBuildsTableViewController *buildsTVC = (KDBBuildsTableViewController *)currentBuildsNavController.topViewController;
    viewsTVC.managedObjectContext = self.mainMOC;
    jobsTVC.managedObjectContext = self.mainMOC;
    buildsTVC.managedObjectContext = self.mainMOC;
     */
    
    /*
    KDBJenkinsRequestHandler *handler = [[KDBJenkinsRequestHandler alloc] initWithJenkinsInstance:jinstance];
    handler.managedObjectContext = self.masterMOC;
    [handler importAllViews];
     */
    
    /*
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
    }*/
    
    return YES;
}

//- (JenkinsInstance *) createJenkinsInstanceWithURL:(NSURL *) url
//{
//    NSArray *jenkinskeys = [NSArray arrayWithObjects:JenkinsInstanceNameKey,JenkinsInstanceURLKey,JenkinsInstanceCurrentKey,JenkinsInstanceEnabledKey,JenkinsInstanceUsernameKey, nil];
//    NSArray *jenkinsvalues = [NSArray arrayWithObjects:@"TestInstance",[url absoluteString],[NSNumber numberWithBool:YES],[NSNumber numberWithBool:YES],@"jenkinsadmin", nil];
//    NSDictionary *jenkins = [NSDictionary dictionaryWithObjects:jenkinsvalues forKeys:jenkinskeys];
//    
//    JenkinsInstance *jinstance = [JenkinsInstance fetchJenkinsInstanceWithURL:[url absoluteString] fromManagedObjectContext:self.mainMOC];
//    if (jinstance == nil) {
//        jinstance = [JenkinsInstance createJenkinsInstanceWithValues:jenkins inManagedObjectContext:self.mainMOC];
//        jinstance.password = @"changeme";
//        jinstance.shouldAuthenticate = [NSNumber numberWithBool:YES];
//        jinstance.allowInvalidSSLCertificate = [NSNumber numberWithBool:YES];
//        [self saveMainContext];
//    }
//    return jinstance;
//}

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

//- (void) contextChanged: (NSNotification *) notification
//{
//    // Only interested in merging from master into main.
//    if ([notification object] != self.masterMOC) return;
//    
//    [_mainMOC performBlock:^{
//        [_mainMOC mergeChangesFromContextDidSaveNotification:notification];
//    }];
//}

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
    // TODO: update for datamanager
    //[self saveContext];
}

@end
