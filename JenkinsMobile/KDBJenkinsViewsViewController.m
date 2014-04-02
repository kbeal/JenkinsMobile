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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.currentJenkinsView = @"All";
    self.jenkinsViewsJobs = [[NSMutableDictionary alloc] init];
    self.jenkinsViews = [[NSMutableArray alloc] init];
    [self getAllJenkinsViews];
}

- (void)addTableForEachJenkinsView
{
    NSArray *colors = [NSArray arrayWithObjects:[UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor brownColor], nil];
    for (int i = 0; i < self.jenkinsViews.count; i++) {
        CGRect frame;
        frame.origin.x = self->jenkinsViewsScrollView.frame.size.width * i;
        frame.origin.y = self->jenkinsViewsScrollView.frame.origin.y;
        frame.size = self->jenkinsViewsScrollView.frame.size;
        
        UITableView *tableView = [[UITableView alloc] initWithFrame:frame];
        tableView.delegate = self;
        tableView.dataSource = self;
        [tableView setContentInset:UIEdgeInsetsMake(64, 0, 0, 0)];
        tableView.backgroundColor = [colors objectAtIndex:i];
        
        [self->jenkinsViewsScrollView addSubview:tableView];
        
        if (i==0) {
            self.currentTableView = tableView;
        }
    }
    self->jenkinsViewsScrollView.contentSize = CGSizeMake(self->jenkinsViewsScrollView.frame.size.width * self.jenkinsViews.count, self->jenkinsViewsScrollView.frame.size.height);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)getAllJenkinsViews
{
    NSURL *requestURL = [NSURL URLWithString:@"http://tomcat:8080/api/json"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *views = [responseObject objectForKey:@"views"];
        NSDictionary *view;
        for (int i=0; i<views.count; i++) {
            view = [views objectAtIndex:i];
            [self.jenkinsViews addObject:[view objectForKey:@"name"]];
            [self makeJenkinsRequestsForView:[view objectForKey:@"name"]];
        }
        [self addTableForEachJenkinsView];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

-(void)makeJenkinsRequestsForView: (NSString *) view
{
    NSURL *viewURL;
    NSString *baseURLString = @"http://tomcat:8080/view/";
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
        [self mapView:view toJobs:[responseObject objectForKey:@"jobs"]];
        [self.currentTableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

-(void) mapView:(NSString *)view toJobs: (NSArray *) jobs
{
    [self.jenkinsViewsJobs setObject:jobs forKey:view];
}

#pragma mark - ScrollView Delegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    static NSInteger previousPage = 0;
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    if (previousPage != page) {
        self.currentJenkinsView = [self.jenkinsViews objectAtIndex:page];
        self.currentTableView = [[self->jenkinsViewsScrollView subviews] objectAtIndex:page];
        [self.currentTableView reloadData];
        previousPage = page;
    }
}


#pragma mark - TableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *jobs = [self.jenkinsViewsJobs objectForKey:self.currentJenkinsView];
    return jobs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] init];
    }
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
    NSArray *jobs = [self.jenkinsViewsJobs objectForKey:self.currentJenkinsView];
    NSDictionary *job = [jobs objectAtIndex:indexPath.row];
    cell.textLabel.text = [job objectForKey:@"name"];
    NSString *iconFileName = [NSString stringWithFormat:@"%@%@", [job objectForKey:@"color"], @".png"];
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
