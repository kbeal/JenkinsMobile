//
//  KDBJenkinsViewsViewController.m
//  JenkinsMobile
//
//  Created by Kyle Beal on 3/30/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBJenkinsViewsViewController.h"
#import "AFNetworking.h"

@interface KDBJenkinsViewsViewController ()

@end

@implementation KDBJenkinsViewsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.currentURL = @"http://tomcat:8080/api/json";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for (int i = 0; i < 3; i++) {
        CGRect frame;
        frame.origin.x = self->jenkinsViewsScrollView.frame.size.width * i;
        frame.origin.y = 0;
        frame.size = self->jenkinsViewsScrollView.frame.size;

        UITableView *tableView = [[UITableView alloc] initWithFrame:frame];
        tableView.delegate = self;
        tableView.dataSource = self;

        [self->jenkinsViewsScrollView addSubview:tableView];
    }

    self->jenkinsViewsScrollView.contentSize = CGSizeMake(self->jenkinsViewsScrollView.frame.size.width * 3, self->jenkinsViewsScrollView.frame.size.height);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)makeJenkinsRequestsForView: (NSString *) view
{
    NSURL *viewURL;
    NSString *baseURLString = @"http://tomcat:8080/";
    if (view==nil) {
        viewURL = [NSURL URLWithString:baseURLString];
    } else {
        viewURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",baseURLString,view,@"/"]];
    }
    
    NSURL *requestURL = [viewURL URLByAppendingPathComponent:@"api/json"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self mapViewsToJobs:[responseObject objectForKey:@"views"]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

-(void) mapViewsToJobs: (NSDictionary *) views
{
    NSEnumerator *enumerator = [views keyEnumerator];
    id key;
    while ((key = [enumerator nextObject])) {
        [self queryJenkinsJobsInView:[[views objectForKey:key] objectForKey:@"url"]];
    }
}

-(void) queryJenkinsJobsInView: (NSString *) url
{
    NSString *viewURL =
        [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",url,@"api/json"]];
    NSURL *requestURL = [NSURL URLWithString:viewURL];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.jenkinsViewsJobs setObject:[responseObject objectForKey:@"jobs"] forKey:url];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

#pragma mark - TableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *jobs = [self.jenkinsViewsJobs objectForKey:self.currentURL];
    return jobs.count;
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

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    /* TODO: Create a current URL variable that defaults to All. Will need to be switched when the scroll view pages.  
     */
    NSDictionary *jobs = [self.jenkinsViewsJobs objectForKey:self.currentURL];
    cell.textLabel.text = [jobs objectForKey:@"name"];
    NSString *iconFileName = [NSString stringWithFormat:@"%@%@", [jobs objectForKey:@"color"], @".png"];
    cell.imageView.image = [UIImage imageNamed:iconFileName];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
