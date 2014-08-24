//
//  KDBJobDetailTableViewController.h
//  JenkinsMobile
//
//  Created by Kyle on 8/3/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SpriteKit/SpriteKit.h>
#import "Job.h"
#import "Build.h"

@interface KDBJobDetailTableViewController : UITableViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) Job *job;
//@property (strong, nonatomic) Build *lastBuild;
@property (strong, nonatomic) NSTimer *lastBuildProgressUpdateTimer;
// the client and jenkin's server clocks will often not be in sync;
// if a build's start time is "in the future", use the current time as the start time
@property (assign, nonatomic) double lastBuildStartTime;
// true if job is currently building (self.job.lastbuild.building=true)
@property (assign, nonatomic) BOOL isBuilding;

@property (weak, nonatomic) IBOutlet SKView *statusBallContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *healthIcon;
@property (weak, nonatomic) IBOutlet UITextView *jobURLTextView;
@property (weak, nonatomic) IBOutlet UITextView *jobDescriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *jenkinsNameJobDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *currentBuildProgressView;

@property (assign, nonatomic) NSInteger lastBuildRowIndex;
@property (assign, nonatomic) NSInteger lastStableBuildRowIndex;
@property (assign, nonatomic) NSInteger lastSuccessfulBuildRowIndex;
@property (assign, nonatomic) NSInteger lastFailedBuildRowIndex;
@property (assign, nonatomic) NSInteger lastUnstableBuildRowIndex;
@property (assign, nonatomic) NSInteger lastUnsuccessfulBuildRowIndex;
@property (assign, nonatomic) NSInteger allBuildsRowIndex;

@property (assign, nonatomic) NSInteger permalinksSectionIndex;
@property (assign, nonatomic) NSInteger upstreamProjectsSectionIndex;
@property (assign, nonatomic) NSInteger downstreamProjectsSectionIndex;

-(IBAction)refresh:(id)sender;

@end