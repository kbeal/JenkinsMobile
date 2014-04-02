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
    self.currentURL = @"http://tomcat:8080/";
    self.jenkinsViewsJobs = [[NSMutableDictionary alloc] init];
    self.jenkinsViews = [[NSMutableArray alloc] init];
    [self getAllJenkinsViews];
    
    NSArray *colors = [NSArray arrayWithObjects:[UIColor redColor], [UIColor greenColor], [UIColor blueColor], nil];
    for (int i = 0; i < self.jenkinsViews.count; i++) {
        CGRect frame;
        frame.origin.x = self->jenkinsViewsScrollView.frame.size.width * i;
        frame.origin.y = 0;
        frame.size = self->jenkinsViewsScrollView.frame.size;

        UITableView *tableView = [[UITableView alloc] initWithFrame:frame];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = [colors objectAtIndex:i];

        [self->jenkinsViewsScrollView addSubview:tableView];
        
        if (i==0) {
            self.currentView = tableView;
        }
    }

    self->jenkinsViewsScrollView.contentSize = CGSizeMake(self->jenkinsViewsScrollView.frame.size.width * 3, self->jenkinsViewsScrollView.frame.size.height);
    [self makeJenkinsRequestsForView:[self.jenkinsViews objectAtIndex:0]];
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
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
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

-(void) mapViewsToJobs: (NSArray *) views
{
    for (int i=0; i<views.count; i++) {
        NSDictionary *view = [views objectAtIndex:i];
        NSEnumerator *enumerator = [view keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            [self queryJenkinsJobsInView:[view objectForKey:@"url"]];
        }
    }
    

}

-(void) queryJenkinsJobsInView: (NSString *) url
{
    NSURL *viewURL =
        [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",url,@"api/json"]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:viewURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self.jenkinsViewsJobs setObject:[responseObject objectForKey:@"jobs"] forKey:url];
        [self.currentView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

#pragma mark - ScrollView Delegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    static NSInteger previousPage = 0;
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    if (previousPage != page) {
        // Page has changed, do your thing!
        // ...
        // Finally, update previous page
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
    NSArray *jobs = [self.jenkinsViewsJobs objectForKey:@"http://tomcat:8080/"];
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
    NSArray *jobs = [self.jenkinsViewsJobs objectForKey:self.currentURL];
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
