//
//  KDBDetailViewController.h
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
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
@property (strong, nonatomic) NSArray *downstreamProjectStatusBalls;
@property (strong, nonatomic) NSArray *upstreamProjectStatusBalls;

@property (weak, nonatomic) IBOutlet UIButton *lastBuildButton;
@property (weak, nonatomic) IBOutlet UIButton *lastSuccessfulBuildButton;
@property (weak, nonatomic) IBOutlet UIButton *lastStableBuildButton;
@property (weak, nonatomic) IBOutlet UIButton *lastUnSuccessfulBuildButton;
@property (weak, nonatomic) IBOutlet UIButton *lastUnStableBuildButton;

@property (weak, nonatomic) IBOutlet UIButton *downstreamProjectButton1;
@property (weak, nonatomic) IBOutlet UIButton *downstreamProjectButton2;
@property (weak, nonatomic) IBOutlet UIButton *downstreamProjectButton3;
@property (weak, nonatomic) IBOutlet UIButton *downstreamProjectButton4;
@property (weak, nonatomic) IBOutlet UIButton *downstreamProjectButton5;

@property (weak, nonatomic) IBOutlet SKView *downstreamProjectStatusBall1;
@property (weak, nonatomic) IBOutlet SKView *downstreamProjectStatusBall2;
@property (weak, nonatomic) IBOutlet SKView *downstreamProjectStatusBall3;
@property (weak, nonatomic) IBOutlet SKView *downstreamProjectStatusBall4;
@property (weak, nonatomic) IBOutlet SKView *downstreamProjectStatusBall5;

@property (weak, nonatomic) IBOutlet UIButton *upstreamProjectButton1;
@property (weak, nonatomic) IBOutlet UIButton *upstreamProjectButton2;
@property (weak, nonatomic) IBOutlet UIButton *upstreamProjectButton3;
@property (weak, nonatomic) IBOutlet UIButton *upstreamProjectButton4;
@property (weak, nonatomic) IBOutlet UIButton *upstreamProjectButton5;

@property (weak, nonatomic) IBOutlet SKView *upstreamProjectStatusBall1;
@property (weak, nonatomic) IBOutlet SKView *upstreamProjectStatusBall2;
@property (weak, nonatomic) IBOutlet SKView *upstreamProjectStatusBall3;
@property (weak, nonatomic) IBOutlet SKView *upstreamProjectStatusBall4;
@property (weak, nonatomic) IBOutlet SKView *upstreamProjectStatusBall5;

@property (weak, nonatomic) IBOutlet UIImageView *healthIcon;

@property (weak, nonatomic) IBOutlet SKView *statusBallContainerView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *jobViewSwitcher;

- (IBAction)jobViewSwitcherTapped:(id)sender;

@end
