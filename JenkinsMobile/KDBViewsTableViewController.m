//
//  KDBViewsTableViewController.m
//  JenkinsMobile
//
//  Created by Kyle on 4/22/15.
//  Copyright (c) 2015 Kyle Beal. All rights reserved.
//

#import "KDBViewsTableViewController.h"
#import "SWRevealViewController.h"
#import "Constants.h"

@interface KDBViewsTableViewController ()

@end

@implementation KDBViewsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.syncMgr = [SyncManager sharedInstance];
    self.managedObjectContext = self.syncMgr.mainMOC;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fireRefreshRequest) forControlEvents:UIControlEventValueChanged];

    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController) {
        [self.sidebarButton setTarget: self.revealViewController];
        [self.sidebarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    [self setNavTitleAndButton];
    [self initObservers];
    [self fireRefreshRequest];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshData:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.refreshControl endRefreshing];
}

- (void) initObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshData:) name:SyncManagerCurrentJenkinsInstanceChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endRefresh:) name:JenkinsInstanceViewsResponseReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endRefresh:) name:JenkinsInstanceViewsRequestFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endRefresh:) name:ViewChildViewsResponseReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endRefresh:) name:ViewChildViewsRequestFailedNotification object:nil];
}

- (void) setNavTitleAndButton {
    if (self.parentView) {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.title = self.parentView.name;
    } else {
        self.navigationItem.leftBarButtonItem.image = [[UIImage imageNamed:@"logo.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        self.navigationItem.title = @"Views";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) fireRefreshRequest {
    if (self.parentView) {
        [self.syncMgr syncChildViewsForView:self.parentView];
    } else if (self.syncMgr.currentJenkinsInstance != nil){
        [self.syncMgr syncViewsForJenkinsInstance:self.syncMgr.currentJenkinsInstance];
    }
}

-(void) endRefresh:(NSNotification *) notification {
    
    if ((notification.name == JenkinsInstanceViewsResponseReceivedNotification || notification.name == JenkinsInstanceViewsRequestFailedNotification) && self.parentView == nil) {
        if (self.syncMgr.currentJenkinsInstance == notification.userInfo[RequestedObjectKey]) {
            [self.refreshControl endRefreshing];
            if (notification.name == JenkinsInstanceViewsRequestFailedNotification) {
                [self showFailureNotification];
            }
        }
    } else if ((notification.name == ViewChildViewsResponseReceivedNotification || notification.name == ViewChildViewsRequestFailedNotification) && self.parentView != nil) {
        if (self.parentView == notification.userInfo[RequestedObjectKey]) {
            [self.refreshControl endRefreshing];
            if (notification.name == ViewChildViewsRequestFailedNotification) {
                [self showFailureNotification];
            }
        }
    }
}

-(void) showFailureNotification {
    UIAlertAction *acceptFailure = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Failed To Refresh" message:@"Unable to refresh Views. Check connection and credentials." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:acceptFailure];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table view delegate
-(void) refreshData:(NSNotification *) notification {
    self.fetchedResultsController = nil;
    [self.tableView reloadData];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[self.fetchedResultsController sections] count];
    //return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
    //return 0;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath forView:(View *)view
{
    cell.textLabel.text = view.name;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    View *view = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    UITableViewCell *cell ;

    if (view.rel_View_Views.count > 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ParentViewCell" forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ViewCell" forIndexPath:indexPath];
    }
    [self configureCell:cell atIndexPath:indexPath forView:view];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
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
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"showChildViews"]) {
        KDBViewsTableViewController *newViewsTVC = [segue destinationViewController];
        //View *selectedView = [[self fetchedResultsController] objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
        [newViewsTVC setManagedObjectContext:self.managedObjectContext];
        [newViewsTVC setParentView:[[self fetchedResultsController] objectAtIndexPath:[self.tableView indexPathForSelectedRow]]];
    } else if ([[segue identifier] isEqualToString:@"showJobs"]) {
        KDBJobsTableViewController *jobsTVC = [segue destinationViewController];
        [jobsTVC setManagedObjectContext:self.managedObjectContext];
        [jobsTVC setParentView:[[self fetchedResultsController] objectAtIndexPath:[self.tableView indexPathForSelectedRow]]];
    }
}

#pragma mark - Fetched results controller
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"View" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];

    NSPredicate *predicate = nil;
    if (self.parentView) {
        predicate = [NSPredicate predicateWithFormat:@"rel_ParentView == %@", self.parentView];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"rel_View_JenkinsInstance == %@ AND rel_ParentView == nil", self.syncMgr.currentJenkinsInstance];
    }

    fetchRequest.predicate = predicate;
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    // cacheName must be nil to workaround crash when managedObjectContext is a child context with NSMainQueueConcurrencyType
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    View *view =[self.fetchedResultsController objectAtIndexPath:newIndexPath];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath forView:view];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

@end
