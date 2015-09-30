//
//  KDBViewsTableViewController.h
//  JenkinsMobile
//
//  Created by Kyle on 4/22/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "View+More.h"

#import "JenkinsInstance+More.h"
#import "KDBJobsTableViewController.h"
#import "JenkinsMobile-Swift.h"
@interface KDBViewsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) SyncManager *syncMgr;
@property (strong, nonatomic) View *parentView;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sidebarButton;

@end
