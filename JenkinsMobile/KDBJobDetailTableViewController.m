//
//  KDBJobDetailTableViewController.m
//  JenkinsMobile
//
//  Created by Kyle on 8/3/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBJobDetailTableViewController.h"
#import "KDBBuildDetailViewController.h"
#import "Constants.h"
#import "KDBBallScene.h"
#import "KDBJobTableViewCell.h"
#import "KDBJenkinsRequestHandler.h"
#import "KDBBuildsTableViewController.h"

@interface KDBJobDetailTableViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation KDBJobDetailTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //observe changes to model
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext];
    // observe notifications when response is returned from server
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jobDetailResponseReceived:) name:JobDetailResponseReceivedNotification object:nil];
    // observe notifications when build progress response is returned from server
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buildProgressResponseReceived:) name:BuildProgressResponseReceivedNotification object:nil];
    // fix the padding inside the job url textview
    self.jobURLTextView.contentInset = UIEdgeInsetsMake(0,-3,0,0);
    // make the job url textview truncate at the end
    self.jobURLTextView.textContainer.maximumNumberOfLines = 0;
    self.jobURLTextView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
}

#pragma mark - Managing the detail item
- (void)setJob:(Job *)newJob
{
    if (_job != newJob) {
        _job = newJob;
        
        // Update the view.
        [self configureView];
        // Query Jenkins for updates to job
        [self getUpdates];
    }
    
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
    // update the master view
    [[NSNotificationCenter defaultCenter] postNotificationName:SelectedJobChangedNotification object:self.job];
}

- (void)configureView
{
    // Update the user interface for the detail item.
    if (self.job) {
        self.navigationItem.title = self.job.name;
        [self.tableView reloadData];
        [self updateJobIcons];
        [self updateProgressView];
        self.jobURLTextView.text = self.job.url;
        self.jobDescriptionTextView.text = self.job.job_description;
        self.jenkinsNameJobDescriptionLabel.text = [self getJenkinsInstance].name;
    }
}

// returns the JenkinsInstance associated with the job
- (JenkinsInstance *) getJenkinsInstance
{
    View *view = [self.job.rel_Job_View anyObject];
    return (JenkinsInstance*)view.rel_View_JenkinsInstance;
}

// returns a JenkinsRequestHandler for this job's JenkinsInstance
- (KDBJenkinsRequestHandler *) getJenkinsRequestHandler
{
    return [[KDBJenkinsRequestHandler alloc] initWithJenkinsInstance:[self getJenkinsInstance]];
}

- (void)getUpdates
{
    KDBJenkinsRequestHandler *jenkins = [self getJenkinsRequestHandler];
    jenkins.managedObjectContext = self.managedObjectContext;
    [jenkins importDetailsForJobAtURL:self.job.url];
}

-(IBAction)refresh:(id)sender
{
    [self getUpdates];
}

- (void) handleDataModelChange: (NSNotification *) notification
{
    NSSet *updatedObjects = [[notification userInfo] objectForKey:NSUpdatedObjectsKey];
    // see if self.job was updated
    [updatedObjects enumerateObjectsUsingBlock:^(id obj, BOOL *stop){
        if ([[obj objectID] isEqual:[self.job objectID]]) {
            self.job = obj;
            [self configureView];
        }
    }];
}

- (void) jobDetailResponseReceived: (NSNotification *) notification
{
    // fired when receiving JobDetailResponseReceivedNotification
    // A response to a request for job details from Jenkins API was received
    // if it was for this job
    if ([[[notification userInfo] objectForKey:JobURLKey] isEqualToString:self.job.url]) {
        // hide the refresh control
        NSLog(@"%@%@%@",@"response notification for job ",self.job.name,@" received");
        [self.refreshControl endRefreshing];
    }
}

- (void) buildProgressResponseReceived: (NSNotification *) notification
{
    // fired when receiving BuildProgressResponseReceievedNotification
    // A response to a request for build progress from Jenkins API was received
    // grab the values from the notification
    NSString *jobURL = [[notification userInfo] objectForKey:JobURLKey];
    NSNumber *buildNumber = [[notification userInfo] objectForKey:BuildNumberKey];
    BOOL building = [[[notification userInfo] objectForKey:BuildBuildingKey] boolValue];
    double timestamp = [[[notification userInfo] objectForKey:BuildTimestampKey] doubleValue];
    double estimatedDuration = [[[notification userInfo] objectForKey:BuildEstimatedDurationKey] doubleValue];
    double currentTime = [[NSDate date] timeIntervalSince1970] * 1000;
    // if it is the most recent build for this job
    if ([self.job.url isEqualToString:jobURL] && [self.job.lastBuild intValue]==[buildNumber intValue]) {
        if (building) {
            // update the progress view's progress and make sure it isn't hidden
            self.currentBuildProgressView.progress = (currentTime - timestamp) / estimatedDuration;
            self.currentBuildProgressView.hidden = NO;
        } else {
            // hide the progress view
            self.currentBuildProgressView.hidden = YES;
        }
    }
    
}

- (void) updateProgressView
{
    //only show the progress view if a build is in progress
    self.currentBuildProgressView.hidden = YES;
    if ([self.job colorIsAnimated]) {
        self.currentBuildProgressView.hidden = NO;
    }
    KDBJenkinsRequestHandler *jenkins = [self getJenkinsRequestHandler];
    [jenkins importProgressForBuild:self.job.lastBuild ofJobAtURL:self.job.url];
}
- (void) updateJobIcons
{
    [self updateJobStatusIcon];
    [self updateJobHealthIcon];
}

- (void) updateJobStatusIcon
{
    // Create and configure the scene.
    NSString *color = [self.job colorIsAnimated] ? [self.job.color componentsSeparatedByString:@"_"][0] : self.job.color;
    KDBBallScene *scene = [[KDBBallScene alloc] initWithSize:self.statusBallContainerView.bounds.size andColor:color withAnimation:[self.job colorIsAnimated]];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [self.statusBallContainerView presentScene:scene];
}

- (void) updateJobHealthIcon
{
    if ([self.job.healthReport count]>0) {
        self.healthIcon.image = [UIImage imageNamed:[[self.job.healthReport objectAtIndex:0] objectForKey:@"iconUrl"]];
    } else {
        self.healthIcon.image = nil;
    }
}

- (void) clearLinkIndices
{
    // set the link row indices back to a number too high to be in the section
    self.lastBuildRowIndex=self.lastFailedBuildRowIndex=self.lastStableBuildRowIndex=self.lastSuccessfulBuildRowIndex=self.lastUnstableBuildRowIndex=self.lastUnsuccessfulBuildRowIndex=100000;
}

- (NSInteger) numberPermalinks
{
    [self clearLinkIndices];
    NSInteger links = 0;
    if ( self.job.lastBuild ) {
        self.lastBuildRowIndex=links;
        links++;
    }
    if ( self.job.lastStableBuild ) {
        self.lastStableBuildRowIndex=links;
        links++;
    }
    if ( self.job.lastSuccessfulBuild ) {
        self.lastSuccessfulBuildRowIndex=links;
        links++;
    }
    if ( self.job.lastFailedBuild ) {
        self.lastFailedBuildRowIndex=links;
        links++;
    }
    if ( self.job.lastUnstableBuild ) {
        self.lastUnstableBuildRowIndex=links;
        links++;
    }
    if ( self.job.lastUnsuccessfulBuild ) {
        self.lastUnsuccessfulBuildRowIndex=links;
        links++;        
    }
    
    self.allBuildsRowIndex = links;
    links++; // will always have the all builds link
    return links;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) relatedProjectColorIsAnimated:(NSString*) color { return [color rangeOfString:@"anime"].length > 0 ? true : false; }

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sections = 0;
    self.permalinksSectionIndex=self.upstreamProjectsSectionIndex=self.downstreamProjectsSectionIndex=0;
    
    if ([self numberPermalinks] > 0) {
        self.permalinksSectionIndex = sections;
        sections += 1;
    }
    
    if ([self.job.upstreamProjects count] > 0) {
        self.upstreamProjectsSectionIndex = sections;
        sections += 1;
    }
    
    if ([self.job.downstreamProjects count] > 0) {
        self.downstreamProjectsSectionIndex = sections;
        sections += 1;
    }

    return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName = @"";
    if (section==self.permalinksSectionIndex) {
        sectionName = @"Permalinks";
    } else if (section==self.upstreamProjectsSectionIndex) {
        sectionName = @"Upstream Projects";
    } else if (section==self.downstreamProjectsSectionIndex) {
        sectionName = @"Downstream Projects";
    }
    return sectionName;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numRows=0;
    if (section==self.permalinksSectionIndex) {
        numRows = [self numberPermalinks];
    } else if (section==self.upstreamProjectsSectionIndex) {
        numRows = [self.job.upstreamProjects count];
    } else if (section==self.downstreamProjectsSectionIndex) {
        numRows = [self.job.downstreamProjects count];
    }
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell=nil;
    // Configure the cell...
    if (indexPath.section==self.permalinksSectionIndex) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"PermalinkCell" forIndexPath:indexPath];
        [self configurePermalinksCell:cell atIndexPath:indexPath];
    } else if (indexPath.section==self.upstreamProjectsSectionIndex) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"RelatedProjectCell" forIndexPath:indexPath];
        [self configureUpstreamProjectsCell:(KDBJobTableViewCell*)cell atIndexPath:indexPath];
    } else if (indexPath.section==self.downstreamProjectsSectionIndex) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"RelatedProjectCell" forIndexPath:indexPath];
        [self configureDownstreamProjectsCell:(KDBJobTableViewCell *)cell atIndexPath:indexPath];
    }
    
    return cell;
}

- (void)configurePermalinksCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row==self.lastBuildRowIndex) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@%d%@",@"Last Build (#",[self.job.lastBuild intValue],@")"];
        cell.tag = [self.job.lastBuild integerValue];
    } else if (indexPath.row==self.lastFailedBuildRowIndex) {
       cell.textLabel.text = [NSString stringWithFormat:@"%@%d%@",@"Last Failed Build (#",[self.job.lastFailedBuild intValue],@")"];
       cell.tag = [self.job.lastFailedBuild integerValue];
    } else if (indexPath.row==self.lastStableBuildRowIndex) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@%d%@",@"Last Stable Build (#",[self.job.lastStableBuild intValue],@")"];
        cell.tag = [self.job.lastStableBuild integerValue];
    } else if (indexPath.row==self.lastSuccessfulBuildRowIndex) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@%d%@",@"Last Successful Build (#",[self.job.lastSuccessfulBuild intValue],@")"];
        cell.tag = [self.job.lastSuccessfulBuild integerValue];
    } else if (indexPath.row==self.lastUnstableBuildRowIndex) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@%d%@",@"Last Unstable Build (#",[self.job.lastUnstableBuild intValue],@")"];
        cell.tag = [self.job.lastUnstableBuild integerValue];
    } else if (indexPath.row==self.lastUnsuccessfulBuildRowIndex) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@%d%@",@"Last Unsuccessful Build (#",[self.job.lastUnsuccessfulBuild intValue],@")"];
        cell.tag = [self.job.lastUnsuccessfulBuild integerValue];
    }else if (indexPath.row==self.allBuildsRowIndex) {
        cell.textLabel.text = @"All Builds";
    }
}

- (void)configureUpstreamProjectsCell:(KDBJobTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSString *projectColor = [[self.job.upstreamProjects objectAtIndex:indexPath.row] objectForKey:@"color"];
    BOOL animated = [self relatedProjectColorIsAnimated:projectColor];
    
    // Create and configure the scene.
    NSString *color =  animated ? [projectColor componentsSeparatedByString:@"_"][0] : projectColor;
    KDBBallScene *scene = [[KDBBallScene alloc] initWithSize:cell.statusBallContainerView.bounds.size andColor:color withAnimation:animated];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [cell.statusBallContainerView presentScene:scene];
    
    cell.projectNamelabel.text = [[self.job.upstreamProjects objectAtIndex:indexPath.row] objectForKey:@"name"];
}

- (void)configureDownstreamProjectsCell:(KDBJobTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSString *projectColor = [[self.job.downstreamProjects objectAtIndex:indexPath.row] objectForKey:@"color"];
    BOOL animated = [self relatedProjectColorIsAnimated:projectColor];
    
    // Create and configure the scene.
    NSString *color =  animated ? [projectColor componentsSeparatedByString:@"_"][0] : projectColor;
    KDBBallScene *scene = [[KDBBallScene alloc] initWithSize:cell.statusBallContainerView.bounds.size andColor:color withAnimation:animated];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [cell.statusBallContainerView presentScene:scene];
    
    cell.projectNamelabel.text = [[self.job.downstreamProjects objectAtIndex:indexPath.row] objectForKey:@"name"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section==self.permalinksSectionIndex) {
        if (indexPath.row==self.allBuildsRowIndex) {
            [self performSegueWithIdentifier:@"allBuildsSegue" sender:self];
        } else {
            [self performSegueWithIdentifier:@"buildDetailSegue" sender:self];
        }
    } else if (indexPath.section==self.upstreamProjectsSectionIndex || indexPath.section==self.downstreamProjectsSectionIndex) {
        [self switchDetailToRelatedProject:indexPath];
    } else {
        NSLog(@"Don't know how to handle selection in this section.");
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // get the selected cell
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForSelectedRow]];

    if ([[segue identifier] isEqualToString:@"buildDetailSegue"]) {
        Build *build = [Build fetchBuildWithNumber:[NSNumber numberWithInteger:cell.tag] forJobAtURL:self.job.url inContext:self.managedObjectContext];
        KDBBuildDetailViewController *dest = [segue destinationViewController];
        if (build != nil) {
            [dest setBuild:build];
        }
    } else if ([[segue identifier] isEqualToString:@"allBuildsSegue"]) {
        // set job
        KDBBuildsTableViewController *dest = [segue destinationViewController];
        [dest setManagedObjectContext:self.managedObjectContext];
        [dest setJob:self.job];
    }
}

- (void)switchDetailToRelatedProject:(NSIndexPath *)indexPath
{
    NSString *relatedProjectURL = @"";
    if (indexPath.section==self.upstreamProjectsSectionIndex) {
        relatedProjectURL = [[self.job.upstreamProjects objectAtIndex:indexPath.row] objectForKey:@"url"];
    } else if (indexPath.section==self.downstreamProjectsSectionIndex) {
        relatedProjectURL = [[self.job.downstreamProjects objectAtIndex:indexPath.row] objectForKey:@"url"];
    }
    [self setJob:[Job fetchJobAtURL:relatedProjectURL inManagedObjectContext:self.managedObjectContext]];
}


@end
