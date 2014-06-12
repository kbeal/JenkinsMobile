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

@interface KDBJobDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation KDBJobDetailViewController

- (void)awakeFromNib
{
    self.upstreamProjectButtons =
        [NSArray arrayWithObjects:self.upstreamProjectButton1,self.upstreamProjectButton2,self.upstreamProjectButton3,self.upstreamProjectButton4,self.upstreamProjectButton5, nil];
    self.downstreamProjectButtons =
        [NSArray arrayWithObjects:self.downstreamProjectButton1,self.downstreamProjectButton2,self.downstreamProjectButton3,self.downstreamProjectButton4,self.downstreamProjectButton5, nil];
    [super awakeFromNib];
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
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
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
