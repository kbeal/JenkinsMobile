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

- (void) importDetailsForView: (View *) view
{
    //NSLog([NSString stringWithFormat:@"%@%@",@"importing details for view: ",view.url]);
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",view.url,@"api/json"]];
    
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
        JenkinsInstance *viewsJI = (JenkinsInstance *)view.rel_View_JenkinsInstance;
        if ([view.url isEqual:viewsJI.url])
        {
            NSArray *keys = [NSArray arrayWithObjects:@"name",@"url",@"jobs",@"description", nil];
            NSArray *values = [NSArray arrayWithObjects:view.name,view.url,[responseObject objectForKey:@"jobs"],[responseObject objectForKey:@"description"], nil];
            viewValues = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        }
        [self persistViewToLocalStorage:viewValues];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

- (void) importDetailsForJob:(NSString *)jobURL inView:(View *) view
{
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",jobURL,@"api/json"]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self persistJobToLocalStorage:responseObject inView:view];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

- (void) importDetailsForBuild: (NSString *) buildURL forJob: (Job *) job
{
    //NSLog([NSString stringWithFormat:@"%@%@",@"importing details for job: ",job.url]);
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",buildURL,@"api/json"]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    //AFNetworking asynchronous url request
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self persistBuildToLocalStorage:responseObject forJob:job];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Handle error
        NSLog(@"Request Failed: %@, %@", error, error.userInfo);
    }];
    
    [operation start];
}

- (void) persistViewsToLocalStorage: (NSArray *) views
{
    //NSLog([NSString stringWithFormat:@"%@%d%@",@"saving ",views.count,@" views..."]);
    for (int i=0; i<views.count; i++) {
        View * view = [View createViewWithValues:[views objectAtIndex:i] inManagedObjectContext:self.managedObjectContext forJenkinsInstance:self.jinstance];
        [self importDetailsForView:view];
    }
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        [NSException raise:@"Unable to import views" format:@"Error saving context: %@", error];
    }
}

- (void) persistViewToLocalStorage: (NSDictionary *) viewvals
{
    View *view = [View createViewWithValues:viewvals inManagedObjectContext:self.managedObjectContext forJenkinsInstance:self.jinstance];
    for (Job *job in view.rel_View_Jobs) {
        [self importDetailsForJob:job.url inView:view];
    }
}

- (void) persistJobToLocalStorage: (NSDictionary *) jobvals inView: (View *) view
{
    Job *job = [Job createJobWithValues:jobvals inManagedObjectContext:self.managedObjectContext forView:view byCaller:@"persistJob"];
//    for (Build *build in job.rel_Job_Builds) {
//        [self importDetailsForBuild:build.url forJob:job];
//    }
}

- (void) persistBuildToLocalStorage: (NSDictionary *) buildvals forJob: (Job *) job
{
    [Build createBuildWithValues:buildvals inManagedObjectContext:self.managedObjectContext forJob:job];
}

@end
