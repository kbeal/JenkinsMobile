//
//  KDBBuildsTableViewController.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 5/8/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Job.h"
#import "Build.h"

@interface KDBBuildsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) Job *job;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
