//
//  KDBMasterViewController.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KDBViewPickerViewController.h"
#import "Job.h"

@class KDBDetailViewController;

@interface KDBMasterViewController : UITableViewController <ViewPickerDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) KDBDetailViewController *detailViewController;

@property (nonatomic, strong) KDBViewPickerViewController *viewPicker;
@property (nonatomic, strong) UIPopoverController *viewPickerPopover;

-(IBAction)chooseViewButtonTapped:(id)sender;

@end
