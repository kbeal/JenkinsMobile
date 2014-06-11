//
//  KDBDetailViewController.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Job.h"
#import "Build.h"
#import "KDBBuildsTableViewController.h"
#import "KDBTestResultsViewController.h"

@interface KDBJobDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) Job *job;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) KDBBuildsTableViewController *buildsVC;
@property (strong, nonatomic) KDBTestResultsViewController *testResultsVC;
@property (weak, nonatomic) IBOutlet UILabel *repositoryURLLabel;
@property (weak, nonatomic) IBOutlet UILabel *repositoryBranchLabel;

@end
