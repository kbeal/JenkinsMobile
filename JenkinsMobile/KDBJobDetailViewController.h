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
@property (strong, nonatomic) NSArray *downstreamProjectButtons;
@property (strong, nonatomic) NSArray *upstreamProjectButtons;

@property (weak, nonatomic) IBOutlet UIButton *lastBuildButton;
@property (weak, nonatomic) IBOutlet UIButton *lastSuccessfullBuildButton;
@property (weak, nonatomic) IBOutlet UIButton *lastStableBuildButton;
@property (weak, nonatomic) IBOutlet UIButton *lastUnSuccessfullBuildButton;
@property (weak, nonatomic) IBOutlet UIButton *lastUnStableBuildButton;
@property (weak, nonatomic) IBOutlet UIButton *lastTestResultButton;

@property (weak, nonatomic) IBOutlet UIButton *downstreamProjectButton1;
@property (weak, nonatomic) IBOutlet UIButton *downstreamProjectButton2;
@property (weak, nonatomic) IBOutlet UIButton *downstreamProjectButton3;
@property (weak, nonatomic) IBOutlet UIButton *downstreamProjectButton4;
@property (weak, nonatomic) IBOutlet UIButton *downstreamProjectButton5;

@property (weak, nonatomic) IBOutlet UIButton *upstreamProjectButton1;
@property (weak, nonatomic) IBOutlet UIButton *upstreamProjectButton2;
@property (weak, nonatomic) IBOutlet UIButton *upstreamProjectButton3;
@property (weak, nonatomic) IBOutlet UIButton *upstreamProjectButton4;
@property (weak, nonatomic) IBOutlet UIButton *upstreamProjectButton5;

@end
