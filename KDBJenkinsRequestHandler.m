//
//  KDBJenkinsRequestHandler.m
//  JenkinsMobile
//
//  Created by Kyle on 4/4/14.
//  Copyright (c) 2014 Kyle Beal. All rights reserved.
//

#import "KDBJenkinsRequestHandler.h"
#import "AFNetworking.h"

@implementation KDBJenkinsRequestHandler

- (id) initWithManagedObjectContext: (NSManagedObjectContext *) context andJenkinsInstance: (JenkinsInstance *) instance
{
    self.managedObjectContext=context;
    self.jinstance = instance;
    self.view_count = 0;
    self.viewDetails = [[NSMutableArray alloc] init];
    self.viewsJobsCounts = [[NSMutableDictionary alloc] init];
    self.viewsJobsDetails = [[NSMutableDictionary alloc] init];
    return self;
}

- (void) importAllViews
{
    //NSLog(@"importing views...");
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",self.jinstance.url,@"api/json"]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self persistViewsToLocalStorage:[responseObject objectForKey:@"views"]];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

- (void) importDetailsForViews: (NSArray *) views
{
    for (NSDictionary *view in views) {
        [self importDetailsForView:[view objectForKey:@"name"] atURL:[view objectForKey:@"url"]];
    }
}

- (void) importDetailsForView: (NSString *) viewName atURL: (NSString *) viewURL
{
    //NSLog([NSString stringWithFormat:@"%@%@",@"importing details for view: ",view.url]);
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",viewURL,@"api/json"]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        // The default Jenkin's 'All' view has the same URL as the node.
        // Which means when we query it, the response doesn't look like a typical view.
        // We have to get the views array out of reponse in that case.
        NSDictionary *viewValues = responseObject;
        if ([viewURL isEqual:self.jinstance.url])
        {
            NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"jobs",@"description", nil];
            NSArray *values = [NSArray arrayWithObjects:viewName,viewURL,[responseObject objectForKey:@"jobs"],[responseObject objectForKey:@"description"], nil];
            viewValues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        }
        [self appendViewDetailsWithValues:viewValues];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

- (void) importDetailsForJobAtURL:(NSString *)jobURL inViewAtURL:(NSString *) viewURL
{
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",jobURL,@"api/json"]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self appendJobDetailsWithValues:responseObject forViewAtURL:viewURL];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

- (void) importDetailsForJobs
{
    for (NSDictionary *view in self.viewDetails) {
        NSArray *jobs = [view objectForKey:@"jobs"];
        [self.viewsJobsCounts setObject:[NSNumber numberWithInt:jobs.count] forKey:[view objectForKey:@"url"]];
        for (NSDictionary *job in jobs) {
            [self importDetailsForJobAtURL:[job objectForKey:@"url"] inViewAtURL:[view objectForKey:@"url"]];
        }
    }
}

//- (void) importDetailsForBuild: (int) buildNumber forJob: (Job *) job
//{
//    //NSLog([NSString stringWithFormat:@"%@%@",@"importing details for job: ",job.url]);
//    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%d%@",job.url,buildNumber,@"/api/json"]];
//    
//    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
//    //AFNetworking asynchronous url request
//    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
//                                         initWithRequest:request];
//    
//    operation.responseSerializer = [AFJSONResponseSerializer serializer];
//    
//    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//        [self persistBuildToLocalStorage:responseObject forJob:job];
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        // Handle error
//        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
//    }];
//    
//    [operation start];
//}

- (void) persistViewsToLocalStorage: (NSArray *) views
{
    @autoreleasepool {
        for (NSDictionary *view in views) {
            [View createViewWithValues:view inManagedObjectContext:self.managedObjectContext forJenkinsInstance:self.jinstance];
        }
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            [NSException raise:@"Unable to create views" format:@"Error saving context: %@", error];
        }
        self.view_count = views.count;
    }
    [self importDetailsForViews:views];
}

- (void) persistViewDetailsToLocalStorage
{
    @autoreleasepool {
        for (NSDictionary *view in self.viewDetails) {
            [View createViewWithValues:view inManagedObjectContext:self.managedObjectContext forJenkinsInstance:self.jinstance];
        }
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            [NSException raise:@"Unable to save view details." format:@"Error saving context: %@", error];
        }
    }
    [self importDetailsForJobs];
}

//- (void) importAllBuildsForJob: (Job *) job
//{
//    if (job.firstBuild)
//    {
//        int lastImportedBuild = [job.lastImportedBuild intValue];
//        int firstBuild = [job.firstBuild intValue];
//        int start = lastImportedBuild > firstBuild ? lastImportedBuild : firstBuild;
//        int lastBuild = [job.lastBuild intValue];
//        for (int i=start; i<=lastBuild; i++) {
//            [self importDetailsForBuild:i forJob:job];
//        }
//    }
//}

//- (void) persistBuildToLocalStorage: (NSDictionary *) buildvals forJob: (Job *) job
//{
//    [Build createBuildWithValues:buildvals inManagedObjectContext:self.managedObjectContext forJob:job];
//}

- (void) appendViewDetailsWithValues: (NSDictionary *) viewValues
{
    [self.viewDetails addObject:viewValues];
    if (self.viewDetails.count == self.view_count) {
        [self persistViewDetailsToLocalStorage];
    }
}

- (void) appendJobDetailsWithValues: (NSDictionary *) jobValues forViewAtURL: (NSString *) viewURL
{
    NSMutableArray *jobs = [self.viewsJobsDetails objectForKey:viewURL];
    if (jobs==nil) {
        jobs = [[NSMutableArray alloc] init];
    }
    [jobs addObject:jobValues];
    [self.viewsJobsDetails setValue:jobs forKey:viewURL];
    if (jobs.count==[[self.viewsJobsCounts objectForKey:viewURL] intValue]) {
        [self persistJobDetailsToLocalStorageForView:viewURL];
    }
}

- (void) persistJobDetailsToLocalStorageForView: (NSString *) viewURL
{
    @autoreleasepool {
        View *view = [View fetchViewWithURL:viewURL inContext:self.managedObjectContext];
        for (NSDictionary *job in [self.viewsJobsDetails objectForKey:viewURL]) {
            [Job createJobWithValues:job inManagedObjectContext:self.managedObjectContext forView:view];
        }
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            [NSException raise:@"Unable to save job details." format:@"Error saving context: %@", error];
        }
    }
    //TODO import details for builds
}

@end
