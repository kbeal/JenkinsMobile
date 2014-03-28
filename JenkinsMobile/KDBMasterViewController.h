//
//  KDBMasterViewController.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KDBDetailViewController;

@interface KDBMasterViewController : UITableViewController

@property (strong, nonatomic) NSArray *jenkinsJobs;

@property (strong, nonatomic) KDBDetailViewController *detailViewController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
