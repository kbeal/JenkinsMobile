//
//  KDBMasterBuildListTableViewController.h
//  JenkinsMobile
//
//  Created by Kyle on 6/9/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Job.h"
#import "KDBMasterViewControllerDelegate.h"
#import "KDBDetailViewControllerDelegate.h"

@interface KDBMasterBuildListTableViewController : UITableViewController <KDBMasterViewControllerDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) Job *job;
@property (weak, nonatomic) id<KDBDetailViewControllerDelegate> buildDetailDelegate;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
