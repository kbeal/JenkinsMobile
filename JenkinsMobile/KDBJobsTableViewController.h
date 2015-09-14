//
//  KDBJobsTableViewController.h
//  JenkinsMobile
//
//  Created by Kyle on 5/31/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JenkinsMobile-Swift.h"
#import "JenkinsInstance+More.h"
#import "Job+More.h"
#import "View+More.h"

@interface KDBJobsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) SyncManager *syncMgr;
@property (strong, nonatomic) View *parentView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;

@end
