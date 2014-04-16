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

//- (void) importDetailsForJob:(NSString *)jobURL inView:(View *) view
//{
//    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",jobURL,@"api/json"]];
//    
//    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
//    //AFNetworking asynchronous url request
//    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
//                                         initWithRequest:request];
//    
//    operation.responseSerializer = [AFJSONResponseSerializer serializer];
//    
//    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//        [self persistJobToLocalStorage:responseObject inView:view];
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        // Handle error
//        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
//    }];
//    
//    [operation start];
//}

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
    
//    for (int i=0; i<views.count; i++) {
//        View * view = [View createViewWithValues:[views objectAtIndex:i] inManagedObjectContext:self.managedObjectContext forJenkinsInstance:self.jinstance];
//        [self importDetailsForView:view];
//    }
//    
//    NSError *error;
//    if (![self.managedObjectContext save:&error]) {
//        [NSException raise:@"Unable to import views" format:@"Error saving context: %@", error];
//    }
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
    //TODO: importDetailsForJobs
}

//- (void) persistJobToLocalStorage: (NSDictionary *) jobvals inView: (View *) view
//{
//    Job *job = [Job createJobWithValues:jobvals inManagedObjectContext:self.managedObjectContext forView:view];
//    [self importAllBuildsForJob:job];
//}

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

@end
