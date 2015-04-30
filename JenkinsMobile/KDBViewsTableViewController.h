//
//  KDBViewsTableViewController.h
//  JenkinsMobile
//
//  Created by Kyle on 4/22/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "View+More.h"

@interface KDBViewsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end
