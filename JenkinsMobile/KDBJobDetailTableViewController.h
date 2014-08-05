//
//  KDBJobDetailTableViewController.h
//  JenkinsMobile
//
//  Created by Kyle on 8/3/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Job.h"

@interface KDBJobDetailTableViewController : UITableViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) Job *job;

@end
