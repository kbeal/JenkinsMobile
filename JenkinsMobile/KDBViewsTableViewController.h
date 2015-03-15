//
//  KDBViewsTableViewController.h
//  JenkinsMobile
//
//  Created by Kyle on 3/14/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KDBViewsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIDataSourceModelAssociation>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
