//
//  KDBBuildsTableViewController.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 5/8/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Job.h"
#import "Build+More.h"
#import "JenkinsMobile-Swift.h"

@interface KDBBuildsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) Job *job;
@property (strong, nonatomic) SyncManager *syncMgr;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;

@end
