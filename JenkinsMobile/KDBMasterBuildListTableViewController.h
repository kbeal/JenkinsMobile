//
//  KDBMasterBuildListTableViewController.h
//  JenkinsMobile
//
//  Created by Kyle on 6/9/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Job.h"
#import "KDBBuildDetailViewController.h"

@interface KDBMasterBuildListTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) Job *job;
@property (strong, nonatomic) KDBBuildDetailViewController *buildDetailVC;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
