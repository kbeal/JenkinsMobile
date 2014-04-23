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
    self.jobsBuildsCounts = [[NSMutableDictionary alloc] init];
    self.jobsBuildsDetails = [[NSMutableDictionary alloc] init];
    
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
        [self.viewsJobsCounts setObject:[NSNumber numberWithLong:jobs.count] forKey:[view objectForKey:@"url"]];
        for (NSDictionary *job in jobs) {
            [self importDetailsForJobAtURL:[job objectForKey:@"url"] inViewAtURL:[view objectForKey:@"url"]];
        }
    }
}

- (void) importDetailsForBuildsForJobs: (NSArray *) jobs
{
    NSArray *builds = nil;
    for (NSDictionary *job in jobs) {
        builds = [job objectForKey:@"builds"];
        [self.jobsBuildsCounts setObject:[NSNumber numberWithLong:builds.count] forKey:[job objectForKey:@"url"]];
        for (NSDictionary *build in [job objectForKey:@"builds"]) {
            [self importDetailsForBuild:[build objectForKey:@"number"] forJobURL:[job objectForKey:@"url"]];
        }
    }
}

- (void) importDetailsForBuild: (NSNumber *) buildNumber forJobURL: (NSString *) jobURL
{
    //NSLog([NSString stringWithFormat:@"%@%@",@"importing details for job: ",job.url]);
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",jobURL,[buildNumber stringValue],@"/api/json"]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self appendBuildDetailsWithValues:responseObject forJobAtURL:jobURL];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

- (void) persistViewsToLocalStorage: (NSArray *) views
{
    @autoreleasepool {
        [self.managedObjectContext performBlock:^{
            for (NSDictionary *view in views) {
                [View createViewWithValues:view inManagedObjectContext:self.managedObjectContext forJenkinsInstance:self.jinstance.url];
            }
            [self saveContext];
        }];
        self.view_count = [NSNumber numberWithLong:views.count];
    }
    [self importDetailsForViews:views];
}

- (void) persistViewDetailsToLocalStorage
{
    @autoreleasepool {
        [self.managedObjectContext performBlock:^{
            for (NSDictionary *view in self.viewDetails) {
                [View createViewWithValues:view inManagedObjectContext:self.managedObjectContext forJenkinsInstance:self.jinstance.url];
            }
            [self saveContext];
        }];
    }
    [self importDetailsForJobs];
}

- (void) persistBuildToLocalStorage: (NSDictionary *) buildvals forJob: (Job *) job
{
    [Build createBuildWithValues:buildvals inManagedObjectContext:self.managedObjectContext forJob:job];
}

- (void) appendViewDetailsWithValues: (NSDictionary *) viewValues
{
    [self.viewDetails addObject:viewValues];
    if ([NSNumber numberWithLong:self.viewDetails.count] == self.view_count) {
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

- (void) appendBuildDetailsWithValues: (NSDictionary *) buildValues forJobAtURL: (NSString *) jobURL
{
    NSMutableArray *builds = [self.jobsBuildsDetails objectForKey:jobURL];
    if (builds==nil) {
        builds = [[NSMutableArray alloc] init];
    }
    [builds addObject:buildValues];
    [self.jobsBuildsDetails setObject:builds forKey:jobURL];
    if (builds.count==[[self.jobsBuildsCounts objectForKey:jobURL] intValue]) {
        [self persistBuildDetailsToLocalStorageForJobAtURL:jobURL];
    }
}

- (void) persistJobDetailsToLocalStorageForView: (NSString *) viewURL
{
    @autoreleasepool {
        View *view = [View fetchViewWithURL:viewURL inContext:self.managedObjectContext];
        for (NSDictionary *job in [self.viewsJobsDetails objectForKey:viewURL]) {
            [Job createJobWithValues:job inManagedObjectContext:self.managedObjectContext forView:view];
        }
        [self saveContext];
    }
    [self importDetailsForBuildsForJobs:[self.viewsJobsDetails objectForKey:viewURL]];
}

- (void) persistBuildDetailsToLocalStorageForJobAtURL: (NSString *) jobURL
{
    @autoreleasepool {
        Job *job = [Job fetchJobAtURL:jobURL inManagedObjectContext:self.managedObjectContext];
        for (NSDictionary *build in [self.jobsBuildsDetails objectForKey:jobURL]) {
            [Build createBuildWithValues:build inManagedObjectContext:self.managedObjectContext forJob:job];
        }
        [self saveContext];
    }
}

- (void) saveContext
{    
    [self.managedObjectContext performBlock:^{
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            [NSException raise:@"Unable to save context." format:@"Error saving context: %@", error];
        }
    }];
}



@end
