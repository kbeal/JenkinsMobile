//
//  KDBDetailViewController.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBJobDetailViewController.h"
#import "KDBBuildDetailViewController.h"
#import "KDBRelatedProjectsViewController.h"
#import "KDBTestResultsViewController.h"
#import "UIImage+animatedGIF.h"

@interface KDBJobDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation KDBJobDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
        self.upstreamProjectButtons =
    [NSArray arrayWithObjects:self.upstreamProjectButton1,self.upstreamProjectButton2,self.upstreamProjectButton3,self.upstreamProjectButton4,self.upstreamProjectButton5, nil];
        self.downstreamProjectButtons =
    [NSArray arrayWithObjects:self.downstreamProjectButton1,self.downstreamProjectButton2,self.downstreamProjectButton3,self.downstreamProjectButton4,self.downstreamProjectButton5, nil];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

#pragma mark - Managing the detail item
- (void)setJob:(Job *)newJob
{
    if (_job != newJob) {
        _job = newJob;
        
        // Update the view.
        [self configureView];
        
        // Update the builds table view
        [self.buildsVC setJob:newJob];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)newManagedObjectContext
{
    if (_managedObjectContext != newManagedObjectContext) {
        _managedObjectContext = newManagedObjectContext;
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.
    if (self.job) {
        self.navigationItem.title = self.job.name;
        [self populateBuildButtons];
        [self populateRelatedProjects];
        [self updateJobStatusIcons];
    }
}

- (void) updateJobStatusIcons
{
    //NSString *statusIconFileName = [NSString stringWithFormat:@"%@", self.job.color];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"blue@2x_anime" withExtension:@"gif"];
    
    self.statusIcon.image = [UIImage animatedImageWithAnimatedGIFURL:url];
    
    //NSString *healthIconFileName = [(NSDictionary *)((NSArray *)self.job.healthReport)[0] objectForKey:@"iconURL"];
    //self.statusIcon.image = [UIImage imageNamed:statusIconFileName];
    //self.healthIcon.image = [UIImage imageNamed:healthIconFileName];
}

- (void) populateRelatedProjects
{
    [self clearRelatedProjectButtons];
    [self populateRelatedProjectsForDownstreamProjects:YES];
    [self populateRelatedProjectsForDownstreamProjects:NO];
}

- (void) clearRelatedProjectButtons
{
    [self.upstreamProjectButton1 setTitle:@"" forState:UIControlStateNormal];
    [self.upstreamProjectButton2 setTitle:@"" forState:UIControlStateNormal];
    [self.upstreamProjectButton3 setTitle:@"" forState:UIControlStateNormal];
    [self.upstreamProjectButton4 setTitle:@"" forState:UIControlStateNormal];
    [self.upstreamProjectButton5 setTitle:@"" forState:UIControlStateNormal];

    [self.downstreamProjectButton1 setTitle:@"" forState:UIControlStateNormal];
    [self.downstreamProjectButton2 setTitle:@"" forState:UIControlStateNormal];
    [self.downstreamProjectButton3 setTitle:@"" forState:UIControlStateNormal];
    [self.downstreamProjectButton4 setTitle:@"" forState:UIControlStateNormal];
    [self.downstreamProjectButton5 setTitle:@"" forState:UIControlStateNormal];
}

- (void) populateRelatedProjectsForDownstreamProjects:(BOOL) downstreamProject
{
    UIButton *buttonToUpdate;
    NSString *projectName;
    NSDictionary *project;
    NSArray *buttonArray = downstreamProject ? self.downstreamProjectButtons : self.upstreamProjectButtons;
    NSArray *relatedProjects = downstreamProject ? self.job.downstreamProjects : self.job.upstreamProjects;
    
    for (int i=0; i<[relatedProjects count]; i++) {
        if (i<5) {
            buttonToUpdate = [buttonArray objectAtIndex:i];
            project = (NSDictionary *)[relatedProjects objectAtIndex:i];
            projectName = [project objectForKey:@"name"];
            
            if ([relatedProjects count]>5 && i==4) {
                projectName = [NSString stringWithFormat:@"%@%d%@",@"+",[relatedProjects count]-4,@" More"];
            }
            
            [buttonToUpdate setTitle:projectName forState:UIControlStateNormal];
        } else {
            break;
        }
    }
}

- (void) populateBuildButtons
{
    [self populateLastBuild];
    [self populateLastSuccessfulBuild];
    [self populateLastUnSuccessfulBuild];
    [self populateLastStableBuild];
    [self populateLastUnStableBuild];
}

- (void) populateLastBuild
{
    if ([self.job.lastBuild intValue]!=0) {
        [self.lastBuildButton setTitle:[NSString stringWithFormat:@"%@%d%@",@"Last Build (#",[self.job.lastBuild intValue],@")"] forState:UIControlStateNormal];
    } else {
        [self.lastBuildButton setTitle:@"Last Build" forState:UIControlStateNormal];
    }
}

- (void) populateLastSuccessfulBuild
{
    if ([self.job.lastSuccessfulBuild intValue]!=0) {
        [self.lastSuccessfulBuildButton setTitle:[NSString stringWithFormat:@"%@%d%@",@"Last Successful Build (#",[self.job.lastSuccessfulBuild intValue],@")"] forState:UIControlStateNormal];
    } else {
        [self.lastSuccessfulBuildButton setTitle:@"Last Successful Build" forState:UIControlStateNormal];
    }
}

- (void) populateLastUnSuccessfulBuild
{
    if ([self.job.lastUnsuccessfulBuild intValue]!=0) {
        [self.lastUnSuccessfulBuildButton setTitle:[NSString stringWithFormat:@"%@%d%@",@"Last Unsuccessful Build (#",[self.job.lastUnsuccessfulBuild intValue],@")"] forState:UIControlStateNormal];
    } else {
        [self.lastUnSuccessfulBuildButton setTitle:@"Last Unsuccessful Build" forState:UIControlStateNormal];
    }
}

- (void) populateLastStableBuild
{
    if ([self.job.lastStableBuild intValue]!=0) {
        [self.lastStableBuildButton setTitle:[NSString stringWithFormat:@"%@%d%@",@"Last Stable Build (#",[self.job.lastStableBuild intValue],@")"] forState:UIControlStateNormal];
    } else {
        [self.lastStableBuildButton setTitle:@"Last Stable Build" forState:UIControlStateNormal];
    }
}

- (void) populateLastUnStableBuild
{
    if ([self.job.lastUnstableBuild intValue]!=0) {
        [self.lastUnStableBuildButton setTitle:[NSString stringWithFormat:@"%@%d%@",@"Last Unstable Build (#",[self.job.lastUnstableBuild intValue],@")"] forState:UIControlStateNormal];
    } else {
        [self.lastUnStableBuildButton setTitle:@"Last Unstable Build" forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    KDBBuildDetailViewController *dest = [segue destinationViewController];
    Build *build = nil;
    if ([[segue identifier] isEqualToString:@"lastBuildSegue"]) {
        build = [Build fetchBuildWithNumber:self.job.lastBuild forJobAtURL:self.job.url inContext:self.managedObjectContext];
    } else if ([[segue identifier] isEqualToString:@"lastSuccessfulBuildSegue"]) {
        build = [Build fetchBuildWithNumber:self.job.lastSuccessfulBuild forJobAtURL:self.job.url inContext:self.managedObjectContext];
    } else if ([[segue identifier] isEqualToString:@"lastUnsuccessfulBuildSegue"]) {
        build = [Build fetchBuildWithNumber:self.job.lastUnsuccessfulBuild forJobAtURL:self.job.url inContext:self.managedObjectContext];
    } else if ([[segue identifier] isEqualToString:@"lastStableBuildSegue"]) {
        build = [Build fetchBuildWithNumber:self.job.lastStableBuild forJobAtURL:self.job.url inContext:self.managedObjectContext];
    } else if ([[segue identifier] isEqualToString:@"lastUnstableBuildSegue"]) {
        build = [Build fetchBuildWithNumber:self.job.lastUnstableBuild forJobAtURL:self.job.url inContext:self.managedObjectContext];
    } else if ([[segue identifier] isEqualToString:@"latestTestResultSegue"]) {
        KDBTestResultsViewController *testresultsdest = [segue destinationViewController];
        build = [Build fetchBuildWithNumber:self.job.lastBuild forJobAtURL:self.job.url inContext:self.managedObjectContext];
        [testresultsdest setBuild:build];
    } else if ([[segue identifier] isEqualToString:@"upstreamProjectsSegue"]) {
        KDBRelatedProjectsViewController *relatedProjectsdest = [segue destinationViewController];
        [relatedProjectsdest setRelatedProjects:self.job.upstreamProjects forType:UPSTREAM];
    } else if ([[segue identifier] isEqualToString:@"downstreamProjectsSegue"]) {
        KDBRelatedProjectsViewController *relatedProjectsdest = [segue destinationViewController];
        [relatedProjectsdest setRelatedProjects:self.job.downstreamProjects forType:DOWNSTREAM];
    } else if ([[segue identifier] isEqualToString:@"buildListSegue"]) {
        self.buildsVC = [segue destinationViewController];
        self.buildsVC.managedObjectContext = self.managedObjectContext;
        self.buildsVC.job = self.job;
    }
    
    if (build != nil) {
        [dest setBuild:build];
    }
}

@end
