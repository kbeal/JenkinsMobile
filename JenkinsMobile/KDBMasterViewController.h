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

@class KDBJobDetailViewController;

@interface KDBMasterViewController : UITableViewController <ViewPickerDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) KDBJobDetailViewController *jobDetailViewController;

@property (nonatomic, strong) KDBViewPickerViewController *viewPicker;
@property (nonatomic, strong) UIPopoverController *viewPickerPopover;

-(IBAction)chooseViewButtonTapped:(id)sender;

@end
