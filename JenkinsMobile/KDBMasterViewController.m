//
//  KDBMasterViewController.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBMasterViewController.h"
#import "KDBJobDetailViewController.h"
#import "AFNetworking.h"
#import "KDBMasterBuildListTableViewController.h"

@interface KDBMasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation KDBMasterViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    self.tableView.separatorInset = UIEdgeInsetsZero;
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.jobDetailViewController = (KDBJobDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    //register an observer that fires when app enters foreground to ensure that a row is always selected
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ensureRowIsSelected) name:UIApplicationDidBecomeActiveNotification object:nil];
    //register an observer that listens to changes in job detail view
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSelectedRow:) name:@"SelectedJobChanged" object:nil];
}

- (void)ensureRowIsSelected
{
    if ([[self.tableView indexPathForSelectedRow] row] == 0 && [self.fetchedResultsController.fetchedObjects count] > 0) {
        NSIndexPath *zeroIndex = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView selectRowAtIndexPath:zeroIndex animated:NO scrollPosition:UITableViewScrollPositionTop];
        [self populateDetailViewForJobAtIndex:zeroIndex];
    }
}

- (void)updateSelectedRow: (NSNotification *) notification
{
    // update the selected job with the newly selected job from detail view
    [self.tableView selectRowAtIndexPath:[self.fetchedResultsController indexPathForObject:(Job*)notification.object] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

- (void) populateDetailViewForJobAtIndex: (NSIndexPath *) indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        Job *job = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [self.jobDetailViewController setJob:job];
        self.jobDetailViewController.managedObjectContext = self.managedObjectContext;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self populateDetailViewForJobAtIndex:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Job *job = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setJob:job];
    } else if ([[segue identifier] isEqualToString:@"BuildMasterTableSegue"]) {
        KDBMasterBuildListTableViewController *buildlist = (KDBMasterBuildListTableViewController *)[segue destinationViewController];
        buildlist.managedObjectContext = self.managedObjectContext;
        buildlist.job = [[self fetchedResultsController] objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Job *job = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = job.name;
    NSString *iconFileName = [NSString stringWithFormat:@"%@%@", job.color, @".png"];
    cell.imageView.image = [UIImage imageNamed:iconFileName];
}

#pragma mark - IBActions
-(IBAction)chooseViewButtonTapped:(id)sender
{
    if (_viewPicker == nil) {
        //Create the ViewPickerViewController.
        _viewPicker = [[KDBViewPickerViewController alloc] initWithStyle:UITableViewStylePlain];
        
        //Set this VC as the delegate.
        _viewPicker.delegate = self;
    }
    
    if (_viewPickerPopover == nil) {
        //The view picker popover is not showing. Show it.
        _viewPickerPopover = [[UIPopoverController alloc] initWithContentViewController:_viewPicker];
        [_viewPickerPopover presentPopoverFromBarButtonItem:(UIBarButtonItem *)sender
                                    permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else {
        //The view picker popover is showing. Hide it.
        [_viewPickerPopover dismissPopoverAnimated:YES];
        _viewPickerPopover = nil;
    }
}

#pragma mark - ViewPickerDelegate method
-(void)selectedView:(NSURL *)newViewURL withName:(NSString *)name {
    //Dismiss the popover if it's showing
    if (_viewPickerPopover) {
        [_viewPickerPopover dismissPopoverAnimated:YES];
        _viewPickerPopover = nil;
    }
    
    // update the title bar
    self.navigationItem.title = name;
    
    // reload the master table view with jobs from the selected view
    // TODO: requery with predicate for view
}

#pragma mark - MasterViewControllerDelegate
-(void) popNavigationController
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIDataSourceModelAssociation
- (NSString *) modelIdentifierForElementAtIndexPath:(NSIndexPath *)idx inView:(UIView *)view
{
    Job *job = [self.fetchedResultsController objectAtIndexPath:idx];
    return job.objectID.URIRepresentation.absoluteString;
}

- (NSIndexPath *) indexPathForElementWithModelIdentifier:(NSString *)identifier inView:(UIView *)view
{
    NSURL *jobURL = [NSURL URLWithString:identifier];
    NSManagedObjectID *jobID = [self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:jobURL];
    Job *job = (Job *)[self.managedObjectContext objectWithID:jobID];
    
    return [_fetchedResultsController indexPathForObject:job];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Job" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
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

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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
