//
//  KDBMasterViewController.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/27/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBMasterViewController.h"
#import "KDBDetailViewController.h"
#import "AFNetworking.h"

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
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.detailViewController = (KDBDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];

    [self makeJenkinsRequestsForViewURL:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)makeJenkinsRequestsForViewURL: (NSURL *) url
{
    if (url==nil) {
        url = [NSURL URLWithString:@"http://tomcat:8080/"];
    }
    
    NSURL *requestURL = [url URLByAppendingPathComponent:@"api/json"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.jenkinsJobs = [responseObject objectForKey:@"jobs"];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.jenkinsJobs count];
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
    /*
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        self.detailViewController.detailItem = object;
    }*/
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDictionary *tempDictionary= [self.jenkinsJobs objectAtIndex:indexPath.row];
        [[segue destinationViewController] setDetailItem: tempDictionary];
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *tempDictionary= [self.jenkinsJobs objectAtIndex:indexPath.row];
    cell.textLabel.text = [tempDictionary objectForKey:@"name"];
    NSString *iconFileName = [NSString stringWithFormat:@"%@%@", [tempDictionary objectForKey:@"color"], @".png"];
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
-(void)selectedView:(NSURL *)newViewURL {
    //Dismiss the popover if it's showing
    if (_viewPickerPopover) {
        [_viewPickerPopover dismissPopoverAnimated:YES];
        _viewPickerPopover = nil;
    }
    
    // reload the master table view with jobs from the selected view
    [self makeJenkinsRequestsForViewURL: newViewURL];
}

@end
